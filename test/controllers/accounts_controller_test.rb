require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test 'renders account overview page' do
    get account_path
    assert_response :success
    assert_template 'accounts/show'
    assert_select 'h1', 'Overview'
  end

  test 'overview page shows account details' do
    get account_path
    assert_response :success
    assert_select 'p', text: /Ben Nicholls/
    assert_select 'p', text: /ben@ecosyste\.ms/
  end

  test 'overview page shows plan information' do
    get account_path
    assert_response :success
    assert_select 'h3', 'Pro'
    assert_select 'p', text: /5,000 requests/
    assert_select 'p', text: /\$200/
  end

  test 'renders details page' do
    get details_account_path
    assert_response :success
    assert_template 'accounts/details'
    assert_select 'h1', 'Your details'
    assert_select 'input[name="account[name]"]'
    assert_select 'input[name="account[email]"]'
  end

  test 'renders plan page' do
    get plan_account_path
    assert_response :success
    assert_template 'accounts/plan'
    assert_select 'h1', 'Plan'
    assert_select 'h3.h4', 'Pro'
  end

  test 'renders api key page' do
    get api_key_account_path
    assert_response :success
    assert_template 'accounts/api_key'
    assert_select 'h1', 'API Key'
    assert_select 'h2.h3', 'Your API key'
  end

  test 'api key page displays the key' do
    get api_key_account_path
    assert_response :success
    assert_select 'input[value*="XMCM6"]'
  end

  test 'renders billing page' do
    get billing_account_path
    assert_response :success
    assert_template 'accounts/billing'
    assert_select 'h1', 'Billing'
    assert_select 'h2.h4', 'Payment method'
  end

  test 'billing page shows billing history table' do
    get billing_account_path
    assert_response :success
    assert_select 'table.table'
    assert_select 'thead th', text: 'Month'
    assert_select 'thead th', text: 'Amount'
    assert_select 'thead th', text: 'Invoice'
    assert_select 'tbody tr', count: 9
  end

  test 'renders security page' do
    get security_account_path
    assert_response :success
    assert_template 'accounts/security'
    assert_select 'h1', 'Password and security'
    assert_select 'h2', 'Linked accounts'
  end

  test 'security page shows linked identities' do
    get security_account_path
    assert_response :success
    assert_select '.well', text: /GitHub/
    assert_select '.well', text: /@benjam/
  end

  test 'all pages include navigation' do
    pages = [
      account_path,
      details_account_path,
      plan_account_path,
      api_key_account_path,
      billing_account_path,
      security_account_path
    ]

    pages.each do |page|
      get page
      assert_response :success
      assert_select 'ul.dboard-nav'
      assert_select 'a', text: 'Overview'
      assert_select 'a', text: 'Your details'
      assert_select 'a', text: 'Plan'
      assert_select 'a', text: 'API Key'
      assert_select 'a', text: 'Billing'
      assert_select 'a', text: 'Password and security'
    end
  end

  test 'all pages include header with account name' do
    pages = [account_path, details_account_path, plan_account_path]

    pages.each do |page|
      get page
      assert_response :success
      assert_select 'h1.display-1', 'Ben Nicholls'
    end
  end
end
