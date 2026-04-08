# frozen_string_literal: true

# spec/integration/payment_flow_spec.rb

require 'rails_helper'

RSpec.describe 'Payment flow integration' do
  let(:user) { create(:user, :with_account) }
  let(:account) { user.account }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('YOOKASSA_SHOP_ID').and_return('test_shop_id')
    allow(ENV).to receive(:fetch).with('YOOKASSA_SECRET_KEY').and_return('test_secret')
    allow(ENV).to receive(:fetch).with('YOOKASSA_RETURN_URL', anything).and_return('http://localhost:3000/orders/1')
  end

  it 'completes full payment flow: create -> pay -> webhook -> success' do
    # Step 1: Create order
    post '/orders', params: { user_id: user.id, amount_cents: 10_000, currency: 'RUB' }
    expect(response).to have_http_status(:created)
    order_id = response.parsed_body['id']
    order = Order.find(order_id)
    expect(order).to be_created

    # Step 2: Initiate payment
    stub_request(:post, 'https://api.yookassa.ru/v3/payments')
      .to_return(
        status: 200,
        body: {
          'id' => 'pay_flow_123',
          'status' => 'pending',
          'confirmation' => {
            'type' => 'redirect',
            'confirmation_url' => 'https://yookassa.ru/confirm/pay_flow_123',
          },
        }.to_json,
        headers: { 'Content-Type' => 'application/json' },
      )

    post "/orders/#{order_id}/pay"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['confirmation_url']).to be_present
    expect(order.reload).to be_payment_pending
    expect(order.external_payment_id).to eq('pay_flow_123')

    # Step 3: Receive webhook
    webhook_params = {
      event: 'payment.succeeded',
      object: { id: 'pay_flow_123', status: 'succeeded' },
    }
    post '/webhooks/yookassa', params: webhook_params, as: :json
    expect(response).to have_http_status(:ok)

    # Step 4: Process webhook job
    perform_enqueued_jobs(only: ProcessWebhookJob)

    # Step 5: Verify final state
    order.reload
    expect(order).to be_successful
    expect(order.paid_at).to be_present

    # Verify ledger entry
    expect(order.ledger_entries.count).to eq(1)
    entry = LedgerEntry.last
    expect(entry.credit?).to be true
    expect(entry.amount_cents).to eq(10_000)
    expect(entry.account).to eq(account)

    # Verify balance
    expect(account.reload.balance_cents).to eq(10_000)

    # Verify email job was enqueued
    expect(WebhookEvent.where(external_event_id: 'pay_flow_123').count).to eq(1)
    expect(WebhookEvent.last.status).to eq('processed')
  end

  it 'correctly tracks balance across multiple orders' do
    stub_request(:post, 'https://api.yookassa.ru/v3/payments')
      .to_return(
        status: 200,
        body: lambda { |request|
          JSON.parse(request.body)
          {
            'id' => "pay_#{SecureRandom.hex(4)}",
            'status' => 'pending',
            'confirmation' => {
              'type' => 'redirect',
              'confirmation_url' => "https://yookassa.ru/confirm/#{SecureRandom.hex(4)}",
            },
          }.to_json
        },
        headers: { 'Content-Type' => 'application/json' },
      )

    # Create and pay for first order
    post '/orders', params: { user_id: user.id, amount_cents: 5000 }
    order1 = Order.find(response.parsed_body['id'])
    post "/orders/#{order1.id}/pay"
    payment_id1 = order1.reload.external_payment_id

    # Create and pay for second order
    post '/orders', params: { user_id: user.id, amount_cents: 3000 }
    order2 = Order.find(response.parsed_body['id'])
    post "/orders/#{order2.id}/pay"
    payment_id2 = order2.reload.external_payment_id

    # Process webhooks for both
    post '/webhooks/yookassa',
         params: { event: 'payment.succeeded', object: { id: payment_id1, status: 'succeeded' } }, as: :json
    post '/webhooks/yookassa',
         params: { event: 'payment.succeeded', object: { id: payment_id2, status: 'succeeded' } }, as: :json

    perform_enqueued_jobs(only: ProcessWebhookJob)

    expect(account.reload.balance_cents).to eq(8000)
    expect(LedgerEntry.where(account: account).count).to eq(2)
  end
end
