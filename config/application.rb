# frozen_string_literal: true

require_relative "boot"

require "uri"
require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
# require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Halfmoon
  # Host of the public origin (e.g. "halfmoon.bing-bong.uk" from APP_URL).
  # Used by config/environments/production.rb for Host Authorization.
  # Falls back to `default` so `assets:precompile` (which boots the app
  # without real env vars) never raises NoMethodError / KeyError.
  def self.app_host(default: nil)
    host = ENV["APP_HOST"].to_s.strip
    if host.empty?
      url = ENV["APP_URL"].to_s.strip
      unless url.empty?
        begin
          parsed = URI.parse(url.include?("://") ? url : "https://#{url}")
          host = parsed.host.to_s.strip
        rescue URI::InvalidURIError
          host = ""
        end
      end
    end
    host = host.downcase
    # Strip port if someone set "example.com:3000".
    host = host.split(":").first.to_s.strip
    host.empty? ? default : host
  end

  # Extra host allowlist entries from env vars (comma/space/semicolon
  # separated, URLs tolerated: "https://foo.com, bar.com").
  def self.hosts_from_env(*keys)
    keys.flat_map { |key| ENV[key].to_s.split(/[\s,;]+/) }
        .map(&:strip)
        .reject(&:empty?)
        .map { |value|
          candidate = value.include?("://") ? value : "https://#{value}"
          begin
            parsed_host = URI.parse(candidate).host.to_s.strip.downcase
            parsed_host.empty? ? value : parsed_host
          rescue URI::InvalidURIError
            value
          end
        }
        .map { |host| host.downcase.split(":").first.to_s.strip }
        .reject(&:empty?)
        .uniq
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil


    config.active_record.encryption.primary_key = ENV["ENCRYPTION_PRIMARY_KEY"]
    config.active_record.encryption.deterministic_key = ENV["ENCRYPTION_DETERMINISTIC_KEY"]
    config.active_record.encryption.key_derivation_salt = ENV["ENCRYPTION_KEY_DERIVATION_SALT"]
  end
end
