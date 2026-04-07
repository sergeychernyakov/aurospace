# frozen_string_literal: true

# spec/integration/idempotency_spec.rb

require 'rails_helper'

RSpec.describe 'Idempotency integration' do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, balance_cents: 0, currency: 'RUB') }

  before { account }

  describe 'duplicate webhook processing' do
    let(:order) do
      create(:order, :payment_pending, user: user, amount_cents: 5000,
                                       currency: 'RUB', external_payment_id: 'pay_idem_123',)
    end
    let(:webhook_params) do
      { event: 'payment.succeeded', object: { id: 'pay_idem_123', status: 'succeeded' } }
    end

    before { order }

    it 'processes first webhook and skips duplicate' do
      # First webhook
      post '/webhooks/yookassa', params: webhook_params, as: :json
      expect(response).to have_http_status(:ok)
      perform_enqueued_jobs(only: ProcessWebhookJob)

      expect(order.reload).to be_successful
      expect(account.reload.balance_cents).to eq(5000)
      expect(LedgerEntry.count).to eq(1)

      # Duplicate webhook
      post '/webhooks/yookassa', params: webhook_params, as: :json
      expect(response).to have_http_status(:ok)
      perform_enqueued_jobs(only: ProcessWebhookJob)

      # Verify no duplicate processing
      expect(LedgerEntry.count).to eq(1)
      expect(account.reload.balance_cents).to eq(5000)
      expect(WebhookEvent.count).to eq(1)
    end
  end

  describe 'MarkSuccessful idempotency' do
    let(:order) do
      create(:order, :payment_pending, user: user, amount_cents: 3000,
                                       currency: 'RUB', external_payment_id: 'pay_idem_ms',)
    end

    it 'calling MarkSuccessful twice produces same result' do
      service = Orders::MarkSuccessful.new

      result1 = service.call(order: order)
      expect(result1).to be_success

      result2 = service.call(order: order.reload)
      expect(result2).to be_success

      expect(LedgerEntry.count).to eq(1)
      expect(account.reload.balance_cents).to eq(3000)
    end
  end

  describe 'duplicate email prevention' do
    let(:order) { create(:order, user: user, amount_cents: 5000) }

    it 'sends email only once even if job runs twice' do
      SendOrderEmailJob.perform_now(order.id, 'order_created')
      SendOrderEmailJob.perform_now(order.id, 'order_created')

      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(NotificationLog.count).to eq(1)
    end

    it 'allows different mail types for same order' do
      SendOrderEmailJob.perform_now(order.id, 'order_created')
      SendOrderEmailJob.perform_now(order.id, 'payment_successful')

      expect(ActionMailer::Base.deliveries.count).to eq(2)
      expect(NotificationLog.count).to eq(2)
    end
  end

  describe 'cancel idempotency guard' do
    let(:order) { create(:order, :successful, user: user, amount_cents: 4000, currency: 'RUB') }

    it 'second cancel returns failure' do
      result1 = Orders::Cancel.new.call(order: order)
      expect(result1).to be_success

      result2 = Orders::Cancel.new.call(order: order.reload)
      expect(result2).to be_failure
      expect(result2.failure).to eq(:already_cancelled)
    end

    it 'does not create extra ledger entries on failed cancel' do
      Orders::Cancel.new.call(order: order)

      expect {
        Orders::Cancel.new.call(order: order.reload)
      }.not_to change(LedgerEntry, :count)
    end
  end
end
