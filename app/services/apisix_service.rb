class ApisixService
  class ApisixError < StandardError; end
  class ConnectionError < ApisixError; end
  class ApiError < ApisixError; end

  def initialize
    @base_url = ENV.fetch('APISIX_ADMIN_URL', 'http://localhost:9180')
    @admin_key = ENV.fetch('APISIX_ADMIN_KEY', nil)
  end

  # Create or update a consumer in APISIX with key-auth plugin
  # @param consumer_name [String] Unique identifier for the consumer (e.g., key_prefix)
  # @param api_key [String] The actual API key to authenticate with
  # @param metadata [Hash] Additional metadata to store with the consumer
  # @return [String] The consumer name
  def create_consumer(consumer_name:, api_key:, metadata: {})
    body = {
      username: consumer_name,
      desc: metadata[:description] || "API Key: #{metadata[:name]}",
      plugins: {
        "key-auth": {
          key: api_key
        }
      },
      labels: metadata.slice(:account_id, :name).transform_keys(&:to_s)
    }

    response = make_request(
      method: :put,
      path: "/apisix/admin/consumers/#{consumer_name}",
      body: body
    )

    consumer_name
  end

  # Delete a consumer from APISIX
  # @param consumer_name [String] The consumer identifier to delete
  # @return [Boolean] true if successful
  def delete_consumer(consumer_name:)
    make_request(
      method: :delete,
      path: "/apisix/admin/consumers/#{consumer_name}"
    )
    true
  end

  # Update consumer metadata (useful if key name changes)
  # Note: This doesn't update the key itself, only metadata
  # @param consumer_name [String] The consumer identifier
  # @param metadata [Hash] Updated metadata
  # @return [String] The consumer name
  def update_consumer_metadata(consumer_name:, metadata: {})
    # Fetch existing consumer first
    existing = get_consumer(consumer_name)
    return nil unless existing

    body = {
      username: consumer_name,
      desc: metadata[:description] || "API Key: #{metadata[:name]}",
      plugins: existing.dig("value", "plugins") || {},
      labels: metadata.slice(:account_id, :name).transform_keys(&:to_s)
    }

    make_request(
      method: :put,
      path: "/apisix/admin/consumers/#{consumer_name}",
      body: body
    )

    consumer_name
  end

  # Get consumer details from APISIX
  # @param consumer_name [String] The consumer identifier
  # @return [Hash, nil] Consumer data or nil if not found
  def get_consumer(consumer_name)
    response = make_request(
      method: :get,
      path: "/apisix/admin/consumers/#{consumer_name}"
    )
    response
  rescue ApiError => e
    # Return nil if consumer not found (404)
    return nil if e.message.include?("404")
    raise
  end

  private

  def make_request(method:, path:, body: nil)
    require 'net/http'
    require 'json'

    uri = URI.join(@base_url, path)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = 5
    http.read_timeout = 10

    request = case method
    when :get
      Net::HTTP::Get.new(uri)
    when :put
      req = Net::HTTP::Put.new(uri)
      req['Content-Type'] = 'application/json'
      req.body = body.to_json if body
      req
    when :delete
      Net::HTTP::Delete.new(uri)
    else
      raise ArgumentError, "Unsupported method: #{method}"
    end

    # Add admin key to request header
    request['X-API-KEY'] = @admin_key if @admin_key

    begin
      response = http.request(request)
    rescue StandardError => e
      raise ConnectionError, "Failed to connect to APISIX at #{@base_url}: #{e.message}"
    end

    # Parse response
    unless response.is_a?(Net::HTTPSuccess)
      error_message = "APISIX API error (#{response.code}): #{response.body}"
      raise ApiError, error_message
    end

    begin
      JSON.parse(response.body) if response.body && !response.body.empty?
    rescue JSON::ParserError => e
      raise ApiError, "Invalid JSON response from APISIX: #{e.message}"
    end
  end
end
