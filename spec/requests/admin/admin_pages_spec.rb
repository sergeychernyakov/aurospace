# frozen_string_literal: true

# spec/requests/admin/admin_pages_spec.rb

require 'rails_helper'

RSpec.describe 'Admin Pages' do
  let(:admin_credentials) { ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'password') }
  let(:user) { create(:user, :with_account) }

  before do
    stub_const('ENV', ENV.to_h.merge('ADMIN_USER' => 'admin', 'ADMIN_PASSWORD' => 'password'))
  end

  describe 'authentication' do
    it 'requires basic auth' do
      get '/a'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows access with valid credentials' do
      get '/a', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /admin (dashboard)' do
    it 'renders the dashboard' do
      get '/a', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('AUROSPACE Dashboard')
    end
  end

  describe 'GET /admin/orders' do
    before { create(:order, user: user) }

    it 'renders the orders index' do
      get '/a/orders', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Orders')
    end
  end

  describe 'GET /admin/orders/:id' do
    let!(:order) { create(:order, user: user) }

    it 'renders the order show page' do
      get "/admin/orders/#{order.id}", headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(order.id.to_s)
    end
  end

  describe 'GET /admin/accounts' do
    before { user }

    it 'renders the accounts index' do
      get '/a/accounts', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Accounts')
    end
  end

  describe 'GET /admin/ledger_entries' do
    it 'renders the ledger entries index' do
      get '/a/ledger_entries', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Ledger Entries')
    end
  end

  describe 'GET /admin/webhook_events' do
    it 'renders the webhook events index' do
      get '/a/webhook_events', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Webhook Events')
    end
  end

  describe 'GET /admin/notification_logs' do
    it 'renders the notification logs index' do
      get '/a/notification_logs', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Notification Logs')
    end
  end

  describe 'POST /admin/orders/:id/cancel_order' do
    let!(:order) { create(:order, :successful, user: user) }

    before do
      # Create a credit ledger entry so the balance supports reversal
      Accounts::ApplyLedgerEntry.new.call(
        account: user.account,
        order: order,
        entry_type: :credit,
        amount_cents: order.amount_cents,
        reference: "test_credit_#{order.id}",
      )
    end

    it 'cancels a successful order via service' do
      post "/admin/orders/#{order.id}/cancel_order",
           headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to redirect_to(admin_order_path(order))
      expect(order.reload.status).to eq('cancelled')
    end

    it 'redirects with alert when order cannot be cancelled' do
      order = create(:order, user: user)
      post "/admin/orders/#{order.id}/cancel_order",
           headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to redirect_to(admin_order_path(order))
      expect(flash[:alert]).to include('Cannot cancel')
    end
  end

  describe 'discard integration' do
    it 'shows discarded orders in admin' do
      order = create(:order, user: user)
      order.discard
      get '/a/orders', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(order.id.to_s)
    end

    it 'shows discarded webhook events in admin' do
      event = create(:webhook_event)
      event.discard
      get '/a/webhook_events', headers: { 'HTTP_AUTHORIZATION' => admin_credentials }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(event.external_event_id)
    end
  end
end
