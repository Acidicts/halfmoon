# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: users
#
#  id         :bigint           not null, primary key
#  email      :string
#  name       :string
#  provider   :string
#  role       :integer
#  uid        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  slack_id   :string
#
# Indexes
#
#  index_users_on_provider_and_uid  (provider,uid) UNIQUE
#
RSpec.describe User, type: :model do
  it "has a valid factory" do
    expect(build(:user)).to be_valid
  end

  it { is_expected.to have_one(:rsvp).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:provider) }
  it { is_expected.to validate_presence_of(:uid) }
end
