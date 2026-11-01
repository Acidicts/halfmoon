# frozen_string_literal: true

class HomeController < ApplicationController
  layout "home"
  include SlackInvitations

  before_action :require_authentication, only: %i[rsvps_count create_rsvp]

  def index; end

  def about; end

  def rsvp
    @rsvped = Rsvp.find_by(user: current_user).presence
  end

  def rsvps_count
    @rsvps = Rsvp.count
    render "home/rsvps"
  end

  def rsvp_thanks; end

  def create_rsvp
    return unless current_user

    Rsvp.find_or_create_by(user: current_user)
    invite_to_slack(current_user)
    redirect_to rsvp_thanks_path
  end
end
