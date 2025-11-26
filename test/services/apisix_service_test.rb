require 'test_helper'
require 'webmock/minitest'

class ApisixServiceTest < ActiveSupport::TestCase
  def setup
    @service = ApisixService.new
    @base_url = ENV.fetch('APISIX_ADMIN_URL', 'http://localhost:9180')
    @admin_key = ENV.fetch('APISIX_ADMIN_KEY', nil)
  end

  test 'create_consumer creates a consumer with key-auth plugin' do
    consumer_name = 'test_key_prefix'
    api_key = 'test_api_key_12345678901234567890'

    stub_request(:put, "#{@base_url}/apisix/admin/consumers/#{consumer_name}")
      .with(
        body: hash_including(
          username: consumer_name,
          plugins: hash_including('key-auth' => { key: api_key })
        )
      )
      .to_return(status: 200, body: '{"action":"set"}', headers: { 'Content-Type' => 'application/json' })

    result = @service.create_consumer(
      consumer_name: consumer_name,
      api_key: api_key,
      metadata: { name: 'Test Key', account_id: 123 }
    )

    assert_equal consumer_name, result
  end

  test 'delete_consumer deletes a consumer' do
    consumer_name = 'test_key_prefix'

    stub_request(:delete, "#{@base_url}/apisix/admin/consumers/#{consumer_name}")
      .to_return(status: 200, body: '{"deleted":"1"}', headers: { 'Content-Type' => 'application/json' })

    result = @service.delete_consumer(consumer_name: consumer_name)
    assert_equal true, result
  end

  test 'get_consumer returns consumer data' do
    consumer_name = 'test_key_prefix'
    response_body = {
      value: {
        username: consumer_name,
        plugins: { 'key-auth' => { key: 'test_key' } }
      }
    }.to_json

    stub_request(:get, "#{@base_url}/apisix/admin/consumers/#{consumer_name}")
      .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })

    result = @service.get_consumer(consumer_name)
    assert_equal consumer_name, result.dig('value', 'username')
  end

  test 'get_consumer returns nil for 404' do
    consumer_name = 'nonexistent'

    stub_request(:get, "#{@base_url}/apisix/admin/consumers/#{consumer_name}")
      .to_return(status: 404, body: '{"error_msg":"not found"}', headers: { 'Content-Type' => 'application/json' })

    result = @service.get_consumer(consumer_name)
    assert_nil result
  end

  test 'raises ConnectionError when APISIX is unreachable' do
    consumer_name = 'test_key_prefix'

    stub_request(:put, "#{@base_url}/apisix/admin/consumers/#{consumer_name}")
      .to_raise(SocketError.new('Failed to open TCP connection'))

    assert_raises(ApisixService::ConnectionError) do
      @service.create_consumer(
        consumer_name: consumer_name,
        api_key: 'test_key',
        metadata: {}
      )
    end
  end

  test 'raises ApiError for non-success responses' do
    consumer_name = 'test_key_prefix'

    stub_request(:put, "#{@base_url}/apisix/admin/consumers/#{consumer_name}")
      .to_return(status: 500, body: '{"error":"Internal server error"}', headers: { 'Content-Type' => 'application/json' })

    assert_raises(ApisixService::ApiError) do
      @service.create_consumer(
        consumer_name: consumer_name,
        api_key: 'test_key',
        metadata: {}
      )
    end
  end

  test 'update_consumer_metadata updates consumer description and labels' do
    consumer_name = 'test_key_prefix'
    existing_consumer = {
      value: {
        username: consumer_name,
        plugins: { 'key-auth' => { key: 'existing_key' } }
      }
    }.to_json

    stub_request(:get, "#{@base_url}/apisix/admin/consumers/#{consumer_name}")
      .to_return(status: 200, body: existing_consumer, headers: { 'Content-Type' => 'application/json' })

    stub_request(:put, "#{@base_url}/apisix/admin/consumers/#{consumer_name}")
      .with(
        body: hash_including(
          desc: 'API Key: Updated Name',
          labels: hash_including('name' => 'Updated_Name')
        )
      )
      .to_return(status: 200, body: '{"action":"set"}', headers: { 'Content-Type' => 'application/json' })

    result = @service.update_consumer_metadata(
      consumer_name: consumer_name,
      metadata: { name: 'Updated Name', account_id: 123 }
    )

    assert_equal consumer_name, result
  end
end
