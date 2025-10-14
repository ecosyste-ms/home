require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
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

  test 'api page shows services with APIs grouped by section' do
    get '/api'
    assert_response :success
    
    # Check that major sections are present
    assert_select 'h2', text: 'Data'
    assert_select 'h2', text: 'Tools'
    assert_select 'h2', text: 'Indexes'
    
    # Check that services with APIs are shown
    assert_select '.card-title', text: 'Packages'
    assert_select '.card-title', text: 'Repositories'
    assert_select '.card-title', text: 'Dependency Parser'
    
    # Check that API links are present
    assert_select 'a[href*="openapi.yaml"]', text: 'OpenAPI Spec'
    assert_select 'a[href*="/docs"]', text: 'Interactive Docs'
    
    # Check that services without APIs are mentioned
    assert_select 'h2', text: 'Services without APIs'
    assert_response_includes 'Digest'
    assert_response_includes 'Funds'
  end

  test 'api page filters out services without APIs from cards' do
    get '/api'
    assert_response :success
    
    # These services should NOT appear in the cards since they don't have APIs
    assert_select '.card-title', text: 'Digest', count: 0
    assert_select '.card-title', text: 'Funds', count: 0
  end

  test 'serves openapi.yml file' do
    get '/openapi.yml'
    assert_response :success
    assert_equal 'application/x-yaml', response.content_type
    assert_response_includes 'openapi: 3.0.1'
    assert_response_includes 'title: Ecosyste.ms APIs'
    assert_response_includes 'packages.ecosyste.ms/docs/api/v1/openapi.yaml'
  end

  test 'renders pricing page' do
    get '/pricing'
    assert_response :success
    assert_template 'pages/pricing'
    assert_select 'h1', 'Pricing'
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

    # Check all plan names are displayed
    assert_select '.card-title', text: 'Free'
    assert_select '.card-title', text: 'Pro'
    assert_select '.card-title', text: 'Enterprise'
  end

  test 'pricing page shows plan details' do
    get '/pricing'
    assert_response :success

    # Check for request limits
    assert_response_includes '300 requests'
    assert_response_includes '5,000 requests'
    assert_response_includes '20,000 requests'

    # Check for pricing
    assert_response_includes 'Free'
    assert_response_includes '$200'
    assert_response_includes '$800'
  end

  test 'pricing page displays plan features' do
    get '/pricing'
    assert_response :success

    # Check that features are shown
    assert_response_includes 'Basic rate limiting'
    assert_response_includes 'Priority support'
    assert_response_includes 'Dedicated support'
    assert_response_includes 'SLA guarantee'
  end

  test 'pricing page includes call to action buttons' do
    get '/pricing'
    assert_response :success

    assert_select 'a.btn', text: 'Get Started'
    assert_select 'a.btn', text: 'Choose Pro'
    assert_select 'a.btn', text: 'Contact Sales'
  end

  private

  def assert_response_includes(text)
    assert_includes response.body, text
  end
end