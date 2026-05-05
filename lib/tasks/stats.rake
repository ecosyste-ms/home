namespace :stats do
  desc 'Fetch current counts from ecosyste.ms services and update hardcoded numbers on the homepage and service list'
  task update: :environment do
    stats = Stat.fetch_all

    update_homepage(stats)
    update_services(stats)
  end

  def update_homepage(stats)
    path = Rails.root.join('app/views/home/index.html.erb')
    content = File.read(path)

    {
      'Packages' => stats.dig(:packages, 'Packages'),
      'Repositories' => stats.dig(:repos, 'Repositories'),
      'Dependencies' => stats.dig(:repos, 'Dependencies'),
      'Maintainers' => stats.dig(:packages, 'Maintainers')
    }.each do |label, value|
      raise "No value found for #{label}" unless value

      human = Stat.humanize(value)
      pattern = %r{(<span class="stat-card-title">)[^<]+(</span>\s*<span class="stat-card-text extra-small">#{label}</span>)}m
      raise "Could not find #{label} stat card in #{path}" unless content.match?(pattern)

      content = content.sub(pattern, "\\1#{human}\\2")
      puts "homepage #{label}: #{human}"
    end

    File.write(path, content)
  end

  def update_services(stats)
    path = Rails.root.join('app/models/service.rb')
    content = File.read(path)

    service_descriptions(stats).each do |name, description|
      if description.nil?
        puts "#{name}: skipped (no stats available on remote homepage)"
        next
      end

      pattern = /(name: '#{Regexp.escape(name)}',\s*url: '[^']+',\s*description: ')[^']+(')/m
      raise "Could not find #{name} in #{path}" unless content.match?(pattern)

      content = content.sub(pattern, "\\1#{description}\\2")
      puts "#{name}: #{description}"
    end

    File.write(path, content)
  end

  def service_descriptions(stats)
    s = ->(source, label) { Stat.short(stats.dig(source, label)) if stats.dig(source, label) }

    {
      'Packages' => ("Metadata for #{s[:packages, 'Packages']} packages across #{s[:packages, 'Registries']} sources" if s[:packages, 'Packages'] && s[:packages, 'Registries']),
      'Repositories' => ("Metadata for #{s[:repos, 'Repositories']} repositories across #{s[:repos, 'Hosts']} sources" if s[:repos, 'Repositories'] && s[:repos, 'Hosts']),
      'Advisories' => ("Metadata for #{s[:advisories, 'Advisories']} security advisories across 12 languages" if s[:advisories, 'Advisories']),
      'Commits' => ("#{Stat.humanize(stats.dig(:commits, 'Commits counted'))} commits across #{Stat.humanize(stats.dig(:commits, 'Repositories indexed'))} repositories" if stats.dig(:commits, 'Commits counted') && stats.dig(:commits, 'Repositories indexed')),
      'Issues' => ("#{Stat.humanize(stats.dig(:issues, 'Issues'))} issues and #{Stat.humanize(stats.dig(:issues, 'Pull requests'))} pull requests across #{Stat.humanize(stats.dig(:issues, 'Repositories'))} repositories" if stats.dig(:issues, 'Issues') && stats.dig(:issues, 'Pull requests') && stats.dig(:issues, 'Repositories')),
      'Sponsors' => ("#{s[:sponsors, 'Total Maintainers']} maintainers and #{s[:sponsors, 'Total Funders']} sponsors on GitHub Sponsors" if s[:sponsors, 'Total Maintainers'] && s[:sponsors, 'Total Funders']),
      'Docker' => ("#{s[:docker, 'Docker Images']} Docker images and their dependencies from Docker Hub" if s[:docker, 'Docker Images']),
      'Dependabot' => ("#{Stat.humanize(stats.dig(:dependabot, 'Total PRs'))} pull requests opened by Dependabot" if stats.dig(:dependabot, 'Total PRs')),
      'Timeline' => nil,
      'Open Collective' => nil
    }
  end
end
