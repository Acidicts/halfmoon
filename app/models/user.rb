# frozen_string_literal: true

class User < ApplicationRecord
  has_many :rsvps, dependent: :destroy

  validates :provider, :uid, presence: true
end
