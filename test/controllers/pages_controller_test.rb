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

  private

  def assert_response_includes(text)
    assert_includes response.body, text
  end
end