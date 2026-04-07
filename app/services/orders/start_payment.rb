# frozen_string_literal: true

# app/services/orders/start_payment.rb

module Orders
  class StartPayment
    include Dry::Monads[:result]

    def call(order:, payment_id:, confirmation_url:)
      return Failure(:invalid_transition) unless order.may_start_payment?

      ActiveRecord::Base.transaction do
        order.lock!
        raise Orders::InvalidTransitionError unless order.may_start_payment?

        order.start_payment!
        order.update!(
          payment_provider: 'yookassa',
          external_payment_id: payment_id,
        )
      end

      Success({ order: order.reload, confirmation_url: confirmation_url })
    rescue AASM::InvalidTransition, Orders::InvalidTransitionError
      Failure(:invalid_transition)
    end
  end
end
