# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    provider { 'hackclub' }
    sequence(:uid) { |n| "user-#{n}" }
    name { 'Test Hacker' }
  end
end
