# frozen_string_literal: true

# Best-effort Slack channel invite for users who RSVP.
#
# Failures are logged and swallowed so a Slack outage never blocks the RSVP
# or sign-in flow.
module SlackInvitations
  extend ActiveSupport::Concern

  private

  # Best-effort Slack invite: never blocks the RSVP on Slack failures.
  def invite_to_slack(user)
    SlackBotService.add_to_channel(slack_id: user.slack_id)
  rescue StandardError => e
    Rails.logger.error("[SlackBot] unexpected invite error for user #{user.id}: #{e.class}: #{e.message}")
    false
  end
end
