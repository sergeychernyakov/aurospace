# frozen_string_literal: true

# spec/requests/orders_spec.rb

require 'rails_helper'

RSpec.describe 'Orders' do
  let(:user) { create(:user, :with_account) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('YOOKASSA_SHOP_ID').and_return('test_shop_id')
    allow(ENV).to receive(:fetch).with('YOOKASSA_SECRET_KEY').and_return('test_secret')
    allow(ENV).to receive(:fetch).with('YOOKASSA_RETURN_URL', anything).and_return('http://localhost:3000/orders/1')
  end

  describe 'GET /orders' do
    it 'returns orders for a given user' do
      create_list(:order, 3, user: user)
      get '/orders', params: { user_id: user.id }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(3)
    end

    it 'returns empty array when no orders exist' do
      get '/orders', params: { user_id: user.id }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end
  end

  describe 'GET /orders/:id' do
    let(:order) { create(:order, user: user) }

    it 'returns the order' do
      get "/orders/#{order.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq(order.id)
    end

    it 'returns 404 for non-existent order' do
      get '/orders/999999'

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /orders' do
    context 'with valid parameters' do
      it 'creates an order' do
        expect {
          post '/orders', params: { user_id: user.id, amount_cents: 5000, currency: 'RUB' }
        }.to change(Order, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'returns the created order' do
        post '/orders', params: { user_id: user.id, amount_cents: 5000 }

        expect(response.parsed_body['amount_cents']).to eq(5000)
      end
    end

    context 'with invalid parameters' do
      it 'returns error for zero amount' do
        post '/orders', params: { user_id: user.id, amount_cents: 0 }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']['code']).to eq('invalid_amount')
      end

      it 'returns 404 for non-existent user' do
        post '/orders', params: { user_id: 999_999, amount_cents: 5000 }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /orders/:id/pay' do
    let(:order) { create(:order, user: user) }

    context 'when YooKassa succeeds' do
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

      it 'returns success with confirmation_url' do
        post "/orders/#{order.id}/pay"

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['confirmation_url']).to eq('https://yookassa.ru/confirm/pay_abc')
      end

      it 'transitions order to payment_pending' do
        post "/orders/#{order.id}/pay"

        expect(order.reload).to be_payment_pending
      end
    end

    context 'when YooKassa fails' do
      before do
        stub_request(:post, 'https://api.yookassa.ru/v3/payments')
          .to_return(status: 500, body: { 'type' => 'error' }.to_json,
                     headers: { 'Content-Type' => 'application/json' },)
      end

      it 'returns error' do
        post "/orders/#{order.id}/pay"

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']['code']).to eq('provider_error')
      end
    end

    it 'returns 404 for non-existent order' do
      post '/orders/999999/pay'

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /orders/:id/cancel' do
    let(:order) { create(:order, :successful, user: user, amount_cents: 3000) }

    it 'cancels a successful order' do
      post "/orders/#{order.id}/cancel"

      expect(response).to have_http_status(:ok)
      expect(order.reload).to be_cancelled
    end

    context 'when order cannot be cancelled' do
      let(:created_order) { create(:order, user: user) }

      it 'returns error' do
        post "/orders/#{created_order.id}/cancel"

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it 'returns 404 for non-existent order' do
      post '/orders/999999/cancel'

      expect(response).to have_http_status(:not_found)
    end
  end
end
