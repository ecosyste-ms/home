class PagesController < ApplicationController
  def api
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

  private

  def has_api?(service_url)
    service_name = service_url.split('//').last.split('.').first
    !%w[digest funds].include?(service_name)
  end
end