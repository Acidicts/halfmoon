# frozen_string_literal: true

class HomeController < ApplicationController
  layout "home"
  include SlackInvitations

  before_action :require_authentication, only: %i[rsvps_count create_rsvp]

  FAQ_QUESTIONS = {
    "Who can join?": "Anyone who's 13-18! It's a Hack Club You Ship, We Ship, so the usual YSWS eligibility rules apply. No experience needed: if you can open a code editor, you're qualified. If you're 19 or older, anyone you may know who fits the age range.",
    "Is this running?": "No as this is currently a draft ysws yet to be sponsored by hackclub hq. RSVP to speed the process up!",
    "Can I use AI?": "Only 30% can be AI and you must be able to explain all major parts of your project.",
    "What if I don't have a friend to do it with?": "You can find someone here on hackclub to do it with.",
    "What if my friend quits midway through?": "You can find a new person or get given a random project from us.",
    "Does the project have to be open source": "Yes as this is a requirment for hackclub YSWS.",
    "I don't have any friends": "Umm, well I'll be your friend except I won't finish you project :P but you complete mine",
    "I don't know how to code": "You won't need to have a friend if you don't want to jump in immediately, instead you can pickup a starter project which you continue off of one of my projects!"
  }.freeze

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
