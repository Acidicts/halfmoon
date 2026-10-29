# frozen_string_literal: true

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
class User < ApplicationRecord
  has_one :rsvp, dependent: :destroy
  encrypts :email, downcase: true
  encrypts :uid, deterministic: true
  encrypts :name

  validates :provider, :uid, presence: true
end
