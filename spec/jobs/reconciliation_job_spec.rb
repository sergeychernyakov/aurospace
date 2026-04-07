# frozen_string_literal: true

# spec/jobs/reconciliation_job_spec.rb

require 'rails_helper'

RSpec.describe ReconciliationJob do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, balance_cents: 0, currency: 'RUB') }

  before do
    account
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('YOOKASSA_SHOP_ID').and_return('test_shop_id')
    allow(ENV).to receive(:fetch).with('YOOKASSA_SECRET_KEY').and_return('test_secret')
  end

  describe '#perform' do
    context 'with stale payment_pending order' do
      let!(:stale_order) do
        create(:order, :payment_pending, user: user, amount_cents: 5000, currency: 'RUB',
                                         external_payment_id: 'pay_stale',
                                         updated_at: 1.hour.ago,)
      end

      it 'marks order as successful when payment succeeded' do
        stub_request(:get, 'https://api.yookassa.ru/v3/payments/pay_stale')
          .to_return(status: 200, body: { 'id' => 'pay_stale', 'status' => 'succeeded' }.to_json,
                     headers: { 'Content-Type' => 'application/json' },)

        described_class.perform_now
        expect(stale_order.reload).to be_successful
      end

      it 'does not change order when payment is canceled' do
        stub_request(:get, 'https://api.yookassa.ru/v3/payments/pay_stale')
          .to_return(status: 200, body: { 'id' => 'pay_stale', 'status' => 'canceled' }.to_json,
                     headers: { 'Content-Type' => 'application/json' },)

        described_class.perform_now
        expect(stale_order.reload).to be_payment_pending
      end

      it 'handles provider errors gracefully' do
        stub_request(:get, 'https://api.yookassa.ru/v3/payments/pay_stale')
          .to_return(status: 500, body: { 'type' => 'error' }.to_json,
                     headers: { 'Content-Type' => 'application/json' },)

        expect { described_class.perform_now }.not_to raise_error
        expect(stale_order.reload).to be_payment_pending
      end
    end

    it 'skips orders without external_payment_id' do
      create(:order, :payment_pending, user: user, amount_cents: 5000, currency: 'RUB',
                                       external_payment_id: nil, updated_at: 1.hour.ago,)

      expect { described_class.perform_now }.not_to raise_error
    end

    it 'does not process recent orders' do
      create(:order, :payment_pending, user: user, amount_cents: 5000, currency: 'RUB',
                                       external_payment_id: 'pay_recent',)

      expect { described_class.perform_now }.not_to raise_error
    end
  end
end
