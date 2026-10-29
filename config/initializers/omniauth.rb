# frozen_string_literal: true

require Rails.root.join("lib/omniauth/strategies/hackclub")

Rails.application.config.middleware.use OmniAuth::Builder do
  # No callback_url override: the strategy derives the callback from APP_URL, which is the
  # origin registered on the Hack Club app. An override here was being applied verbatim and
  # a bare origin there sent the user back to the site root instead of the callback.
  provider :hackclub,
           ENV.fetch("HACKCLUB_CLIENT_ID", ""),
           ENV.fetch("HACKCLUB_CLIENT_SECRET", ""),
           scope: "profile email name slack_id verification_status"
end

# The request phase must be a POST carrying a CSRF token. Leaving it open to GET
# disables the check against login CSRF: another site can start an OAuth flow in
# a victim's browser and, if the IdP reuses an existing Hack Club session, the
# victim is silently signed in as whoever the attacker chose. OmniAuth's
# default AllowedRequestMethods already restricts this to POST, and the
# omniauth-rails_csrf_protection railtie verifies the Rails token issued via
# csrf_meta_tags / form_authenticity_token (CVE-2015-9284 mitigation).
OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.logger = Rails.logger
OmniAuth.config.on_failure = proc { |env| SessionsController.action(:failure).call(env) }
