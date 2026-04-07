# frozen_string_literal: true

# spec/services/orders/mark_successful_spec.rb

require 'rails_helper'

RSpec.describe Orders::MarkSuccessful do
  subject(:service) { described_class.new }

  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, balance_cents: 0, currency: 'RUB') }

  before { account }

  describe '#call' do
    context 'when order is payment_pending' do
      let(:order) do
        create(:order, :payment_pending, user: user, amount_cents: 5000, currency: 'RUB',
                                         external_payment_id: 'pay_abc',)
      end

      it 'returns Success with the order' do
        result = service.call(order: order)
        expect(result).to be_success
        expect(result.value!).to be_a(Order)
      end

      it 'transitions order to successful' do
        service.call(order: order)
        expect(order.reload).to be_successful
      end

      it 'sets paid_at timestamp' do
        freeze_time do
          service.call(order: order)
          expect(order.reload.paid_at).to eq(Time.zone.now)
        end
      end

      it 'creates a credit ledger entry' do
        expect {
          service.call(order: order)
        }.to change(LedgerEntry, :count).by(1)

        entry = LedgerEntry.last
        expect(entry.credit?).to be true
        expect(entry.amount_cents).to eq(5000)
        expect(entry.account).to eq(account)
        expect(entry.order).to eq(order)
      end

      it 'increases account balance' do
        expect {
          service.call(order: order)
        }.to change { account.reload.balance_cents }.from(0).to(5000)
      end

      it 'sets reference on ledger entry' do
        service.call(order: order)
        entry = LedgerEntry.last
        expect(entry.reference).to eq('payment_pay_abc')
      end

      it 'enqueues payment_successful email' do
        expect {
          service.call(order: order)
        }.to have_enqueued_job(SendOrderEmailJob).with(order.id, 'payment_successful')
      end
    end

    context 'when order is already successful (idempotent)' do
      let(:order) { create(:order, :successful, user: user, amount_cents: 5000, currency: 'RUB') }

      it 'returns Success with the order' do
        result = service.call(order: order)
        expect(result).to be_success
        expect(result.value!).to eq(order)
      end

      it 'does not create a ledger entry' do
        expect {
          service.call(order: order)
        }.not_to change(LedgerEntry, :count)
      end

      it 'does not change account balance' do
        expect {
          service.call(order: order)
        }.not_to(change { account.reload.balance_cents })
      end
    end

    context 'when order is in created state' do
      let(:order) { create(:order, user: user, amount_cents: 5000, currency: 'RUB') }

      it 'returns Failure(:invalid_transition)' do
        result = service.call(order: order)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_transition)
      end

      it 'does not create a ledger entry' do
        expect {
          service.call(order: order)
        }.not_to change(LedgerEntry, :count)
      end
    end

    context 'when order is cancelled' do
      let(:order) { create(:order, :cancelled, user: user, amount_cents: 5000, currency: 'RUB') }

      it 'returns Failure(:invalid_transition)' do
        result = service.call(order: order)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_transition)
      end
    end

    context 'when ledger entry fails' do
      let(:order) do
        create(:order, :payment_pending, user: user, amount_cents: 5000, currency: 'RUB',
                                         external_payment_id: 'pay_err',)
      end

      it 'returns Failure(:ledger_error) when ledger returns failure' do
        ledger_service = instance_double(Accounts::ApplyLedgerEntry)
        allow(Accounts::ApplyLedgerEntry).to receive(:new).and_return(ledger_service)
        allow(ledger_service).to receive(:call).and_return(Dry::Monads::Failure(:currency_mismatch))

        result = service.call(order: order)
        expect(result).to be_failure
        expect(result.failure).to eq(:ledger_error)
      end

      it 'does not change order status when ledger fails' do
        ledger_service = instance_double(Accounts::ApplyLedgerEntry)
        allow(Accounts::ApplyLedgerEntry).to receive(:new).and_return(ledger_service)
        allow(ledger_service).to receive(:call).and_return(Dry::Monads::Failure(:currency_mismatch))

        service.call(order: order)
        expect(order.reload).to be_payment_pending
      end
    end

    context 'when AASM raises unexpectedly inside transaction' do
      let(:order) do
        create(:order, :payment_pending, user: user, amount_cents: 5000, currency: 'RUB',
                                         external_payment_id: 'pay_race',)
      end

      it 'returns Failure(:invalid_transition)' do
        allow(order).to receive(:may_mark_successful?).and_return(true)
        err = AASM::InvalidTransition.allocate
        allow(order).to receive(:mark_successful!).and_raise(err)
        result = service.call(order: order)
        expect(result.failure).to eq(:invalid_transition)
      end
    end
  end
end
