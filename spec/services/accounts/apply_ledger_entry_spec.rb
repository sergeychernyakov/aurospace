# frozen_string_literal: true

# spec/services/accounts/apply_ledger_entry_spec.rb

require 'rails_helper'

RSpec.describe Accounts::ApplyLedgerEntry do
  subject(:service) { described_class.new }

  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, balance_cents: 5000, currency: 'RUB') }
  let(:order) { create(:order, user: user, amount_cents: 1000, currency: 'RUB') }

  describe '#call' do
    context 'with credit entry' do
      it 'returns Success with the created entry' do
        result = service.call(account: account, order: order, entry_type: :credit, amount_cents: 1000)
        expect(result).to be_success
        expect(result.value!).to be_a(LedgerEntry)
      end

      it 'increases account balance' do
        expect {
          service.call(account: account, order: order, entry_type: :credit, amount_cents: 1000)
        }.to change { account.reload.balance_cents }.from(5000).to(6000)
      end

      it 'creates a LedgerEntry with correct attributes' do
        result = service.call(account: account, order: order, entry_type: :credit, amount_cents: 1000)
        entry = result.value!

        expect(entry.account).to eq(account)
        expect(entry.order).to eq(order)
        expect(entry.credit?).to be true
        expect(entry.amount_cents).to eq(1000)
        expect(entry.currency).to eq('RUB')
      end
    end

    context 'with debit entry' do
      it 'decreases account balance' do
        expect {
          service.call(account: account, order: order, entry_type: :debit, amount_cents: 2000)
        }.to change { account.reload.balance_cents }.from(5000).to(3000)
      end

      it 'creates a debit LedgerEntry' do
        result = service.call(account: account, order: order, entry_type: :debit, amount_cents: 2000)
        expect(result.value!.debit?).to be true
      end
    end

    context 'with reversal entry' do
      it 'increases account balance (compensating)' do
        expect {
          service.call(account: account, order: order, entry_type: :reversal, amount_cents: 500)
        }.to change { account.reload.balance_cents }.from(5000).to(5500)
      end

      it 'creates a reversal LedgerEntry' do
        result = service.call(account: account, order: order, entry_type: :reversal, amount_cents: 500)
        expect(result.value!.reversal?).to be true
      end
    end

    context 'with reference and metadata' do
      it 'stores reference on the entry' do
        result = service.call(
          account: account, order: order, entry_type: :credit,
          amount_cents: 100, reference: 'payment_123',
        )
        expect(result.value!.reference).to eq('payment_123')
      end

      it 'stores metadata on the entry' do
        result = service.call(
          account: account, order: order, entry_type: :credit,
          amount_cents: 100, metadata: { 'source' => 'webhook' },
        )
        expect(result.value!.metadata).to eq({ 'source' => 'webhook' })
      end
    end

    context 'when insufficient funds for debit' do
      it 'returns Failure(:insufficient_funds)' do
        result = service.call(account: account, order: order, entry_type: :debit, amount_cents: 10_000)
        expect(result).to be_failure
        expect(result.failure).to eq(:insufficient_funds)
      end

      it 'does not change account balance' do
        expect {
          service.call(account: account, order: order, entry_type: :debit, amount_cents: 10_000)
        }.not_to(change { account.reload.balance_cents })
      end

      it 'does not create a LedgerEntry' do
        expect {
          service.call(account: account, order: order, entry_type: :debit, amount_cents: 10_000)
        }.not_to change(LedgerEntry, :count)
      end
    end

    context 'with invalid amount' do
      it 'returns Failure(:invalid_amount) for zero' do
        result = service.call(account: account, order: order, entry_type: :credit, amount_cents: 0)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_amount)
      end

      it 'returns Failure(:invalid_amount) for negative' do
        result = service.call(account: account, order: order, entry_type: :credit, amount_cents: -100)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_amount)
      end

      it 'returns Failure(:invalid_amount) for non-integer' do
        result = service.call(account: account, order: order, entry_type: :credit, amount_cents: 10.5)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_amount)
      end

      it 'returns Failure(:invalid_amount) for nil' do
        result = service.call(account: account, order: order, entry_type: :credit, amount_cents: nil)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_amount)
      end
    end

    context 'with currency mismatch' do
      let(:usd_order) { create(:order, user: user, amount_cents: 1000, currency: 'USD') }

      it 'returns Failure(:currency_mismatch)' do
        result = service.call(account: account, order: usd_order, entry_type: :credit, amount_cents: 1000)
        expect(result).to be_failure
        expect(result.failure).to eq(:currency_mismatch)
      end

      it 'does not create a LedgerEntry' do
        expect {
          service.call(account: account, order: usd_order, entry_type: :credit, amount_cents: 1000)
        }.not_to change(LedgerEntry, :count)
      end
    end

    context 'when transaction fails partway through' do
      it 'does not change balance if LedgerEntry creation fails' do
        allow(LedgerEntry).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

        expect {
          service.call(account: account, order: order, entry_type: :credit, amount_cents: 1000)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(account.reload.balance_cents).to eq(5000)
      end
    end
  end
end
