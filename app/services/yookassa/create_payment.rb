# frozen_string_literal: true

# app/services/yookassa/create_payment.rb

module Yookassa
  class CreatePayment
    include Dry::Monads[:result]

    # @param order [Order] the order to create payment for
    # @return [Dry::Monads::Result] Success({payment_id:, confirmation_url:}) or Failure
    def call(order:)
      return Failure(:already_paid) if order.external_payment_id.present?

      client = YookassaClient.new
      result = client.create_payment(
        amount_cents: order.amount_cents,
        currency: order.currency,
        description: "Order ##{order.id}",
        return_url: "#{ENV.fetch("FRONTEND_URL", "http://localhost:5173")}/orders/#{order.id}",
        idempotence_key: "order_#{order.id}",
      )

      Success({
        payment_id: result['id'],
        confirmation_url: result.dig('confirmation', 'confirmation_url'),
      })
    rescue ::Payments::ProviderError
      Failure(:provider_error)
    end
  end
end
