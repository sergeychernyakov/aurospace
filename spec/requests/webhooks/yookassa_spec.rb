# frozen_string_literal: true

# spec/requests/webhooks/yookassa_spec.rb

require 'rails_helper'

RSpec.describe 'Webhooks::Yookassa' do
  describe 'POST /webhooks/yookassa' do
    let(:valid_params) do
      {
        event: 'payment.succeeded',
        object: { id: 'pay_webhook_123', status: 'succeeded' },
      }
    end

    it 'returns 200 OK' do
      post '/webhooks/yookassa', params: valid_params, as: :json

      expect(response).to have_http_status(:ok)
    end

    it 'enqueues a ProcessWebhookJob' do
      expect {
        post '/webhooks/yookassa', params: valid_params, as: :json
      }.to have_enqueued_job(ProcessWebhookJob)
    end

    it 'always returns 200 even with invalid payload' do
      post '/webhooks/yookassa', params: { event: '' }, as: :json

      expect(response).to have_http_status(:ok)
    end
  end
end
