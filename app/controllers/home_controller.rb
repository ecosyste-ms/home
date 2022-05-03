class HomeController < ApplicationController
  def index
    @services = [
      {
        name: 'Packages',
        url: 'https://packages.ecosyste.ms',
        description: 'An open API service providing package, version and dependency metadata many open source software ecosystems and registries.',
        icon: 'box-seam',
        repo: 'packages'
      },
      {
        name: 'Timeline',
        url: 'https://timeline.ecosyste.ms',
        description: 'An open API service providing the timeline of over 4 Billion events for every public repo on GitHub, all the way back to 2015.',
        icon: 'clock-history',
        repo: 'timeline'
      },
      {
        name: 'Parser',
        url: 'https://parser.ecosyste.ms',
        description: 'An open API service to parse dependency metadata from many open source software ecosystems manifest files.',
        icon: 'bar-chart-steps',
        repo: 'parser'
      },
      {
        name: 'Digest',
        url: 'https://digest.ecosyste.ms',
        description: 'An open API service providing digests of packages from many open source software ecosystems and registries.',
        icon: 'hash',
        repo: 'digest'
      },
    ]
  end
end