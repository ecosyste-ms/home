class Service
  def self.sections
    [
      {
        name: 'Data',
        description: 'Core ecosyste.ms datasets',
        icon: 'data.svg',
        services: [
          {
            name: 'Packages',
            url: 'https://packages.ecosyste.ms',
            description: 'Metadata for 10.7m packages across 63 sources'
          },
          {
            name: 'Repositories',
            url: 'https://repos.ecosyste.ms',
            description: 'Metadata for 230m packages across 1877 sources'
          },
          {
            name: 'Advisories',
            url: 'https://advisories.ecosyste.ms',
            description: 'Metadata for 20k security advisories across 12 languages (under development)'
          }
        ]
      },
      {
        name: 'Tools',
        description: 'Use ecosystems intelligence to get things done',
        icon: 'tools.svg',
        services: [
          {
            name: 'Dependency Parser',
            url: 'https://parser.ecosyste.ms',
            description: 'Resolve the full dependency tree for a repository',
          },
          {
            name: 'Dependency Resolver',
            url: 'https://resolve.ecosyste.ms',
            description: 'Resolve the full dependency tree for a package',
          },
          {
            name: 'SBOM Parser',
            url: 'https://sbom.ecosyste.ms',
            description: 'Parse and convert between SBOM file formats',
          },
          {
            name: 'License Parser',
            url: 'https://licenses.ecosyste.ms',
            description: 'Extract license metadata from a package or repository',
          },
          {
            name: 'Digest',
            url: 'https://digest.ecosyste.ms',
            description: 'Check the integrity of a package or repository',
          },
          {
            name: 'Archives',
            url: 'https://archives.ecosyste.ms',
            description: 'Inspect the contents of a package or repository',
          },
          {
            name: 'Diff',
            url: 'https://diff.ecosyste.ms',
            description: 'Compare the contents of two packages or repositories',
          },
          {
            name: 'Summary',
            url: 'https://summary.ecosyste.ms',
            description: 'Produce an overview of a list of open source projects',
          },
        ]
      },
      {
        name: 'Indexes',
        description: 'Additional data powering ecosyste.ms core services, provided direct for your own use',
        icon: 'indexes.svg',
        services: [
          {
            name: 'Timeline',
            url: 'https://timeline.ecosyste.ms',
            description: '6 billion events for every public repo on GitHub',
          },
          {
            name: 'Commits',
            url: 'https://commits.ecosyste.ms',
            description: '570 million commits across 2.3 million repositories',
          },
          {
            name: 'Issues',
            url: 'https://issues.ecosyste.ms',
            description: '20.9 million issues and 44 million pull requests across 5.4 million repositories',
          },
          {
            name: 'Sponsors',
            url: 'https://sponsors.ecosyste.ms',
            description: '31k maintainers and 125k sponsors on GitHub Sponsors',
          },
          {
            name: 'Docker',
            url: 'https://docker.ecosyste.ms',
            description: '600k Docker images and their dependencies from Docker Hub',
          },
          {
            name: 'Open Collective',
            url: 'https://opencollective.ecosyste.ms',
            description: '$48m in open source grants, donations, and sponsorships from Open Collective',
          },
        ]
      },
      {
        name: 'Applications',
        description: 'Full applications built by the ecosyste.ms team',
        icon: 'applications.svg',
        services: [
          {
            name: 'Funds',
            url: 'https://funds.ecosyste.ms',
            description: 'Support your core open source dependencies'
          },
        ]
      },
      {
        name: 'Experiments',
        description: 'The following datasets and services are created as demonstrators or as part of partnerships with ecosystem teams',
        icon: 'experiment.svg',
        services: [
          {
            name: 'OST',
            url: 'https://ost.ecosyste.ms',
            description: 'A curated list of technology projects protecting and sustaining our climate and environment',
          },
          {
            name: 'Papers',
            url: 'https://papers.ecosyste.ms',
            description: 'Indexing and attributing open source software mentioned in academic papers',
          },
          {
            name: 'Awesome',
            url: 'https://awesome.ecosyste.ms',
            description: 'Tracking thousands of “awesome lists” on GitHub',
          },
        ]
      }
    ]
  end
end