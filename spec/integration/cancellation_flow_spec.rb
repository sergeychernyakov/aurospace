# frozen_string_literal: true

# spec/integration/cancellation_flow_spec.rb

require 'rails_helper'

RSpec.describe 'Cancellation flow integration' do
  let(:user) { create(:user, :with_account) }
  let(:account) { user.account }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('YOOKASSA_SHOP_ID').and_return('test_shop_id')
    allow(ENV).to receive(:fetch).with('YOOKASSA_SECRET_KEY').and_return('test_secret')
    allow(ENV).to receive(:fetch).with('YOOKASSA_RETURN_URL', anything).and_return('http://localhost:3000/orders/1')
  end

  it 'cancels a successful order and reverses the balance' do
    # Setup: create a successful order with balance
    stub_request(:post, 'https://api.yookassa.ru/v3/payments')
      .to_return(
        status: 200,
        body: {
          'id' => 'pay_cancel_flow',
          'status' => 'pending',
          'confirmation' => { 'type' => 'redirect', 'confirmation_url' => 'https://yookassa.ru/confirm' },
        }.to_json,
        headers: { 'Content-Type' => 'application/json' },
      )

    post '/orders', params: { user_id: user.id, amount_cents: 7000 }
    order = Order.find(response.parsed_body['id'])

    post "/orders/#{order.id}/pay"
    post '/webhooks/yookassa',
         params: { event: 'payment.succeeded', object: { id: 'pay_cancel_flow', status: 'succeeded' } },
         as: :json
    perform_enqueued_jobs(only: ProcessWebhookJob)

    expect(order.reload).to be_successful
    expect(account.reload.balance_cents).to eq(7000)

    # Step: Cancel the order
    post "/orders/#{order.id}/cancel"

    expect(response).to have_http_status(:ok)
    expect(order.reload).to be_cancelled
    expect(order.cancelled_at).to be_present

    # Verify reversal entry
    reversal = LedgerEntry.where(entry_type: :reversal).last
    expect(reversal).to be_present
    expect(reversal.amount_cents).to eq(7000)

    # Verify balance restored
    expect(account.reload.balance_cents).to eq(14_000)
  end

  it 'rejects cancellation of non-successful order' do
    post '/orders', params: { user_id: user.id, amount_cents: 5000 }
    order = Order.find(response.parsed_body['id'])

    post "/orders/#{order.id}/cancel"

    expect(response).to have_http_status(:unprocessable_entity)
    expect(order.reload).to be_created
  end

  it 'rejects double cancellation' do
    # Create successful order
    order = create(:order, :successful, user: user, amount_cents: 5000, currency: 'RUB')

    post "/orders/#{order.id}/cancel"
    expect(response).to have_http_status(:ok)

    post "/orders/#{order.id}/cancel"
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
