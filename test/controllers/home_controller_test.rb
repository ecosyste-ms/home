require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  test 'renders index' do
    get root_path
    assert_response :success
    assert_template 'home/index'
  end

  test 'renders styleguide for styleguide.ecosyste.ms domain' do
    get root_path, headers: { 'HTTP_HOST' => 'styleguide.ecosyste.ms' }
    assert_response :success
    assert_template 'pages/styleguide'
  end

  test 'renders regular index for other domains' do
    get root_path, headers: { 'HTTP_HOST' => 'ecosyste.ms' }
    assert_response :success
    assert_template 'home/index'
  end
end