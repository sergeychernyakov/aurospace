# frozen_string_literal: true

# app/services/orders/start_payment.rb

module Orders
  class StartPayment
    include Dry::Monads[:result]

    # @param order [Order] the order to start payment for
    # @param payment_id [String] external payment provider ID
    # @param confirmation_url [String] URL for user to confirm payment
    # @return [Dry::Monads::Result] Success or Failure
    def call(order:, payment_id:, confirmation_url:)
      return Failure(:invalid_transition) unless order.may_start_payment?

      order.start_payment!
      order.update!(
        payment_provider: 'yookassa',
        external_payment_id: payment_id,
      )

      Success({ order: order, confirmation_url: confirmation_url })
    rescue AASM::InvalidTransition
      Failure(:invalid_transition)
    end
  end
end
