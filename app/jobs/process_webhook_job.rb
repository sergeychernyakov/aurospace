# frozen_string_literal: true

# app/jobs/process_webhook_job.rb

class ProcessWebhookJob < ApplicationJob
  queue_as :critical
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(payload)
    Yookassa::ProcessWebhook.new.call(payload: payload)
  end
end
