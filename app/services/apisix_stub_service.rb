# Stub implementation of ApisixService for development environments
# This allows API key creation without a running APISIX instance
class ApisixStubService
  class ApisixError < StandardError; end
  class ConnectionError < ApisixError; end
  class ApiError < ApisixError; end

  def initialize
    # No-op in stub - no actual connection needed
    @consumers = {} # In-memory storage for testing
  end

  # Create or update a consumer (stubbed - no actual APISIX call)
  def create_consumer(consumer_name:, api_key:, requests_per_hour:, metadata: {})
    Rails.logger.info "[ApisixStubService] Creating consumer: #{consumer_name} with #{requests_per_hour} requests/hour"

    @consumers[consumer_name] = {
      username: consumer_name,
      desc: "#{metadata[:email]} - #{metadata[:plan_name]} (#{requests_per_hour}/hr)",
      plugins: {
        "key-auth": {
          key: api_key
        },
        "limit-count": {
          count: requests_per_hour,
          time_window: 3600,
          rejected_code: 429,
          key_type: "var",
          key: "consumer_name"
        }
      },
      labels: sanitize_labels(metadata.slice(:account_id, :name))
    }

    consumer_name
  end

  # Delete a consumer (stubbed - no actual APISIX call)
  def delete_consumer(consumer_name:)
    Rails.logger.info "[ApisixStubService] Deleting consumer: #{consumer_name}"
    @consumers.delete(consumer_name)
    true
  end

  # Update consumer metadata (stubbed - no actual APISIX call)
  def update_consumer_metadata(consumer_name:, metadata: {})
    Rails.logger.info "[ApisixStubService] Updating consumer metadata: #{consumer_name}"

    existing = @consumers[consumer_name]
    return nil unless existing

    @consumers[consumer_name] = {
      username: consumer_name,
      desc: metadata[:description] || "API Key: #{metadata[:name]}",
      plugins: existing[:plugins] || {},
      labels: sanitize_labels(metadata.slice(:account_id, :name))
    }

    consumer_name
  end

  # Update consumer rate limit (stubbed - no actual APISIX call)
  def update_consumer_rate_limit(consumer_name:, requests_per_hour:)
    Rails.logger.info "[ApisixStubService] Updating rate limit for #{consumer_name}: #{requests_per_hour} requests/hour"

    existing = @consumers[consumer_name]
    return nil unless existing

    existing[:plugins][:"limit-count"] = {
      count: requests_per_hour,
      time_window: 3600,
      rejected_code: 429,
      key_type: "var",
      key: "consumer_name"
    }

    consumer_name
  end

  private

  def sanitize_labels(hash)
    hash.transform_keys(&:to_s).transform_values { |v| v.to_s.gsub(/\s+/, '_') }
  end

  public

  # Get consumer details (stubbed - returns stored data)
  def get_consumer(consumer_name)
    Rails.logger.info "[ApisixStubService] Getting consumer: #{consumer_name}"

    consumer = @consumers[consumer_name]
    return nil unless consumer

    # Return in APISIX response format
    {
      "value" => consumer
    }
  end
end
