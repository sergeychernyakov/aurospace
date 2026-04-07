# frozen_string_literal: true

# app/services/yookassa/create_refund.rb

module Yookassa
  class CreateRefund
    include Dry::Monads[:result]

    # @param order [Order] the order to refund
    # @return [Dry::Monads::Result] Success(Hash) or Failure(Symbol)
    def call(order:)
      return Failure(:no_payment_id) if order.external_payment_id.blank?

      client = YookassaClient.new
      result = client.create_refund(
        payment_id: order.external_payment_id,
        amount_cents: order.amount_cents,
        currency: order.currency,
        idempotence_key: "refund_order_#{order.id}",
      )

      Success(result)
    rescue ::Payments::ProviderError
      Failure(:refund_failed)
    end
  end
end
