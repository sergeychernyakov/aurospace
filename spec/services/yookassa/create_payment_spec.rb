# frozen_string_literal: true

# spec/services/yookassa/create_payment_spec.rb

require 'rails_helper'

RSpec.describe Yookassa::CreatePayment do
  subject(:service) { described_class.new }

  let(:user) { create(:user, :with_account) }
  let(:order) { create(:order, user: user, amount_cents: 5000, currency: 'RUB') }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('YOOKASSA_SHOP_ID').and_return('test_shop_id')
    allow(ENV).to receive(:fetch).with('YOOKASSA_SECRET_KEY').and_return('test_secret')
    allow(ENV).to receive(:fetch).with('YOOKASSA_RETURN_URL', anything).and_return('http://localhost:3000/orders/1')
  end

  describe '#call' do
    context 'when payment creation succeeds' do
      before do
        stub_request(:post, 'https://api.yookassa.ru/v3/payments')
          .to_return(
            status: 200,
            body: {
              'id' => 'pay_abc',
              'status' => 'pending',
              'confirmation' => {
                'type' => 'redirect',
                'confirmation_url' => 'https://yookassa.ru/confirm/pay_abc',
              },
            }.to_json,
            headers: { 'Content-Type' => 'application/json' },
          )
      end

      it 'returns Success with payment_id and confirmation_url' do
        result = service.call(order: order)
        expect(result).to be_success
        expect(result.value![:payment_id]).to eq('pay_abc')
        expect(result.value![:confirmation_url]).to eq('https://yookassa.ru/confirm/pay_abc')
      end
    end

    context 'when order already has external_payment_id' do
      let(:order) do
        create(:order, :payment_pending, user: user, amount_cents: 5000,
                                         external_payment_id: 'existing_pay',)
      end

      it 'returns Failure(:already_paid)' do
        result = service.call(order: order)
        expect(result).to be_failure
        expect(result.failure).to eq(:already_paid)
      end
    end

    context 'when provider returns error' do
      before do
        stub_request(:post, 'https://api.yookassa.ru/v3/payments')
          .to_return(status: 500, body: { 'type' => 'error' }.to_json,
                     headers: { 'Content-Type' => 'application/json' },)
      end

      it 'returns Failure(:provider_error)' do
        result = service.call(order: order)
        expect(result).to be_failure
        expect(result.failure).to eq(:provider_error)
      end
    end
  end
end
