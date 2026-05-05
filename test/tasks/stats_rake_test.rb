require 'test_helper'
require 'rake'
require 'webmock/minitest'

class StatsRakeTest < ActiveSupport::TestCase
  def setup
    Rails.application.load_tasks unless Rake::Task.task_defined?('stats:update')
    Rake::Task['stats:update'].reenable

    @view_path = Rails.root.join('app/views/home/index.html.erb')
    @view_original = File.read(@view_path)
    @service_path = Rails.root.join('app/models/service.rb')
    @service_original = File.read(@service_path)
  end

  def teardown
    File.write(@view_path, @view_original)
    File.write(@service_path, @service_original)
  end

  def stub_sources
    bodies = {
      packages: '<div class="card-body"><h4 class="card-title">99,000,000</h4><p class="card-text">Packages</p></div>' \
                '<div class="card-body"><h4 class="card-title">5,000,000</h4><p class="card-text">Maintainers</p></div>' \
                '<div class="card-body"><h4 class="card-title">110</h4><p class="card-text">Registries</p></div>',
      repos: '<div class="card-body"><h4 class="card-title">400,000,000</h4><p class="card-text">Repositories</p></div>' \
             '<div class="card-body"><h4 class="card-title">30,000,000,000</h4><p class="card-text">Dependencies</p></div>' \
             '<div class="card-body"><h4 class="card-title">2,000</h4><p class="card-text">Hosts</p></div>',
      advisories: '<div class="stat-card-body"><span class="stat-card-title">30,000</span><span class="stat-card-text">Advisories</span></div>',
      commits: '<div>Repositories indexed: 7,000,000 - Commits counted: 1,000,000,000</div>',
      issues: '<div class="stat-card-body"><span class="stat-card-title">40 Million</span><span class="stat-card-text">Issues</span></div>' \
              '<div class="stat-card-body"><span class="stat-card-title">120 Million</span><span class="stat-card-text">Pull requests</span></div>' \
              '<div class="stat-card-body"><span class="stat-card-title">15 Million</span><span class="stat-card-text">Repositories</span></div>',
      sponsors: '<p><strong>Total Maintainers:</strong> 40,000</p><p><strong>Total Funders:</strong> 180,000</p>',
      docker: '<div class="card-body"><h4 class="card-title">700,000</h4><p class="card-text">Docker Images</p></div>',
      dependabot: '<div class="card-body"><h4 class="card-title">10,000,000</h4><p class="card-text">Total PRs</p></div>'
    }
    Stat::SOURCES.each do |key, url|
      stub_request(:get, "#{url}/").to_return(status: 200, body: bodies[key] || '')
    end
  end

  test 'update rewrites stat card numbers in the homepage view' do
    stub_sources

    capture_io { Rake::Task['stats:update'].invoke }

    result = File.read(@view_path)
    assert_match %r{<span class="stat-card-title">99 million</span>\s*<span class="stat-card-text extra-small">Packages</span>}, result
    assert_match %r{<span class="stat-card-title">400 million</span>\s*<span class="stat-card-text extra-small">Repositories</span>}, result
    assert_match %r{<span class="stat-card-title">30 billion</span>\s*<span class="stat-card-text extra-small">Dependencies</span>}, result
    assert_match %r{<span class="stat-card-title">5 million</span>\s*<span class="stat-card-text extra-small">Maintainers</span>}, result
  end

  test 'update rewrites service descriptions' do
    stub_sources

    capture_io { Rake::Task['stats:update'].invoke }

    result = File.read(@service_path)
    assert_includes result, "description: 'Metadata for 99m packages across 110 sources'"
    assert_includes result, "description: 'Metadata for 400m repositories across 2k sources'"
    assert_includes result, "description: 'Metadata for 30k security advisories across 12 languages'"
    assert_includes result, "description: '1 billion commits across 7 million repositories'"
    assert_includes result, "description: '40 million issues and 120 million pull requests across 15 million repositories'"
    assert_includes result, "description: '40k maintainers and 180k sponsors on GitHub Sponsors'"
    assert_includes result, "description: '700k Docker images and their dependencies from Docker Hub'"
    assert_includes result, "description: '10 million pull requests opened by Dependabot'"
  end

  test 'update skips services with no available stats' do
    stub_sources

    out, = capture_io { Rake::Task['stats:update'].invoke }

    assert_match(/Timeline: skipped/, out)
    assert_match(/Open Collective: skipped/, out)
  end

  test 'update raises when a homepage label is missing' do
    Stat::SOURCES.each_value do |url|
      stub_request(:get, "#{url}/").to_return(status: 200, body: '')
    end

    error = assert_raises(RuntimeError) do
      capture_io { Rake::Task['stats:update'].invoke }
    end
    assert_match(/No value found/, error.message)
    assert_equal @view_original, File.read(@view_path)
    assert_equal @service_original, File.read(@service_path)
  end
end
