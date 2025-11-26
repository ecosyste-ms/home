require "test_helper"

class ApisixStubServiceTest < ActiveSupport::TestCase
  setup do
    @service = ApisixStubService.new
  end

  test "create_consumer stores consumer in memory" do
    consumer_name = "test_key"
    api_key = "test_api_key_12345"
    metadata = { name: "Test Key", account_id: 1 }

    result = @service.create_consumer(
      consumer_name: consumer_name,
      api_key: api_key,
      metadata: metadata
    )

    assert_equal consumer_name, result
  end

  test "get_consumer returns stored consumer" do
    consumer_name = "test_key"
    api_key = "test_api_key_12345"
    metadata = { name: "Test Key", account_id: 1 }

    @service.create_consumer(
      consumer_name: consumer_name,
      api_key: api_key,
      metadata: metadata
    )

    consumer = @service.get_consumer(consumer_name)

    assert_not_nil consumer
    assert_equal consumer_name, consumer["value"][:username]
    assert_equal api_key, consumer["value"][:plugins][:"key-auth"][:key]
  end

  test "get_consumer returns nil for non-existent consumer" do
    result = @service.get_consumer("nonexistent")

    assert_nil result
  end

  test "delete_consumer removes consumer from memory" do
    consumer_name = "test_key"
    api_key = "test_api_key_12345"

    @service.create_consumer(
      consumer_name: consumer_name,
      api_key: api_key,
      metadata: {}
    )

    result = @service.delete_consumer(consumer_name: consumer_name)

    assert_equal true, result
    assert_nil @service.get_consumer(consumer_name)
  end

  test "update_consumer_metadata updates existing consumer" do
    consumer_name = "test_key"
    api_key = "test_api_key_12345"
    original_metadata = { name: "Original Name", account_id: 1 }

    @service.create_consumer(
      consumer_name: consumer_name,
      api_key: api_key,
      metadata: original_metadata
    )

    new_metadata = { name: "Updated Name", account_id: 1 }
    @service.update_consumer_metadata(
      consumer_name: consumer_name,
      metadata: new_metadata
    )

    consumer = @service.get_consumer(consumer_name)

    assert_equal "Updated_Name", consumer["value"][:labels]["name"]
  end

  test "update_consumer_metadata returns nil for non-existent consumer" do
    result = @service.update_consumer_metadata(
      consumer_name: "nonexistent",
      metadata: { name: "Test" }
    )

    assert_nil result
  end
end
