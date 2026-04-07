# frozen_string_literal: true

# app/models/order.rb

class Order < ApplicationRecord
  include AASM
  include Discard::Model

  default_scope -> { kept }

  belongs_to :user
  has_many :ledger_entries, dependent: :restrict_with_error

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true

  enum :status, { created: 0, payment_pending: 1, successful: 2, cancelled: 3 }

  scope :stale_payment_pending, lambda { |threshold = 30.minutes|
    where(status: :payment_pending).where(updated_at: ...threshold.ago)
  }

  def self.ransackable_attributes(_auth_object = nil)
    ['id', 'user_id', 'amount_cents', 'currency', 'status', 'paid_at', 'cancelled_at', 'created_at', 'updated_at',
     'discarded_at',]
  end

  def self.ransackable_associations(_auth_object = nil)
    ['user', 'ledger_entries']
  end

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
