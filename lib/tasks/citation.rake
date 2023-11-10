namespace :citation do
  desc "Citation"
  task :generate, [:name] => :environment do |t, args|
    services = Service.all
    service = services.find{|s| s[:name].downcase == args[:name].to_s.downcase}
    citation = <<-CITATION
cff-version: 1.2.0
title: 'Ecosyste.ms: #{service[:name]}'
message: >-
  If you use this software, please cite it using the
  metadata from this file.
type: software
authors:
  - given-names: Andrew
    family-names: Nesbitt
    email: andrew@ecosyste.ms
    orcid: 'https://orcid.org/0009-0007-2710-1118'
repository-code: 'https://github.com/ecosyste-ms/#{service[:repo]}'
url: '#{service[:url]}'
abstract: >-
  #{service[:description]}
keywords:
  - open source
  - package management
  - software
license: AGPL-3.0
    CITATION

    puts citation
  end
end