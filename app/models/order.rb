# frozen_string_literal: true

# app/models/order.rb

class Order < ApplicationRecord
  include AASM

  belongs_to :user
  has_many :ledger_entries, dependent: :restrict_with_error

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true

  enum :status, { created: 0, payment_pending: 1, successful: 2, cancelled: 3 }

  aasm column: :status, enum: true, whiny_persistence: true do
    state :created, initial: true
    state :payment_pending
    state :successful
    state :cancelled

    event :start_payment do
      transitions from: :created, to: :payment_pending
    end

    event :mark_successful do
      transitions from: :payment_pending, to: :successful
    end

    event :cancel do
      transitions from: :successful, to: :cancelled
    end
  end
end
