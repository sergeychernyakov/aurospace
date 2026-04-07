# frozen_string_literal: true

# spec/integration/full_scenario_spec.rb

require 'rails_helper'

RSpec.describe 'Full scenario integration' do
  include ActiveJob::TestHelper

  let!(:user) { create(:user, :with_account) }
  let(:account) { user.account }
  let(:admin_credentials) { ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'password') }

  before do
    stub_const('ENV', ENV.to_h.merge(
                        'ADMIN_USER' => 'admin',
                        'ADMIN_PASSWORD' => 'password',
                        'YOOKASSA_SHOP_ID' => 'test_shop_id',
                        'YOOKASSA_SECRET_KEY' => 'test_secret',
                      ),)
  end

  describe 'order lifecycle' do
    let(:payment_id) { "pay_#{SecureRandom.hex(8)}" }

    before do
      stub_request(:post, 'https://api.yookassa.ru/v3/payments')
        .to_return(
          status: 200,
          body: {
            'id' => payment_id,
            'status' => 'pending',
            'confirmation' => {
              'type' => 'redirect',
              'confirmation_url' => "https://yookassa.ru/confirm/#{payment_id}",
            },
          }.to_json,
          headers: { 'Content-Type' => 'application/json' },
        )
    end

    it 'step 1: creates an order' do
      post '/orders', params: { user_id: user.id, amount_cents: 5000, currency: 'RUB' }

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body['status']).to eq('created')
      expect(body['amount_cents']).to eq(5000)
      expect(account.reload.balance_cents).to eq(0)
    end

    it 'step 2: pays an order' do
      post '/orders', params: { user_id: user.id, amount_cents: 5000 }
      order_id = response.parsed_body['id']

      post "/orders/#{order_id}/pay"

      expect(response).to have_http_status(:ok)
      order = Order.find(order_id)
      expect(order).to be_payment_pending
      expect(order.external_payment_id).to eq(payment_id)
      expect(account.reload.balance_cents).to eq(0)
    end

    it 'step 3: processes webhook and marks order successful' do
      post '/orders', params: { user_id: user.id, amount_cents: 5000 }
      order_id = response.parsed_body['id']
      post "/orders/#{order_id}/pay"

      post '/webhooks/yookassa',
           params: { event: 'payment.succeeded', object: { id: payment_id } },
           as: :json
      expect(response).to have_http_status(:ok)

      perform_enqueued_jobs(only: ProcessWebhookJob)

      order = Order.find(order_id)
      expect(order).to be_successful
      expect(order.paid_at).to be_present
      expect(account.reload.balance_cents).to eq(5000)

      credit_entry = LedgerEntry.find_by(order_id: order_id, entry_type: :credit)
      expect(credit_entry).to be_present
      expect(credit_entry.amount_cents).to eq(5000)

      webhook = WebhookEvent.find_by(external_event_id: payment_id)
      expect(webhook.status).to eq('processed')
    end

    it 'step 4: cancels a successful order and creates reversal' do
      post '/orders', params: { user_id: user.id, amount_cents: 5000 }
      order_id = response.parsed_body['id']
      post "/orders/#{order_id}/pay"
      post '/webhooks/yookassa',
           params: { event: 'payment.succeeded', object: { id: payment_id } },
           as: :json
      perform_enqueued_jobs(only: ProcessWebhookJob)

      balance_before_cancel = account.reload.balance_cents

      post "/orders/#{order_id}/cancel"

      expect(response).to have_http_status(:ok)
      order = Order.find(order_id)
      expect(order).to be_cancelled
      expect(order.cancelled_at).to be_present

      reversal_entry = LedgerEntry.find_by(order_id: order_id, entry_type: :reversal)
      expect(reversal_entry).to be_present
      expect(reversal_entry.amount_cents).to eq(5000)
      expect(account.reload.balance_cents).to eq(balance_before_cancel + 5000)
    end

    it 'step 5: handles duplicate webhook idempotently' do
      post '/orders', params: { user_id: user.id, amount_cents: 5000 }
      order_id = response.parsed_body['id']
      post "/orders/#{order_id}/pay"

      webhook_params = { event: 'payment.succeeded', object: { id: payment_id } }

      post '/webhooks/yookassa', params: webhook_params, as: :json
      perform_enqueued_jobs(only: ProcessWebhookJob)

      balance_after_first = account.reload.balance_cents
      ledger_count = LedgerEntry.count
      webhook_count = WebhookEvent.count

      post '/webhooks/yookassa', params: webhook_params, as: :json
      expect(response).to have_http_status(:ok)
      perform_enqueued_jobs(only: ProcessWebhookJob)

      expect(LedgerEntry.count).to eq(ledger_count)
      expect(account.reload.balance_cents).to eq(balance_after_first)
      expect(WebhookEvent.count).to eq(webhook_count)
    end

    it 'step 6: rejects double cancellation' do
      post '/orders', params: { user_id: user.id, amount_cents: 5000 }
      order_id = response.parsed_body['id']
      post "/orders/#{order_id}/pay"
      post '/webhooks/yookassa',
           params: { event: 'payment.succeeded', object: { id: payment_id } },
           as: :json
      perform_enqueued_jobs(only: ProcessWebhookJob)

      post "/orders/#{order_id}/cancel"
      expect(response).to have_http_status(:ok)

      balance_after_cancel = account.reload.balance_cents

      post "/orders/#{order_id}/cancel"
      expect(response).to have_http_status(:unprocessable_entity)
      expect(account.reload.balance_cents).to eq(balance_after_cancel)
    end

    it 'step 7: completes second order and accumulates balance' do
      second_payment_id = "pay_second_#{SecureRandom.hex(8)}"
      stub_request(:post, 'https://api.yookassa.ru/v3/payments')
        .to_return(
          status: 200,
          body: lambda { |_request|
            {
              'id' => second_payment_id,
              'status' => 'pending',
              'confirmation' => {
                'type' => 'redirect',
                'confirmation_url' => "https://yookassa.ru/confirm/#{second_payment_id}",
              },
            }.to_json
          },
          headers: { 'Content-Type' => 'application/json' },
        )

      post '/orders', params: { user_id: user.id, amount_cents: 3000 }
      expect(response).to have_http_status(:created)
      order_id = response.parsed_body['id']

      post "/orders/#{order_id}/pay"
      expect(response).to have_http_status(:ok)

      post '/webhooks/yookassa',
           params: { event: 'payment.succeeded', object: { id: second_payment_id } },
           as: :json
      perform_enqueued_jobs(only: ProcessWebhookJob)

      expect(Order.find(order_id)).to be_successful
      expect(account.reload.balance_cents).to eq(3000)
    end
  end

  describe 'edge cases' do
    it 'step 8: rejects order with zero amount' do
      post '/orders', params: { user_id: user.id, amount_cents: 0 }

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.parsed_body
      expect(body['error']['code']).to be_present
    end

    it 'step 9: rejects cancelling an unpaid order' do
      post '/orders', params: { user_id: user.id, amount_cents: 5000 }
      order_id = response.parsed_body['id']

      post "/orders/#{order_id}/cancel"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Order.find(order_id)).to be_created
    end

    it 'step 10: handles webhook with unknown payment_id' do
      balance_before = account.reload.balance_cents

      post '/webhooks/yookassa',
           params: { event: 'payment.succeeded', object: { id: 'nonexistent_999' } },
           as: :json
      expect(response).to have_http_status(:ok)
      perform_enqueued_jobs(only: ProcessWebhookJob)

      expect(account.reload.balance_cents).to eq(balance_before)
    end

    it 'step 11: rejects malformed webhook payload' do
      post '/webhooks/yookassa',
           headers: { 'CONTENT_TYPE' => 'application/json' },
           env: { 'RAW_POST_DATA' => 'not-valid-json{{{' }
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'admin pages' do
    let!(:order) { create(:order, user: user) }

    it 'step 12a: renders the dashboard' do
      get '/a', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Dashboard')
    end

    it 'step 12b: renders orders index' do
      get '/a/orders', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
    end

    it 'step 12c: renders accounts index' do
      get '/a/accounts', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
    end

    it 'step 12d: renders ledger entries index' do
      get '/a/ledger_entries', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
    end

    it 'step 12e: renders webhook events index' do
      get '/a/webhook_events', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
    end

    it 'step 12f: renders notification logs index' do
      get '/a/notification_logs', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
    end

    it 'step 13: cancels order via admin' do
      successful_order = create(:order, :successful, user: user)
      Accounts::ApplyLedgerEntry.new.call(
        account: account,
        order: successful_order,
        entry_type: :credit,
        amount_cents: successful_order.amount_cents,
        reference: "test_credit_#{successful_order.id}",
      )

      post "/a/orders/#{successful_order.id}/cancel_order",
           headers: { 'HTTP_AUTHORIZATION' => admin_credentials }

      expect(response).to have_http_status(:redirect)
      expect(successful_order.reload).to be_cancelled
    end
  end
end
