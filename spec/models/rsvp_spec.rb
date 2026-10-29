# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: rsvps
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_rsvps_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
RSpec.describe Rsvp, type: :model do
  it "has a valid factory" do
    expect(build(:rsvp)).to be_valid
  end

  it { is_expected.to belong_to(:user) }
end
