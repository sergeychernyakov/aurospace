# frozen_string_literal: true

# app/models/ledger_entry.rb

class LedgerEntry < ApplicationRecord
  belongs_to :account
  belongs_to :order

  enum :entry_type, { debit: 0, credit: 1, reversal: 2 }

  validates :entry_type, presence: true
  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true

  # Immutable: prevent update and destroy after creation
  before_update { raise ActiveRecord::ReadOnlyRecord }
  before_destroy { raise ActiveRecord::ReadOnlyRecord }

  def self.ransackable_attributes(_auth_object = nil)
    ['id', 'account_id', 'order_id', 'entry_type', 'amount_cents', 'currency', 'reference', 'created_at', 'updated_at']
  end

  def self.ransackable_associations(_auth_object = nil)
    ['account', 'order']
  end
end
