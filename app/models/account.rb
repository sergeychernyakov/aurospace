# frozen_string_literal: true

# app/models/account.rb

class Account < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  belongs_to :user
  has_many :ledger_entries, dependent: :restrict_with_error

  validates :user_id, uniqueness: true
  validates :currency, presence: true
  validates :balance_cents, numericality: { only_integer: true }

  def self.ransackable_attributes(_auth_object = nil)
    ['id', 'user_id', 'balance_cents', 'currency', 'created_at', 'updated_at', 'discarded_at']
  end

  def self.ransackable_associations(_auth_object = nil)
    ['user', 'ledger_entries']
  end
end
