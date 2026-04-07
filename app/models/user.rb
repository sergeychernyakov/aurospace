# frozen_string_literal: true

# app/models/user.rb

class User < ApplicationRecord
  include Discard::Model

  has_one :account, dependent: :destroy
  has_many :orders, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    ['id', 'email', 'name', 'created_at', 'updated_at', 'discarded_at']
  end

  def self.ransackable_associations(_auth_object = nil)
    ['account', 'orders']
  end
end
