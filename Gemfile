source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: ".ruby-version"

gem "activerecord", "~> 8.0.0"
gem "actionpack", "~> 8.0.0"
gem "actionview", "~> 8.0.0"
gem "railties", "~> 8.0.0"
gem "activesupport", "~> 8.0.0"

gem "secure_headers"
gem "sprockets-rails"
gem "pg"
gem "puma"
gem "jbuilder"
gem "sassc-rails"
gem 'bootstrap'
gem 'jquery-rails'
gem 'bootstrap-icons', require: "bootstrap_icons"
gem 'appsignal'
gem 'ostruct'

group :test do
  gem "rails-controller-testing"
end

group :development, :test do
  gem "dotenv-rails", "~> 3.1"
end
