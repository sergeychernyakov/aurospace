# frozen_string_literal: true

# spec/services/orders/start_payment_spec.rb

require 'rails_helper'

RSpec.describe Orders::StartPayment do
  subject(:service) { described_class.new }

  let(:user) { create(:user, :with_account) }
  let(:payment_id) { 'yookassa_pay_123' }
  let(:confirmation_url) { 'https://yookassa.ru/confirm/123' }

  describe '#call' do
    context 'when order is in created state' do
      let(:order) { create(:order, user: user) }

      it 'returns Success' do
        result = service.call(order: order, payment_id: payment_id, confirmation_url: confirmation_url)
        expect(result).to be_success
      end

      it 'transitions order to payment_pending' do
        service.call(order: order, payment_id: payment_id, confirmation_url: confirmation_url)
        expect(order.reload).to be_payment_pending
      end

      it 'sets payment_provider to yookassa' do
        service.call(order: order, payment_id: payment_id, confirmation_url: confirmation_url)
        expect(order.reload.payment_provider).to eq('yookassa')
      end

      it 'sets external_payment_id' do
        service.call(order: order, payment_id: payment_id, confirmation_url: confirmation_url)
        expect(order.reload.external_payment_id).to eq(payment_id)
      end

      it 'returns confirmation_url in success value' do
        result = service.call(order: order, payment_id: payment_id, confirmation_url: confirmation_url)
        expect(result.value![:confirmation_url]).to eq(confirmation_url)
      end

      it 'returns order in success value' do
        result = service.call(order: order, payment_id: payment_id, confirmation_url: confirmation_url)
        expect(result.value![:order]).to eq(order)
      end
    end

    context 'when order is payment_pending' do
      let(:order) { create(:order, :payment_pending, user: user) }

      it 'returns Failure(:invalid_transition)' do
        result = service.call(order: order, payment_id: payment_id, confirmation_url: confirmation_url)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_transition)
      end

      it 'does not change order status' do
        service.call(order: order, payment_id: payment_id, confirmation_url: confirmation_url)
        expect(order.reload).to be_payment_pending
      end
    end

    context 'when order is successful' do
      let(:order) { create(:order, :successful, user: user) }

      it 'returns Failure(:invalid_transition)' do
        result = service.call(order: order, payment_id: payment_id, confirmation_url: confirmation_url)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_transition)
      end
    end

    context 'when order is cancelled' do
      let(:order) { create(:order, :cancelled, user: user) }

      it 'returns Failure(:invalid_transition)' do
        result = service.call(order: order, payment_id: payment_id, confirmation_url: confirmation_url)
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_transition)
      end
    end

    context 'when AASM transition raises unexpectedly' do
      let(:order) { create(:order, :successful, user: user) }

      it 'returns Failure(:invalid_transition)' do
        allow(order).to receive(:may_start_payment?).and_return(true)
        result = service.call(order: order, payment_id: 'pay_1', confirmation_url: 'http://example.com')
        expect(result.failure).to eq(:invalid_transition)
      end
    end
  end
end
