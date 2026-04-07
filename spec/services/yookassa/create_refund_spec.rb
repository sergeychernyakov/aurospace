# frozen_string_literal: true

# spec/services/yookassa/create_refund_spec.rb

require 'rails_helper'

RSpec.describe Yookassa::CreateRefund do
  subject(:service) { described_class.new }

  let(:user) { create(:user, :with_account) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('YOOKASSA_SHOP_ID').and_return('test_shop_id')
    allow(ENV).to receive(:fetch).with('YOOKASSA_SECRET_KEY').and_return('test_secret')
  end

  describe '#call' do
    context 'when refund succeeds' do
      let(:order) do
        create(:order, :successful, user: user, amount_cents: 5000,
                                    currency: 'RUB', external_payment_id: 'pay_123',)
      end

      before do
        stub_request(:post, 'https://api.yookassa.ru/v3/refunds')
          .to_return(
            status: 200,
            body: {
              'id' => 'ref_abc',
              'status' => 'succeeded',
              'payment_id' => 'pay_123',
              'amount' => { 'value' => '50.00', 'currency' => 'RUB' },
            }.to_json,
            headers: { 'Content-Type' => 'application/json' },
          )
      end

      it 'returns Success with refund data' do
        result = service.call(order: order)
        expect(result).to be_success
        expect(result.value!['id']).to eq('ref_abc')
      end

      it 'sends correct amount to YooKassa' do
        service.call(order: order)
        expect(WebMock).to(have_requested(:post, 'https://api.yookassa.ru/v3/refunds')
          .with { |req| JSON.parse(req.body)['amount']['value'] == '50.0' })
      end
    end

    context 'when order has no external_payment_id' do
      let(:order) do
        create(:order, :successful, user: user, amount_cents: 5000,
                                    currency: 'RUB', external_payment_id: nil,)
      end

      it 'returns Failure(:no_payment_id)' do
        result = service.call(order: order)
        expect(result).to be_failure
        expect(result.failure).to eq(:no_payment_id)
      end
    end

    context 'when provider returns error' do
      let(:order) do
        create(:order, :successful, user: user, amount_cents: 5000,
                                    currency: 'RUB', external_payment_id: 'pay_456',)
      end

      before do
        stub_request(:post, 'https://api.yookassa.ru/v3/refunds')
          .to_return(
            status: 500,
            body: { 'type' => 'error', 'description' => 'Internal error' }.to_json,
            headers: { 'Content-Type' => 'application/json' },
          )
      end

      it 'returns Failure(:refund_failed)' do
        result = service.call(order: order)
        expect(result).to be_failure
        expect(result.failure).to eq(:refund_failed)
      end
    end

    context 'when idempotence key is set correctly' do
      let(:order) do
        create(:order, :successful, user: user, amount_cents: 3000,
                                    currency: 'RUB', external_payment_id: 'pay_789',)
      end

      before do
        stub_request(:post, 'https://api.yookassa.ru/v3/refunds')
          .to_return(
            status: 200,
            body: { 'id' => 'ref_xyz', 'status' => 'succeeded' }.to_json,
            headers: { 'Content-Type' => 'application/json' },
          )
      end

      it 'sends idempotence key with order id' do
        service.call(order: order)
        expect(WebMock).to have_requested(:post, 'https://api.yookassa.ru/v3/refunds')
          .with(headers: { 'Idempotence-Key' => "refund_order_#{order.id}" })
      end
    end

    context 'when order has blank external_payment_id' do
      let(:order) do
        create(:order, :successful, user: user, amount_cents: 5000,
                                    currency: 'RUB', external_payment_id: '',)
      end

      it 'returns Failure(:no_payment_id)' do
        result = service.call(order: order)
        expect(result).to be_failure
        expect(result.failure).to eq(:no_payment_id)
      end
    end
  end
end
