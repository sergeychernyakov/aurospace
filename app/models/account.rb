# frozen_string_literal: true

# app/models/account.rb

class Account < ApplicationRecord
  belongs_to :user
  has_many :ledger_entries, dependent: :restrict_with_error

  validates :user_id, uniqueness: true
  validates :currency, presence: true
  validates :balance_cents, numericality: { only_integer: true }
end
