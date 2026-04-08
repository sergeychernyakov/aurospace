# frozen_string_literal: true

# spec/services/orders/cancel_spec.rb

require 'rails_helper'

RSpec.describe Orders::Cancel do
  subject(:service) { described_class.new }

  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, balance_cents: 5000, currency: 'RUB') }
  let(:order) { create(:order, :successful, user: user, amount_cents: 1000, currency: 'RUB') }

  before { account }

  describe '#call' do
    context 'with a successful order' do
      it 'returns Success with the cancelled order' do
        result = service.call(order: order)
        expect(result).to be_success
        expect(result.value!).to be_cancelled
      end

      it 'transitions order to cancelled' do
        service.call(order: order)
        expect(order.reload).to be_cancelled
      end

      it 'sets cancelled_at timestamp' do
        freeze_time do
          service.call(order: order)
          expect(order.reload.cancelled_at).to eq(Time.zone.now)
        end
      end

      it 'creates a reversal ledger entry' do
        expect {
          service.call(order: order)
        }.to change(LedgerEntry, :count).by(1)

        entry = LedgerEntry.last
        expect(entry.reversal?).to be true
        expect(entry.amount_cents).to eq(1000)
        expect(entry.account).to eq(account)
        expect(entry.order).to eq(order)
      end

      it 'increases account balance via reversal' do
        expect {
          service.call(order: order)
        }.to change { account.reload.balance_cents }.from(5000).to(6000)
      end

      it 'sets reference on ledger entry' do
        service.call(order: order)
        entry = LedgerEntry.last
        expect(entry.reference).to eq("cancel_order_#{order.id}")
      end
    end

    context 'when order is already cancelled' do
      let(:cancelled_order) { create(:order, :cancelled, user: user, amount_cents: 1000) }

      it 'returns Failure(:already_cancelled)' do
        result = service.call(order: cancelled_order)
        expect(result).to be_failure
        expect(result.failure).to eq(:already_cancelled)
      end

      it 'does not create a ledger entry' do
        expect {
          service.call(order: cancelled_order)
        }.not_to change(LedgerEntry, :count)
      end
    end

    context 'when order is in created state' do
      let(:created_order) { create(:order, user: user, amount_cents: 1000) }

      it 'returns Failure(:invalid_transition)' do
        result = service.call(order: created_order)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_transition)
      end

      it 'does not change order status' do
        service.call(order: created_order)
        expect(created_order.reload).to be_created
      end
    end

    context 'when order is in payment_pending state' do
      let(:pending_order) { create(:order, :payment_pending, user: user, amount_cents: 1000) }

      it 'returns Failure(:invalid_transition)' do
        result = service.call(order: pending_order)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_transition)
      end

      it 'does not create a ledger entry' do
        expect {
          service.call(order: pending_order)
        }.not_to change(LedgerEntry, :count)
      end
    end

    context 'when transaction fails partway through' do
      it 'does not change order status if ledger entry fails' do
        ledger_service = instance_double(Accounts::ApplyLedgerEntry)
        allow(Accounts::ApplyLedgerEntry).to receive(:new).and_return(ledger_service)
        allow(ledger_service).to receive(:call).and_return(
          Dry::Monads::Failure(:insufficient_funds),
        )

        expect {
          service.call(order: order)
        }.to raise_error(Dry::Monads::UnwrapError)

        expect(order.reload).to be_successful
      end

      it 'rolls back balance if update! after cancel fails' do
        allow(order).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)

        expect {
          service.call(order: order)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(account.reload.balance_cents).to eq(5000)
        expect(LedgerEntry.where(order: order).count).to eq(0)
      end
    end

    context 'when AASM raises unexpectedly inside transaction' do
      it 'returns Failure(:invalid_transition)' do
        allow(order).to receive(:may_cancel?).and_return(true)
        err = AASM::InvalidTransition.allocate
        allow(order).to receive(:cancel!).and_raise(err)
        result = service.call(order: order)
        expect(result.failure).to eq(:invalid_transition)
      end
    end
  end
end
