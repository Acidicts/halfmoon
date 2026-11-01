# frozen_string_literal: true

require "rails_helper"
require "rake"

extend Rake::DSL
load Rails.root.join("lib/tasks/invite_rsvped_users.rake").to_s

# The task declares `=> :environment`, which Rails registers when tasks are
# loaded via `bin/rails`. In specs the environment is already loaded, so define
# a no-op prerequisite so the task can be invoked directly.
task :environment

RSpec.describe "invite:rsvped_users" do
  let(:task) { Rake::Task["invite:rsvped_users"] }

  before do
    task.reenable
    allow(SlackBotService).to receive(:in_channel?).and_return(false)
    allow(SlackBotService).to receive(:add_to_channel).and_return(true)
  end

  it "invites every RSVPed user that has a slack_id" do
    rsvped_users = create_list(:user, 3)
    rsvped_users.each { |u| create(:rsvp, user: u) }
    create(:user) # no RSVP, must not be invited

    task.invoke

    expect(SlackBotService).to have_received(:add_to_channel).exactly(3).times
    rsvped_users.each do |user|
      expect(SlackBotService).to have_received(:add_to_channel).with(slack_id: user.slack_id)
    end
  end

  it "skips RSVPed users without a slack_id" do
    with_slack = create(:user, slack_id: "U11111111")
    without_slack = create(:user, slack_id: nil)
    create(:rsvp, user: with_slack)
    create(:rsvp, user: without_slack)

    task.invoke

    expect(SlackBotService).to have_received(:add_to_channel).with(slack_id: "U11111111").once
    expect(SlackBotService).not_to have_received(:add_to_channel).with(slack_id: nil)
  end

  it "does not re-invite users already in the channel" do
    already = create(:user, slack_id: "U22222222")
    not_yet = create(:user, slack_id: "U33333333")
    create(:rsvp, user: already)
    create(:rsvp, user: not_yet)

    allow(SlackBotService).to receive(:in_channel?).with("U22222222").and_return(true)
    allow(SlackBotService).to receive(:in_channel?).with("U33333333").and_return(false)

    task.invoke

    expect(SlackBotService).to have_received(:add_to_channel).with(slack_id: "U33333333").once
    expect(SlackBotService).not_to have_received(:add_to_channel).with(slack_id: "U22222222")
  end

  it "makes no Slack API calls in dry-run mode" do
    create_list(:user, 2).each { |u| create(:rsvp, user: u) }

    task.invoke("dry")

    expect(SlackBotService).not_to have_received(:add_to_channel)
    expect(SlackBotService).not_to have_received(:in_channel?)
  end

  it "respects the limit argument" do
    create_list(:user, 5).each { |u| create(:rsvp, user: u) }

    task.invoke(nil, 2)

    expect(SlackBotService).to have_received(:add_to_channel).exactly(2).times
  end
end
