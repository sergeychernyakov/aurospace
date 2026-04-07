# frozen_string_literal: true

# app/errors/payments/duplicate_webhook_error.rb

module Payments
  class DuplicateWebhookError < ApplicationError
    def initialize(message: nil, details: {})
      super(
        message: message,
        code: 'duplicate_webhook',
        status: :conflict,
        details: details,
      )
    end

    private

    def default_message
      'This webhook event has already been processed'
    end
  end
end
