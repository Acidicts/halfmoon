# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rsvp, type: :model do
  it "has a valid factory" do
    expect(build(:rsvp)).to be_valid
  end

  it { is_expected.to belong_to(:user) }
end
