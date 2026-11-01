# frozen_string_literal: true

require "rails_helper"

RSpec.describe SlackBotService do
  let(:fake_client) { instance_double(Slack::Web::Client) }

  def build_service(token: "xoxb-test", channel: "C123")
    allow(Slack::Web::Client).to receive(:new).and_return(fake_client)
    described_class.new(token: token, default_channel_id: channel)
  end

  def slack_error(code)
    response = double("response", body: double("body", error: code))
    Slack::Web::Api::Errors::SlackError.new(code, response)
  end

  def members_page(members, next_cursor: "")
    double("members_page", members: members, response_metadata: double("metadata", next_cursor: next_cursor))
  end

  def without_slack_channel_env
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("SLACK_CHANNEL_ID").and_return(nil)
  end

  describe ".add_to_channel" do
    it "invites via the API and returns true" do
      allow(Slack::Web::Client).to receive(:new).and_return(fake_client)
      allow(fake_client).to receive(:conversations_members).and_return(members_page(%w[U1]))
      allow(fake_client).to receive(:conversations_invite).and_return({ "ok" => true })

      expect(described_class.add_to_channel(slack_id: "U456", channel_id: "C999")).to be(true)
      expect(fake_client).to have_received(:conversations_invite).with(channel: "C999", users: "U456")
    end
  end

  describe "#add_to_channel" do
    it "uses the default channel when none is given" do
      service = build_service
      allow(fake_client).to receive(:conversations_members).and_return(members_page(%w[U1]))
      allow(fake_client).to receive(:conversations_invite).and_return({ "ok" => true })

      expect(service.add_to_channel(slack_id: "U456")).to be(true)
      expect(fake_client).to have_received(:conversations_invite).with(channel: "C123", users: "U456")
    end

    it "prefers an explicit channel_id over the default" do
      service = build_service
      allow(fake_client).to receive(:conversations_members).and_return(members_page(%w[U1]))
      allow(fake_client).to receive(:conversations_invite).and_return({ "ok" => true })

      expect(service.add_to_channel(slack_id: "U456", channel_id: "C999")).to be(true)
      expect(fake_client).to have_received(:conversations_invite).with(channel: "C999", users: "U456")
    end

    it "returns false without calling the API when slack_id is blank" do
      service = build_service
      allow(fake_client).to receive(:conversations_invite)

      expect(service.add_to_channel(slack_id: "  ")).to be(false)
      expect(fake_client).not_to have_received(:conversations_invite)
    end

    it "returns false without calling the API when the token is missing" do
      service = build_service(token: "")
      allow(fake_client).to receive(:conversations_invite)

      expect(service.add_to_channel(slack_id: "U456")).to be(false)
      expect(fake_client).not_to have_received(:conversations_invite)
    end

    it "returns false without calling the API when the channel is missing" do
      without_slack_channel_env
      service = build_service(channel: "")
      allow(fake_client).to receive(:conversations_invite)

      expect(service.add_to_channel(slack_id: "U456")).to be(false)
      expect(fake_client).not_to have_received(:conversations_invite)
    end

    it "returns true when the user is already in the channel" do
      service = build_service
      allow(fake_client).to receive(:conversations_members).and_return(members_page(%w[U456]))
      allow(fake_client).to receive(:conversations_invite)

      expect(service.add_to_channel(slack_id: "U456")).to be(true)
      expect(fake_client).not_to have_received(:conversations_invite)
    end

    it "returns true via the already_in_channel API error" do
      service = build_service
      allow(fake_client).to receive(:conversations_members).and_return(members_page(%w[U1]))
      allow(fake_client).to receive(:conversations_invite).and_raise(slack_error("already_in_channel"))

      expect(service.add_to_channel(slack_id: "U456")).to be(true)
    end

    %w[cant_invite_self is_archived channel_not_found user_not_found not_in_channel channel_not_joined].each do |code|
      it "returns false on #{code}" do
        service = build_service
        allow(fake_client).to receive(:conversations_members).and_return(members_page(%w[U1]))
        allow(fake_client).to receive(:conversations_invite).and_raise(slack_error(code))

        expect(service.add_to_channel(slack_id: "U456")).to be(false)
      end
    end

    it "returns false on unexpected Slack errors" do
      service = build_service
      allow(fake_client).to receive(:conversations_members).and_return(members_page(%w[U1]))
      allow(fake_client).to receive(:conversations_invite).and_raise(slack_error("something_weird"))

      expect(service.add_to_channel(slack_id: "U456")).to be(false)
    end
  end

  describe ".in_channel?" do
    it "delegates to an instance and returns the result" do
      allow(Slack::Web::Client).to receive(:new).and_return(fake_client)
      allow(fake_client).to receive(:conversations_members).and_return(members_page(%w[U456]))

      expect(described_class.in_channel?("U456")).to be(true)
    end
  end

  describe "#in_channel?" do
    it "returns true when the user is on the first page" do
      service = build_service
      allow(fake_client).to receive(:conversations_members).and_return(members_page(%w[U1 U456]))

      expect(service.in_channel?("U456")).to be(true)
      expect(fake_client).to have_received(:conversations_members).with(channel: "C123", limit: 1000)
    end

    it "follows the cursor and returns true when the user is on a later page" do
      service = build_service
      allow(fake_client).to receive(:conversations_members).and_return(
        members_page(%w[U1 U2], next_cursor: "cursor-1"),
        members_page(%w[U456])
      )

      expect(service.in_channel?("U456")).to be(true)
      expect(fake_client).to have_received(:conversations_members).with(channel: "C123", limit: 1000, cursor: "cursor-1")
    end

    it "returns false when the user is absent after all pages" do
      service = build_service
      allow(fake_client).to receive(:conversations_members).and_return(
        members_page(%w[U1], next_cursor: "cursor-1"),
        members_page(%w[U2])
      )

      expect(service.in_channel?("U999")).to be(false)
    end

    it "prefers an explicit channel_id over the default" do
      service = build_service
      allow(fake_client).to receive(:conversations_members).and_return(members_page(%w[U456]))

      expect(service.in_channel?("U456", "C999")).to be(true)
      expect(fake_client).to have_received(:conversations_members).with(channel: "C999", limit: 1000)
    end

    it "accepts a User and reads its slack_id" do
      service = build_service
      allow(fake_client).to receive(:conversations_members).and_return(members_page(%w[U123]))
      user = build(:user, slack_id: "U123")

      expect(service.in_channel?(user)).to be(true)
      expect(fake_client).to have_received(:conversations_members).with(channel: "C123", limit: 1000)
    end

    it "returns false without calling the API when slack_id is blank" do
      service = build_service
      allow(fake_client).to receive(:conversations_members)

      expect(service.in_channel?("  ")).to be(false)
      expect(fake_client).not_to have_received(:conversations_members)
    end

    it "returns false without calling the API when the token is missing" do
      service = build_service(token: "")
      allow(fake_client).to receive(:conversations_members)

      expect(service.in_channel?("U456")).to be(false)
      expect(fake_client).not_to have_received(:conversations_members)
    end

    it "returns false without calling the API when the channel is missing" do
      without_slack_channel_env
      service = build_service(channel: "")
      allow(fake_client).to receive(:conversations_members)

      expect(service.in_channel?("U456")).to be(false)
      expect(fake_client).not_to have_received(:conversations_members)
    end

    %w[channel_not_found not_in_channel is_archived something_weird].each do |code|
      it "returns false on #{code}" do
        service = build_service
        allow(fake_client).to receive(:conversations_members).and_raise(slack_error(code))

        expect(service.in_channel?("U456")).to be(false)
      end
    end
  end
end
