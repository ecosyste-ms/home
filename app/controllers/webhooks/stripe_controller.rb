module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :require_login

    def create
      payload = request.body.read
      sig_header = request.env['HTTP_STRIPE_SIGNATURE']
      endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']

      begin
        event = Stripe::Webhook.construct_event(
          payload, sig_header, endpoint_secret
        )
      rescue JSON::ParserError => e
        Rails.logger.error "[Stripe Webhook] Invalid payload: #{e.message}"
        render json: { error: 'Invalid payload' }, status: :bad_request
        return
      rescue Stripe::SignatureVerificationError => e
        Rails.logger.error "[Stripe Webhook] Invalid signature: #{e.message}"
        render json: { error: 'Invalid signature' }, status: :bad_request
        return
      end

      # Store the event in database for audit trail
      stripe_event = StripeEvent.find_or_initialize_by(event_id: event.id)
      stripe_event.assign_attributes(
        event_type: event.type,
        data: event.to_hash
      )
      stripe_event.save!

      Rails.logger.info "[Stripe Webhook] Received event: #{event.type} (#{event.id})"

      # Process the event
      begin
        case event.type
        when 'customer.subscription.created'
          handle_subscription_created(event.data.object)
        when 'customer.subscription.updated'
          handle_subscription_updated(event.data.object)
        when 'customer.subscription.deleted'
          handle_subscription_deleted(event.data.object)
        when 'invoice.payment_succeeded'
          handle_invoice_payment_succeeded(event.data.object)
        when 'invoice.payment_failed'
          handle_invoice_payment_failed(event.data.object)
        when 'invoice.finalized'
          handle_invoice_finalized(event.data.object)
        else
          Rails.logger.info "[Stripe Webhook] Unhandled event type: #{event.type}"
        end

        stripe_event.mark_as_processed!
        Rails.logger.info "[Stripe Webhook] Successfully processed event #{event.id}"
      rescue StandardError => e
        stripe_event.mark_as_failed!(e)
        Rails.logger.error "[Stripe Webhook] Failed to process event #{event.id}: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n")
        # Still return 200 so Stripe doesn't retry
      end

      render json: { received: true }, status: :ok
    end

    private

    def handle_subscription_created(stripe_subscription)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)

      if subscription
        subscription.update!(
          status: stripe_subscription.status,
          current_period_start: Time.at(stripe_subscription.current_period_start),
          current_period_end: Time.at(stripe_subscription.current_period_end)
        )
        Rails.logger.info "[Stripe Webhook] Updated subscription #{subscription.id}"
      else
        Rails.logger.warn "[Stripe Webhook] Subscription not found: #{stripe_subscription.id}"
      end
    end

    def handle_subscription_updated(stripe_subscription)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)

      if subscription
        subscription.update!(
          status: stripe_subscription.status,
          current_period_start: Time.at(stripe_subscription.current_period_start),
          current_period_end: Time.at(stripe_subscription.current_period_end),
          cancel_at_period_end: stripe_subscription.cancel_at_period_end
        )
        Rails.logger.info "[Stripe Webhook] Updated subscription #{subscription.id}"
      else
        Rails.logger.warn "[Stripe Webhook] Subscription not found: #{stripe_subscription.id}"
      end
    end

    def handle_subscription_deleted(stripe_subscription)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)

      if subscription
        subscription.update!(
          status: 'canceled',
          ended_at: Time.at(stripe_subscription.ended_at || Time.current.to_i)
        )
        Rails.logger.info "[Stripe Webhook] Canceled subscription #{subscription.id}"
      else
        Rails.logger.warn "[Stripe Webhook] Subscription not found: #{stripe_subscription.id}"
      end
    end

    def handle_invoice_payment_succeeded(stripe_invoice)
      account = Account.find_by(stripe_customer_id: stripe_invoice.customer)
      unless account
        Rails.logger.warn "[Stripe Webhook] Account not found for customer #{stripe_invoice.customer}"
        return
      end

      subscription = account.subscriptions.find_by(stripe_subscription_id: stripe_invoice.subscription)

      invoice = account.invoices.find_or_initialize_by(stripe_invoice_id: stripe_invoice.id)
      invoice.assign_attributes(
        subscription: subscription,
        number: stripe_invoice.number,
        status: 'paid',
        amount_due_cents: stripe_invoice.amount_due,
        amount_paid_cents: stripe_invoice.amount_paid,
        currency: stripe_invoice.currency,
        period_start: stripe_invoice.period_start ? Time.at(stripe_invoice.period_start) : nil,
        period_end: stripe_invoice.period_end ? Time.at(stripe_invoice.period_end) : nil,
        paid_at: stripe_invoice.status_transitions&.paid_at ? Time.at(stripe_invoice.status_transitions.paid_at) : Time.current,
        hosted_invoice_url: stripe_invoice.hosted_invoice_url,
        invoice_pdf_url: stripe_invoice.invoice_pdf
      )
      invoice.save!

      Rails.logger.info "[Stripe Webhook] Invoice #{invoice.id} marked as paid"
    end

    def handle_invoice_payment_failed(stripe_invoice)
      account = Account.find_by(stripe_customer_id: stripe_invoice.customer)
      unless account
        Rails.logger.warn "[Stripe Webhook] Account not found for customer #{stripe_invoice.customer}"
        return
      end

      subscription = account.subscriptions.find_by(stripe_subscription_id: stripe_invoice.subscription)

      invoice = account.invoices.find_or_initialize_by(stripe_invoice_id: stripe_invoice.id)
      invoice.assign_attributes(
        subscription: subscription,
        number: stripe_invoice.number,
        status: 'open',
        amount_due_cents: stripe_invoice.amount_due,
        amount_paid_cents: stripe_invoice.amount_paid,
        currency: stripe_invoice.currency,
        period_start: stripe_invoice.period_start ? Time.at(stripe_invoice.period_start) : nil,
        period_end: stripe_invoice.period_end ? Time.at(stripe_invoice.period_end) : nil,
        due_date: stripe_invoice.due_date ? Time.at(stripe_invoice.due_date) : nil,
        hosted_invoice_url: stripe_invoice.hosted_invoice_url,
        invoice_pdf_url: stripe_invoice.invoice_pdf
      )
      invoice.save!

      Rails.logger.warn "[Stripe Webhook] Invoice #{invoice.id} payment failed"
    end

    def handle_invoice_finalized(stripe_invoice)
      account = Account.find_by(stripe_customer_id: stripe_invoice.customer)
      unless account
        Rails.logger.warn "[Stripe Webhook] Account not found for customer #{stripe_invoice.customer}"
        return
      end

      subscription = account.subscriptions.find_by(stripe_subscription_id: stripe_invoice.subscription)

      invoice = account.invoices.find_or_initialize_by(stripe_invoice_id: stripe_invoice.id)
      invoice.assign_attributes(
        subscription: subscription,
        number: stripe_invoice.number,
        status: stripe_invoice.status,
        amount_due_cents: stripe_invoice.amount_due,
        amount_paid_cents: stripe_invoice.amount_paid || 0,
        currency: stripe_invoice.currency,
        period_start: stripe_invoice.period_start ? Time.at(stripe_invoice.period_start) : nil,
        period_end: stripe_invoice.period_end ? Time.at(stripe_invoice.period_end) : nil,
        due_date: stripe_invoice.due_date ? Time.at(stripe_invoice.due_date) : nil,
        hosted_invoice_url: stripe_invoice.hosted_invoice_url,
        invoice_pdf_url: stripe_invoice.invoice_pdf
      )
      invoice.save!

      Rails.logger.info "[Stripe Webhook] Invoice #{invoice.id} finalized"
    end
  end
end
