class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true

      t.string :stripe_subscription_id
      t.string :stripe_price_id

      t.string :status, null: false
      t.datetime :current_period_start
      t.datetime :current_period_end

      t.datetime :trial_start
      t.datetime :trial_end

      t.boolean :cancel_at_period_end, default: false
      t.datetime :canceled_at
      t.datetime :ended_at

      t.references :scheduled_plan, foreign_key: { to_table: :plans }
      t.datetime :scheduled_change_date

      t.string :promo_code
      t.integer :discount_amount_cents, default: 0

      t.json :metadata
      t.json :data

      t.timestamps
    end

    add_index :subscriptions, :stripe_subscription_id, unique: true
    add_index :subscriptions, :status
    add_index :subscriptions, :current_period_end
    add_index :subscriptions, :trial_end
  end
end
