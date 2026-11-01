# frozen_string_literal: true

source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.4"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgre-sql as the database for Active Record with redis for caching
gem "pg"
gem "redis"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

gem "image_processing", "~> 1.2"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

gem "slack-ruby-client", "~> 2.5"

group :development, :test do
  gem "brakeman", ">= 8.0.6", require: false
  gem "bundler-audit", require: false
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "dotenv-rails"
  gem "erb_lint", require: false
  gem "rubocop-rails-omakase", require: false

  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-rails"
end

group :development do
  gem "annotaterb"
  gem "rails_live_reload"
  gem "web-console"

  gem "ruby-lsp", ">= 0.18.0", require: false
  gem "ruby-lsp-rails", require: false

  gem "htmlbeautifier", require: false
  gem "rubocop", require: false
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
end

gem "bcrypt", "~> 3.1"

gem "omniauth", "~> 2.1"
gem "omniauth-oauth2", "~> 1.8"
gem "omniauth-rails_csrf_protection", "~> 2.0", require: "omniauth/rails_csrf_protection"

gem "simplecov", "~> 1.3", group: :test
