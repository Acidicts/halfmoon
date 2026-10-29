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
FactoryBot.define do
  factory :user do
    provider { 'hackclub' }
    sequence(:uid) { |n| "user-#{n}" }
    name { 'Test Hacker' }
  end
end
