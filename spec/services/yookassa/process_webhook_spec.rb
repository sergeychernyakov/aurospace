# frozen_string_literal: true

# spec/services/yookassa/process_webhook_spec.rb

require 'rails_helper'

RSpec.describe Yookassa::ProcessWebhook do
  subject(:service) { described_class.new }

  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, balance_cents: 0, currency: 'RUB') }

  before { account }

  describe '#call' do
    context 'with payment.succeeded event' do
      let(:order) do
        create(:order, :payment_pending, user: user, amount_cents: 5000,
                                         currency: 'RUB', external_payment_id: 'pay_xyz',)
      end
      let(:params) do
        {
          'event' => 'payment.succeeded',
          'object' => { 'id' => 'pay_xyz', 'status' => 'succeeded' },
        }
      end

      before { order }

      it 'returns Success' do
        result = service.call(payload: params)
        expect(result).to be_success
      end

      it 'marks order as successful' do
        service.call(payload: params)
        expect(order.reload).to be_successful
      end

      it 'creates a WebhookEvent record' do
        expect {
          service.call(payload: params)
        }.to change(WebhookEvent, :count).by(1)
      end

      it 'creates a credit ledger entry' do
        expect {
          service.call(payload: params)
        }.to change(LedgerEntry, :count).by(1)
      end

      it 'marks WebhookEvent as processed' do
        service.call(payload: params)
        event = WebhookEvent.last
        expect(event.status).to eq('processed')
        expect(event.processed_at).to be_present
      end
    end

    context 'with payment.canceled event' do
      let(:order) do
        create(:order, :payment_pending, user: user, amount_cents: 5000,
                                         currency: 'RUB', external_payment_id: 'pay_cancel',)
      end
      let(:params) do
        {
          'event' => 'payment.canceled',
          'object' => { 'id' => 'pay_cancel', 'status' => 'canceled' },
        }
      end

      before { order }

      it 'returns Success(:payment_canceled)' do
        result = service.call(payload: params)
        expect(result).to be_success
        expect(result.value!).to eq(:payment_canceled)
      end

      it 'does not change order status' do
        service.call(payload: params)
        expect(order.reload).to be_payment_pending
      end
    end

    context 'with duplicate webhook event' do
      let(:order) do
        create(:order, :payment_pending, user: user, amount_cents: 5000,
                                         currency: 'RUB', external_payment_id: 'pay_dup',)
      end
      let(:params) do
        {
          'event' => 'payment.succeeded',
          'object' => { 'id' => 'pay_dup', 'status' => 'succeeded' },
        }
      end

      before do
        order
        create(:webhook_event, provider: 'yookassa', external_event_id: 'pay_dup',
                               event_type: 'payment.succeeded',)
      end

      it 'returns Success(:duplicate)' do
        result = service.call(payload: params)
        expect(result).to be_success
        expect(result.value!).to eq(:duplicate)
      end

      it 'does not create another WebhookEvent' do
        expect {
          service.call(payload: params)
        }.not_to change(WebhookEvent, :count)
      end
    end

    context 'with unknown order' do
      let(:params) do
        {
          'event' => 'payment.succeeded',
          'object' => { 'id' => 'pay_unknown', 'status' => 'succeeded' },
        }
      end

      it 'returns Failure(:unknown_order)' do
        result = service.call(payload: params)
        expect(result).to be_failure
        expect(result.failure).to eq(:unknown_order)
      end
    end

    context 'with invalid payload' do
      it 'returns Failure(:invalid_payload) when event is blank' do
        result = service.call(payload: { 'event' => '', 'object' => { 'id' => '123' } })
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_payload)
      end

      it 'returns Failure(:invalid_payload) when object id is blank' do
        result = service.call(payload: { 'event' => 'payment.succeeded', 'object' => {} })
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_payload)
      end

      it 'returns Failure(:invalid_payload) when object is missing' do
        result = service.call(payload: { 'event' => 'payment.succeeded' })
        expect(result).to be_failure
        expect(result.failure).to eq(:invalid_payload)
      end
    end

    context 'with refund.succeeded event' do
      let(:params) do
        {
          'event' => 'refund.succeeded',
          'object' => { 'id' => 'ref_123', 'status' => 'succeeded', 'payment_id' => 'pay_abc' },
        }
      end

      it 'returns Success(:refund_logged)' do
        result = service.call(payload: params)
        expect(result).to be_success
        expect(result.value!).to eq(:refund_logged)
      end

      it 'creates a WebhookEvent record' do
        expect {
          service.call(payload: params)
        }.to change(WebhookEvent, :count).by(1)
      end
    end

    context 'with unknown event type' do
      let(:params) do
        {
          'event' => 'capture.succeeded',
          'object' => { 'id' => 'cap_123', 'status' => 'succeeded' },
        }
      end

      it 'returns Success(:unknown_event_type)' do
        result = service.call(payload: params)
        expect(result).to be_success
        expect(result.value!).to eq(:unknown_event_type)
      end

      it 'still creates a WebhookEvent record' do
        expect {
          service.call(payload: params)
        }.to change(WebhookEvent, :count).by(1)
      end
    end
  end
end
