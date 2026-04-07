# frozen_string_literal: true

# app/errors/orders/invalid_transition_error.rb

module Orders
  class InvalidTransitionError < ApplicationError
    def initialize(message: nil, details: {})
      super(
        message: message,
        code: 'invalid_transition',
        status: :unprocessable_entity,
        details: details,
      )
    end

    private

    def default_message
      'Order cannot transition to the requested state'
    end
  end
end
