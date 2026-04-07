# frozen_string_literal: true

# spec/clients/yookassa_client_spec.rb

require 'rails_helper'

RSpec.describe YookassaClient do
  subject(:client) { described_class.new }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('YOOKASSA_SHOP_ID').and_return('test_shop_id')
    allow(ENV).to receive(:fetch).with('YOOKASSA_SECRET_KEY').and_return('test_secret')
  end

  describe '#create_payment' do
    let(:success_body) do
      {
        'id' => 'pay_123',
        'status' => 'pending',
        'confirmation' => {
          'type' => 'redirect',
          'confirmation_url' => 'https://yookassa.ru/confirm/pay_123',
        },
      }
    end

    context 'when API returns success' do
      before do
        stub_request(:post, 'https://api.yookassa.ru/v3/payments')
          .to_return(status: 200, body: success_body.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns parsed response body' do
        result = client.create_payment(
          amount_cents: 5000, currency: 'RUB',
          description: 'Order #1', return_url: 'http://localhost:3000/orders/1',
          idempotence_key: 'order_1',
        )
        expect(result['id']).to eq('pay_123')
        expect(result.dig('confirmation', 'confirmation_url')).to eq('https://yookassa.ru/confirm/pay_123')
      end

      it 'sends correct Idempotence-Key header' do
        client.create_payment(
          amount_cents: 5000, currency: 'RUB',
          description: 'Order #1', return_url: 'http://localhost:3000/orders/1',
          idempotence_key: 'order_1',
        )
        expect(WebMock).to have_requested(:post, 'https://api.yookassa.ru/v3/payments')
          .with(headers: { 'Idempotence-Key' => 'order_1' })
      end

      it 'sends basic auth credentials' do
        client.create_payment(
          amount_cents: 5000, currency: 'RUB',
          description: 'Order #1', return_url: 'http://localhost:3000/orders/1',
          idempotence_key: 'order_1',
        )
        expect(WebMock).to have_requested(:post, 'https://api.yookassa.ru/v3/payments')
          .with(basic_auth: ['test_shop_id', 'test_secret'])
      end
    end

    context 'when API returns error' do
      before do
        stub_request(:post, 'https://api.yookassa.ru/v3/payments')
          .to_return(status: 400, body: { 'type' => 'error' }.to_json,
                     headers: { 'Content-Type' => 'application/json' },)
      end

      it 'raises Payments::ProviderError' do
        expect {
          client.create_payment(
            amount_cents: 5000, currency: 'RUB',
            description: 'Order #1', return_url: 'http://localhost:3000/orders/1',
            idempotence_key: 'order_1',
          )
        }.to raise_error(Payments::ProviderError, /YooKassa API error: 400/)
      end
    end
  end

  describe '#get_payment' do
    context 'when API returns success' do
      before do
        stub_request(:get, 'https://api.yookassa.ru/v3/payments/pay_123')
          .to_return(status: 200, body: { 'id' => 'pay_123', 'status' => 'succeeded' }.to_json,
                     headers: { 'Content-Type' => 'application/json' },)
      end

      it 'returns parsed response body' do
        result = client.get_payment(payment_id: 'pay_123')
        expect(result['id']).to eq('pay_123')
        expect(result['status']).to eq('succeeded')
      end
    end

    context 'when API returns error' do
      before do
        stub_request(:get, 'https://api.yookassa.ru/v3/payments/not_found')
          .to_return(status: 404, body: { 'type' => 'error' }.to_json,
                     headers: { 'Content-Type' => 'application/json' },)
      end

      it 'raises Payments::ProviderError' do
        expect {
          client.get_payment(payment_id: 'not_found')
        }.to raise_error(Payments::ProviderError)
      end
    end
  end
end
