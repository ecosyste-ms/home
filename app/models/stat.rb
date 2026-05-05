require 'net/http'

class Stat
  SOURCES = {
    packages: 'https://packages.ecosyste.ms',
    repos: 'https://repos.ecosyste.ms',
    advisories: 'https://advisories.ecosyste.ms',
    commits: 'https://commits.ecosyste.ms',
    issues: 'https://issues.ecosyste.ms',
    sponsors: 'https://sponsors.ecosyste.ms',
    docker: 'https://docker.ecosyste.ms',
    dependabot: 'https://dependabot.ecosyste.ms'
  }

  MULTIPLIERS = {
    'thousand' => 1_000, 'k' => 1_000,
    'million' => 1_000_000, 'm' => 1_000_000,
    'billion' => 1_000_000_000, 'b' => 1_000_000_000
  }

  def self.fetch_all
    stats = {}
    SOURCES.each do |key, url|
      stats[key] = fetch(url)
    end
    stats
  end

  def self.fetch(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 10
    http.read_timeout = 10

    response = http.get(uri.path.empty? ? '/' : uri.path, { 'User-Agent' => 'ecosyste.ms home' })
    raise "#{url} returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    parse(response.body)
  end

  def self.parse(html)
    doc = Nokogiri::HTML(html)
    stats = {}

    doc.css('.card-body, .stat-card-body').each do |card|
      title = card.at_css('.card-title, .stat-card-title')
      label = card.at_css('.card-text, .stat-card-text')
      next unless title && label

      value = parse_number(title.text)
      next unless value

      stats[label.text.strip] ||= value
    end

    doc.css('p, div, span').each do |node|
      node.text.scan(/([A-Z][\w ]+?):\s*([\d,]+)/) do |label, num|
        stats[label.strip] ||= parse_number(num)
      end
    end

    stats
  end

  def self.parse_number(text)
    text = text.strip
    if text =~ /\A([\d,.]+)\s*(thousand|million|billion|k|m|b)\b/i
      ($1.delete(',').to_f * MULTIPLIERS[$2.downcase]).to_i
    elsif text =~ /\A[\d,]+\z/
      text.delete(',').to_i
    end
  end

  def self.humanize(value)
    ActiveSupport::NumberHelper.number_to_human(
      value,
      precision: 3,
      significant: true,
      units: { million: 'million', billion: 'billion' },
      format: '%n %u'
    ).strip
  end

  def self.short(value)
    ActiveSupport::NumberHelper.number_to_human(
      value,
      precision: 3,
      significant: true,
      units: { unit: '', thousand: 'k', million: 'm', billion: 'b' },
      format: '%n%u'
    ).strip
  end
end
