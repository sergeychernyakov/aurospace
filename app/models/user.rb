# frozen_string_literal: true

# app/models/user.rb

class User < ApplicationRecord
  has_one :account, dependent: :destroy
  has_many :orders, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
end
