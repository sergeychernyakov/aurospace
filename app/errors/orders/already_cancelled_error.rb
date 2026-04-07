# frozen_string_literal: true

# app/errors/orders/already_cancelled_error.rb

module Orders
  class AlreadyCancelledError < ApplicationError
    def initialize(message: nil, details: {})
      super(
        message: message,
        code: 'already_cancelled',
        status: :conflict,
        details: details,
      )
    end

    private

    def default_message
      'Order has already been cancelled'
    end
  end
end
