require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    create(:plan,
      name: 'Free',
      price_cents: 0,
      requests_per_hour: 300,
      features: ['Basic rate limiting', 'Community support', 'Access to all APIs']
    )

    create(:plan,
      name: 'Researcher',
      price_cents: 10000,
      requests_per_hour: 2000,
      features: ['Standard rate limiting', 'Community support', 'Access to all APIs']
    )

    create(:plan,
      name: 'Developer',
      price_cents: 50000,
      requests_per_hour: 5000,
      features: ['High rate limiting', 'Priority support', 'Access to all APIs', 'Usage analytics']
    )
  end

  test 'renders api page' do
    get '/api'
    assert_response :success
    assert_template 'pages/api'
    assert_select 'h1', 'API Documentation'
    assert_select 'a[href="/openapi.yml"]', 'Download openapi.yml'
  end

  test 'api page has custom meta title and description' do
    get '/api'
    assert_response :success
    assert_select 'title', 'API Documentation - ecosyste.ms | Rate Limits & OpenAPI Specs'
    assert_select 'meta[name="description"][content="RESTful APIs with OpenAPI 3.0.1 specs for package ecosystem data. Polite pool access with email authentication, consistent JSON responses, and CC-BY-SA-4.0 licensing."]'
  end

  test 'renders pricing page' do
    get '/pricing'
    assert_response :success
    assert_template 'pages/pricing'
    assert_select 'h1', 'API Plans and Pricing'
  end

  test 'pricing page has custom meta title and description' do
    get '/pricing'
    assert_response :success
    assert_select 'title', 'Pricing - ecosyste.ms | API Rate Limits & Plans'
    assert_select 'meta[name="description"]'
  end

  test 'pricing page displays all plans' do
    get '/pricing'
    assert_response :success

    assert_select '.card-title', text: 'Free'
    assert_select '.card-title', text: 'Researcher'
    assert_select '.card-title', text: 'Developer'
  end

  test 'pricing page shows plan details' do
    get '/pricing'
    assert_response :success

    assert_response_includes '300 requests'
    assert_response_includes '2,000 requests'
    assert_response_includes '5,000 requests'

    assert_response_includes 'Free'
    assert_response_includes '$100'
    assert_response_includes '$500'
  end

  test 'pricing page displays plan features' do
    get '/pricing'
    assert_response :success

    # table/accordion feature labels
    assert_response_includes 'API Access'
    assert_response_includes 'Rate limit'
    assert_response_includes 'Quota reset'
    assert_response_includes 'Burst requests'
    assert_response_includes 'Request priority'
    assert_response_includes 'License'
    assert_response_includes 'Support'
    assert_response_includes 'SLA'
    assert_response_includes 'Dashboard access'
  end

  test 'pricing page includes call to action buttons' do
    get '/pricing'
    assert_response :success

    assert_select 'a.btn', text: 'Get access'
    assert_select 'a.btn', text: 'Choose'
  end

  private

  def assert_response_includes(text)
    assert_includes response.body, text
  end
end