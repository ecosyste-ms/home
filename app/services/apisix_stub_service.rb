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
  def create_consumer(consumer_name:, api_key:, metadata: {})
    Rails.logger.info "[ApisixStubService] Creating consumer: #{consumer_name}"

    # Store in memory for later retrieval
    @consumers[consumer_name] = {
      username: consumer_name,
      desc: metadata[:description] || "API Key: #{metadata[:name]}",
      plugins: {
        "key-auth": {
          key: api_key
        }
      },
      labels: metadata.slice(:account_id, :name).transform_keys(&:to_s)
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
      labels: metadata.slice(:account_id, :name).transform_keys(&:to_s)
    }

    consumer_name
  end

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
