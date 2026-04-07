# frozen_string_literal: true

# app/services/orders/cancel.rb

module Orders
  class Cancel
    include Dry::Monads[:result]

    # @param order [Order] the order to cancel
    # @return [Dry::Monads::Result] Success(Order) or Failure(Symbol)
    def call(order:)
      return Failure(:already_cancelled) if order.cancelled?
      return Failure(:invalid_transition) unless order.may_cancel?

      ActiveRecord::Base.transaction do
        order.lock!
        raise Orders::InvalidTransitionError unless order.may_cancel?

        apply_reversal(order)
        order.cancel!
        order.update!(cancelled_at: Time.zone.now)
      end

      request_refund(order)
      SendOrderEmailJob.perform_later(order.id, 'order_cancelled')
      Success(order.reload)
    rescue AASM::InvalidTransition, Orders::InvalidTransitionError
      Failure(:invalid_transition)
    end

    private

    def apply_reversal(order)
      Accounts::ApplyLedgerEntry.new.call(
        account: order.user.account,
        order: order,
        entry_type: :reversal,
        amount_cents: order.amount_cents,
        reference: "cancel_order_#{order.id}",
      ).value!
    end

    def request_refund(order)
      Yookassa::CreateRefund.new.call(order: order)
    rescue StandardError => e
      Rails.logger.error("Refund request failed for order #{order.id}: #{e.message}")
    end
  end
end
