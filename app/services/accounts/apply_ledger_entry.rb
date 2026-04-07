# frozen_string_literal: true

# app/services/accounts/apply_ledger_entry.rb

module Accounts
  class ApplyLedgerEntry
    include Dry::Monads[:result]

    # @param account [Account] the account to apply the entry to
    # @param order [Order] the related order
    # @param entry_type [Symbol] :debit, :credit, or :reversal
    # @param amount_cents [Integer] positive amount in cents
    # @param reference [String, nil] optional reference string
    # @param metadata [Hash] optional metadata
    # @return [Dry::Monads::Result] Success(LedgerEntry) or Failure(Symbol)
    def call(account:, order:, entry_type:, amount_cents:, **opts)
      return Failure(:invalid_amount) unless amount_cents.is_a?(Integer) && amount_cents.positive?
      return Failure(:currency_mismatch) if order.currency != account.currency

      entry = execute_transaction(account, order, entry_type, amount_cents, opts)
      Success(entry)
    rescue Accounts::InsufficientFundsError
      Failure(:insufficient_funds)
    end

    private

    def execute_transaction(account, order, entry_type, amount_cents, opts)
      ActiveRecord::Base.transaction do
        account.lock!
        apply_entry(account, order, entry_type, amount_cents, opts)
      end
    end

    def apply_entry(account, order, entry_type, amount_cents, opts)
      delta = calculate_delta(entry_type, amount_cents)
      raise Accounts::InsufficientFundsError if (account.balance_cents + delta).negative?

      entry = LedgerEntry.create!(
        account: account, order: order, entry_type: entry_type,
        amount_cents: amount_cents, currency: account.currency,
        reference: opts[:reference], metadata: opts[:metadata] || {},
      )
      account.update!(balance_cents: account.balance_cents + delta)
      entry
    end

    def calculate_delta(entry_type, amount_cents)
      case entry_type.to_sym
      when :credit, :reversal then amount_cents
      when :debit then -amount_cents
      end
    end
  end
end
