# frozen_string_literal: true

# app/errors/accounts/insufficient_funds_error.rb

module Accounts
  class InsufficientFundsError < ApplicationError
    def initialize(message: nil, details: {})
      super(
        message: message,
        code: 'insufficient_funds',
        status: :unprocessable_entity,
        details: details,
      )
    end

    private

    def default_message
      'Account has insufficient funds for this operation'
    end
  end
end
