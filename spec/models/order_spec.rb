# frozen_string_literal: true

# spec/models/order_spec.rb

require 'rails_helper'

RSpec.describe Order do
  subject(:order) { build(:order) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:ledger_entries).dependent(:restrict_with_error) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:amount_cents) }
    it { is_expected.to validate_numericality_of(:amount_cents).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:currency) }
  end

  describe 'AASM states' do
    it 'has created as initial state' do
      expect(order).to be_created
    end

    it 'defines all expected states' do
      expect(described_class.aasm.states.map(&:name)).to eq([:created, :payment_pending, :successful, :cancelled])
    end
  end

  describe 'AASM transitions' do
    describe '#start_payment' do
      context 'when order is created' do
        it 'transitions to payment_pending' do
          order.save!
          order.start_payment!
          expect(order).to be_payment_pending
        end
      end

      context 'when order is payment_pending' do
        subject(:order) { create(:order, :payment_pending) }

        it 'raises AASM::InvalidTransition' do
          expect { order.start_payment! }.to raise_error(AASM::InvalidTransition)
        end
      end

      context 'when order is successful' do
        subject(:order) { create(:order, :successful) }

        it 'raises AASM::InvalidTransition' do
          expect { order.start_payment! }.to raise_error(AASM::InvalidTransition)
        end
      end

      context 'when order is cancelled' do
        subject(:order) { create(:order, :cancelled) }

        it 'raises AASM::InvalidTransition' do
          expect { order.start_payment! }.to raise_error(AASM::InvalidTransition)
        end
      end
    end

    describe '#mark_successful' do
      context 'when order is payment_pending' do
        subject(:order) { create(:order, :payment_pending) }

        it 'transitions to successful' do
          order.mark_successful!
          expect(order).to be_successful
        end
      end

      context 'when order is created' do
        it 'raises AASM::InvalidTransition' do
          order.save!
          expect { order.mark_successful! }.to raise_error(AASM::InvalidTransition)
        end
      end

      context 'when order is successful' do
        subject(:order) { create(:order, :successful) }

        it 'raises AASM::InvalidTransition' do
          expect { order.mark_successful! }.to raise_error(AASM::InvalidTransition)
        end
      end
    end

    describe '#cancel' do
      context 'when order is successful' do
        subject(:order) { create(:order, :successful) }

        it 'transitions to cancelled' do
          order.cancel!
          expect(order).to be_cancelled
        end
      end

      context 'when order is created' do
        it 'raises AASM::InvalidTransition' do
          order.save!
          expect { order.cancel! }.to raise_error(AASM::InvalidTransition)
        end
      end

      context 'when order is payment_pending' do
        subject(:order) { create(:order, :payment_pending) }

        it 'raises AASM::InvalidTransition' do
          expect { order.cancel! }.to raise_error(AASM::InvalidTransition)
        end
      end

      context 'when order is already cancelled' do
        subject(:order) { create(:order, :cancelled) }

        it 'raises AASM::InvalidTransition' do
          expect { order.cancel! }.to raise_error(AASM::InvalidTransition)
        end
      end
    end
  end

  describe 'AASM guard queries' do
    it 'may_start_payment? is true for created' do
      expect(order.may_start_payment?).to be true
    end

    it 'may_cancel? is false for created' do
      expect(order.may_cancel?).to be false
    end

    it 'may_cancel? is true for successful' do
      successful_order = build(:order, :successful)
      expect(successful_order.may_cancel?).to be true
    end
  end
end
