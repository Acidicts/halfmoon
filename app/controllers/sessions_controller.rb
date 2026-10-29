# frozen_string_literal: true

class SessionsController < ApplicationController
  # The login button POSTs to /auth/hackclub (OmniAuth request phase, verified
  # against the Rails CSRF token); the IdP redirects back to #create.
  def new; end

  def create
    auth = request.env["omniauth.auth"]
    user = User.find_or_initialize_by(provider: auth["provider"], uid: auth["uid"])

    info = auth["info"] || {}

    user.name = info["name"].presence || user.name || "Hacker #{auth['uid']}"
    user.email = info["email"] if info["email"].present?
    user.slack_id = info["slack_id"] if info["slack_id"].present?
    user.save!

    # reset_session (session-fixation protection) wipes everything, so grab
    # the stored post-login destination / pending action first.
    return_to = session[:return_to_after_authenticating]
    pending_action = session[:pending_action_after_authenticating]

    reset_session
    session[:user_id] = user.id

    # Resume the action the user attempted before being asked to sign in.
    # Browsers can't replay a POST via redirect, so we perform the whitelisted
    # side effect here instead. Only explicitly listed paths run; anything
    # else falls through to the normal return_to redirect.
    if pending_action.is_a?(Hash) &&
       pending_action["method"] == "POST" &&
       pending_action["path"] == rsvp_path
      Rsvp.find_or_create_by(user: user)
      redirect_to rsvp_thanks_path, notice: "Signed in as #{user.name}"
      return
    end

    redirect_to(safe_return_to(return_to) || root_url,
                notice: "Signed in as #{user.name}")
  end

  def destroy
    reset_session
    redirect_to root_url, notice: "Signed out."
  end

  # OmniAuth redirects here via `OmniAuth.config.on_failure`.
  def failure
    redirect_to new_session_path, alert: "Sign in failed (#{params[:message] || 'unknown error'})."
  end

  private

  # Only redirect to in-app paths after login (open-redirect guard, in case the
  # session value was ever tampered with; the cookie store is signed, but cheap
  # to double-check).
  def safe_return_to(path)
    return nil unless path.is_a?(String)
    return nil unless path.start_with?("/") && !path.start_with?("//")

    path
  end
end
