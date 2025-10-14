class PagesController < ApplicationController
  def api
    @meta_title = "API Documentation - ecosyste.ms | Rate Limits & OpenAPI Specs"
    @meta_description = "RESTful APIs with OpenAPI 3.0.1 specs for package ecosystem data. Polite pool access with email authentication, consistent JSON responses, and CC-BY-SA-4.0 licensing."
    @services_with_apis = Service.sections.flat_map do |section|
      section[:services].select { |service| has_api?(service[:url]) }.map do |service|
        service.merge(
          section: section[:name],
          api_url: "#{service[:url]}/docs/api/v1/openapi.yaml",
          docs_url: "#{service[:url]}/docs"
        )
      end
    end
  end

  def openapi
    send_file Rails.root.join('openapi.yml'), type: 'application/x-yaml', disposition: 'inline'
  end

  def pricing
    @meta_title = "Pricing - ecosyste.ms | API Rate Limits & Plans"
    @meta_description = "Choose the right plan for your needs. From free community access to enterprise-grade rate limits with dedicated support."
    @plans = Plan.all
  end

  private

  def has_api?(service_url)
    service_name = service_url.split('//').last.split('.').first
    !%w[digest funds].include?(service_name)
  end
end