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

  test 'lists search, proxy and live in the homepage experiments section' do
    get root_path
    assert_response :success

    assert_select '.directory-section', text: /Experiments/ do
      assert_select 'h4 a[href="https://search.ecosyste.ms"]', text: 'Search', count: 1
      assert_select 'p', text: 'Search popular open source packages and projects by name or description'
      assert_select 'h4 a[href="https://proxy.ecosyste.ms"]', text: 'Proxy', count: 1
      assert_select 'p', text: 'Cache package downloads across ecosystems with optional release cooldowns'
      assert_select 'h4 a[href="https://live.ecosyste.ms"]', text: 'Live', count: 1
      assert_select 'p', text: 'A live feed of new packages and versions from open source software ecosystems and registries'
    end
  end

  test 'lists search, proxy and live in the service menu experiments category' do
    get root_path
    assert_response :success

    assert_select '#header__global__menu .header__global__menu__category', text: /Experiments/ do
      assert_select 'a[href="https://search.ecosyste.ms"]', text: 'Search', count: 1
      assert_select 'a[href="https://proxy.ecosyste.ms"]', text: 'Proxy', count: 1
      assert_select 'a[href="https://live.ecosyste.ms"]', text: 'Live', count: 1
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
