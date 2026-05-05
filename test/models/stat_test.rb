require 'test_helper'
require 'webmock/minitest'

class StatTest < ActiveSupport::TestCase
  test 'parse extracts numbers from card-body markup' do
    html = <<~HTML
      <div class="card-body">
        <h4 class="card-title text-warning mb-1">14,075,683</h4>
        <p class="card-text small text-muted mb-0">Packages</p>
      </div>
      <div class="card-body">
        <h4 class="card-title text-secondary mb-1">2,125,984</h4>
        <p class="card-text small text-muted mb-0">Maintainers</p>
      </div>
    HTML

    stats = Stat.parse(html)
    assert_equal 14_075_683, stats['Packages']
    assert_equal 2_125_984, stats['Maintainers']
  end

  test 'parse extracts numbers from stat-card-body markup' do
    html = <<~HTML
      <div class="stat-card-body">
        <span class="stat-card-title stat-card-title--small">29,725</span>
        <span class="stat-card-text stat-card-text--small">Advisories</span>
      </div>
    HTML

    assert_equal 29_725, Stat.parse(html)['Advisories']
  end

  test 'parse handles humanized values in stat cards' do
    html = <<~HTML
      <div class="stat-card-body">
        <span class="stat-card-title">34.3 Million</span>
        <span class="stat-card-text">Issues</span>
      </div>
    HTML

    assert_equal 34_300_000, Stat.parse(html)['Issues']
  end

  test 'parse extracts label: number pairs from text' do
    html = <<~HTML
      <p class="mb-1"><strong>Total Maintainers:</strong> 36,761</p>
      <div>Repositories indexed: 6,270,883 - Commits counted: 907,830,556</div>
    HTML

    stats = Stat.parse(html)
    assert_equal 36_761, stats['Total Maintainers']
    assert_equal 6_270_883, stats['Repositories indexed']
    assert_equal 907_830_556, stats['Commits counted']
  end

  test 'parse ignores non-numeric card titles' do
    html = <<~HTML
      <div class="card-body">
        <h5 class="card-title"><a href="/packages/foo">foo/bar</a></h5>
        <p class="card-text">something</p>
      </div>
    HTML

    assert_empty Stat.parse(html)
  end

  test 'fetch_all keys results by source' do
    Stat::SOURCES.each_value do |url|
      stub_request(:get, "#{url}/").to_return(status: 200, body: '')
    end
    stub_request(:get, 'https://packages.ecosyste.ms/').to_return(
      status: 200,
      body: '<div class="card-body"><h4 class="card-title">100</h4><p class="card-text">Packages</p></div>'
    )

    stats = Stat.fetch_all
    assert_equal Stat::SOURCES.keys.sort, stats.keys.sort
    assert_equal 100, stats[:packages]['Packages']
  end

  test 'fetch raises on non-success response' do
    stub_request(:get, 'https://packages.ecosyste.ms/').to_return(status: 500)

    assert_raises(RuntimeError) { Stat.fetch('https://packages.ecosyste.ms') }
  end

  test 'parse_number handles delimited integers' do
    assert_equal 14_075_683, Stat.parse_number('14,075,683')
  end

  test 'parse_number handles humanized strings' do
    assert_equal 34_300_000, Stat.parse_number('34.3 Million')
    assert_equal 7_000_000_000, Stat.parse_number('7 billion')
    assert_equal 24_000, Stat.parse_number('24k')
  end

  test 'parse_number returns nil for non-numeric text' do
    assert_nil Stat.parse_number('foo/bar')
  end

  test 'humanize formats millions and billions' do
    assert_equal '14.1 million', Stat.humanize(14_075_683)
    assert_equal '293 million', Stat.humanize(292_715_127)
    assert_equal '24.6 billion', Stat.humanize(24_595_603_456)
  end

  test 'short formats with single-letter suffix' do
    assert_equal '14.1m', Stat.short(14_075_683)
    assert_equal '29.7k', Stat.short(29_725)
    assert_equal '103', Stat.short(103)
  end
end
