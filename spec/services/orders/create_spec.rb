# frozen_string_literal: true

# spec/services/orders/create_spec.rb

require 'rails_helper'

RSpec.describe Orders::Create do
  subject(:service) { described_class.new }

  let(:user) { create(:user, :with_account) }

  describe '#call' do
    context 'with valid parameters' do
      it 'returns Success with the created order' do
        result = service.call(user: user, amount_cents: 5000)
        expect(result).to be_success
        expect(result.value!).to be_a(Order)
      end

      it 'creates an order with correct attributes' do
        result = service.call(user: user, amount_cents: 5000, currency: 'RUB')
        order = result.value!

        expect(order.user).to eq(user)
        expect(order.amount_cents).to eq(5000)
        expect(order.currency).to eq('RUB')
        expect(order).to be_created
      end

      it 'persists the order' do
        expect {
          service.call(user: user, amount_cents: 5000)
        }.to change(Order, :count).by(1)
      end

      it 'defaults currency to RUB' do
        result = service.call(user: user, amount_cents: 1000)
        expect(result.value!.currency).to eq('RUB')
      end

      it 'accepts custom currency' do
        result = service.call(user: user, amount_cents: 1000, currency: 'USD')
        expect(result.value!.currency).to eq('USD')
      end
    end

    context 'with invalid amount' do
      it 'returns Failure(:invalid_amount) for zero' do
        result = service.call(user: user, amount_cents: 0)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_amount)
      end

      it 'returns Failure(:invalid_amount) for negative' do
        result = service.call(user: user, amount_cents: -100)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_amount)
      end

      it 'returns Failure(:invalid_amount) for nil' do
        result = service.call(user: user, amount_cents: nil)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_amount)
      end

      it 'returns Failure(:invalid_amount) for non-integer' do
        result = service.call(user: user, amount_cents: 10.5)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_amount)
      end

      it 'does not create an order' do
        expect {
          service.call(user: user, amount_cents: 0)
        }.not_to change(Order, :count)
      end
    end

    context 'when user has no account' do
      let(:user_without_account) { create(:user) }

      it 'returns Failure(:account_missing)' do
        result = service.call(user: user_without_account, amount_cents: 5000)
        expect(result).to be_failure
        expect(result.failure).to eq(:account_missing)
      end

      it 'does not create an order' do
        expect {
          service.call(user: user_without_account, amount_cents: 5000)
        }.not_to change(Order, :count)
      end
    end
  end
end
