require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  test 'renders index' do
    get root_path
    assert_response :success
    assert_template 'home/index'
  end

  test 'renders service links without surrounding whitespace' do
    get root_path
    assert_response :success

    services = HomeController.helpers.ecosystems_services.values.flatten
    assert_select '#header__global__menu', count: 1
    assert_select '#header__global__menu a', count: services.length do |links|
      services.zip(links).each do |service, link|
        assert_equal service[:name], link.text
        assert_equal service[:url], link['href']
      end
    end
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
