# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :authenticated?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def authenticated?
    current_user.present?
  end

  def require_authentication
    return if authenticated?

    store_location_for_login
    redirect_to new_session_path, alert: "Please sign in with Hack Club to continue."
  end

  # Remember where the user wanted to go so SessionsController#create can send
  # them back after OAuth. GETs store the full path; non-GETs (e.g. POST /rsvp)
  # store the action so it can be replayed after sign-in (redirects are GET, so
  # the POST itself can't be replayed via redirect).
  def store_location_for_login
    # Don't store the sign-in / OAuth handshake itself, or we'd loop back to it.
    return if request.path.start_with?("/sign_in", "/auth", "/logout")

    if request.get?
      session[:return_to_after_authenticating] = request.fullpath if safe_return_path?(request.fullpath)
    else
      session[:pending_action_after_authenticating] = {
        "method" => request.request_method,
        "path" => request.path
      }
      # Fallback GET page for the same resource (e.g. POST /rsvp -> GET /rsvp)
      # in case the pending action can't be resumed automatically.
      session[:return_to_after_authenticating] = request.path if safe_return_path?(request.path)
    end
  end

  def safe_return_path?(path)
    path.present? && path.start_with?("/") && !path.start_with?("//")
  end
end
