# frozen_string_literal: true

# app/errors/payments/provider_error.rb

module Payments
  class ProviderError < ApplicationError
    def initialize(message: nil, details: {})
      super(
        message: message,
        code: 'provider_error',
        status: :bad_gateway,
        details: details,
      )
    end

    private

    def default_message
      'Payment provider returned an error'
    end
  end
end
