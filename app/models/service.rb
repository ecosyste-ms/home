class Service
  def self.all
    [
      {
        name: 'Packages',
        url: 'https://packages.ecosyste.ms',
        description: 'An open API service providing package, version and dependency metadata of many open source software ecosystems and registries.',
        icon: 'box-seam',
        repo: 'packages'
      },
      {
        name: 'Timeline',
        url: 'https://timeline.ecosyste.ms',
        description: 'An open API service providing the timeline of over 6 Billion events for every public repo on GitHub, all the way back to 2015.',
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
        name: 'Archives',
        url: 'https://archives.ecosyste.ms',
        description: 'An open API service for inspecting package archives and files from many open source software ecosystems.',
        icon: 'folder2-open',
        repo: 'archives'
      },
      {
        name: 'Digest',
        url: 'https://digest.ecosyste.ms',
        description: 'An open API service providing digests of packages from many open source software ecosystems',
        icon: 'hash',
        repo: 'digest'
      },
      {
        name: 'Diff',
        url: 'https://diff.ecosyste.ms',
        description: 'An open API service to generate diffs between package releases for many open source software ecosystems.',
        icon: 'file-earmark-diff',
        repo: 'diff'
      },
      {
        name: 'Licenses',
        url: 'https://licenses.ecosyste.ms',
        description: 'An open API service to parse license metadata from many open source software ecosystems.',
        icon: 'check-square',
        repo: 'licenses'
      },
      {
        name: 'Repos',
        url: 'https://repos.ecosyste.ms',
        description: 'An open API service providing repository metadata for many open source software ecosystems',
        icon: 'journal-code',
        repo: 'repos'
      },
      {
        name: 'Resolve',
        url: 'https://resolve.ecosyste.ms',
        description: 'An open API service to resolve dependency trees of packages for many open source software ecosystems.',
        icon: 'gear',
        repo: 'resolve'
      },
      {
        name: 'Advisories',
        url: 'https://advisories.ecosyste.ms',
        description: 'An open API service providing security vulnerability metadata for many open source software ecosystems.',
        icon: 'incognito',
        repo: 'advisories'
      },
      {
        name: 'Commits',
        url: 'https://commits.ecosyste.ms',
        description: 'An open API service providing commit metadata for open source projects.',
        icon: 'people',
        repo: 'commits'
      },
      {
        name: 'Docker',
        url: 'https://docker.ecosyste.ms',
        description: 'An open API service providing dependency metadata for docker projects.',
        icon: 'layers',
        repo: 'docker'
      },
      {
        name: 'Summary',
        url: 'https://summary.ecosyste.ms',
        description: 'An open API service for producing an overview of a list of open source projects.',
        icon: 'award',
        repo: 'summary'
      },
      {
        name: 'Issues',
        url: 'https://issues.ecosyste.ms',
        description: 'An open API service for providing issue and pull request metadata for open source projects.',
        icon: 'bug',
        repo: 'issues'
      },
      {
        name: 'OST',
        url: 'https://ost.ecosyste.ms',
        description: 'An open API service for discovering and reviewing projects for opensustain.tech.',
        icon: 'globe-americas',
        repo: 'ost'
      },
      {
        name: 'Papers',
        url: 'https://papers.ecosyste.ms',
        description: 'An open API service providing mapping between scientific papers and software projects that are mentioned in them.',
        icon: 'newspaper',
        repo: 'papers'
      },
    ]
  end
end