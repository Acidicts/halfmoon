# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  before do
    OmniAuth.config.test_mode = true
    allow(SlackBotService).to receive(:add_to_channel).and_return(true)
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:hackclub] = nil
  end

  def mock_hackclub_auth(uid: "user-1", slack_id: "U12345")
    OmniAuth.config.mock_auth[:hackclub] = OmniAuth::AuthHash.new(
      provider: "hackclub",
      uid: uid,
      info: { name: "Test Hacker", email: "test@example.com", slack_id: slack_id }
    )
  end

  describe "pending RSVP replay after sign-in" do
    it "creates the rsvp and invites to Slack" do
      mock_hackclub_auth
      post "/rsvp" # unauthenticated: stores pending POST /rsvp in session
      expect(response).to redirect_to(new_session_path)

      expect { get "/auth/hackclub/callback" }.to change(Rsvp, :count).by(1)
      expect(response).to redirect_to(rsvp_thanks_path)
      expect(SlackBotService).to have_received(:add_to_channel).with(slack_id: "U12345")
    end

    it "still rsvps when the Slack invite raises" do
      mock_hackclub_auth
      allow(SlackBotService).to receive(:add_to_channel).and_raise(StandardError, "boom")
      post "/rsvp"

      expect { get "/auth/hackclub/callback" }.to change(Rsvp, :count).by(1)
      expect(response).to redirect_to(rsvp_thanks_path)
    end
  end
end
