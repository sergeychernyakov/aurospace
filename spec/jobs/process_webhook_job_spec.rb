# frozen_string_literal: true

# spec/jobs/process_webhook_job_spec.rb

require 'rails_helper'

RSpec.describe ProcessWebhookJob do
  describe '#perform' do
    let(:payload) do
      { 'event' => 'payment.succeeded', 'object' => { 'id' => 'pay_job_123' } }
    end

    it 'delegates to Yookassa::ProcessWebhook service' do
      service = instance_double(Yookassa::ProcessWebhook)
      allow(Yookassa::ProcessWebhook).to receive(:new).and_return(service)
      allow(service).to receive(:call).with(payload: payload).and_return(Dry::Monads::Success(:processed))

      described_class.perform_now(payload)

      expect(service).to have_received(:call).with(payload: payload)
    end
  end
end
