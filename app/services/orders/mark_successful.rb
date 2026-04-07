# frozen_string_literal: true

# app/services/orders/mark_successful.rb

module Orders
  class MarkSuccessful
    include Dry::Monads[:result]

    # @param order [Order] the order to mark as successful
    # @return [Dry::Monads::Result] Success(Order) or Failure(Symbol)
    def call(order:)
      return Success(order) if order.successful?
      return Failure(:invalid_transition) unless order.may_mark_successful?

      execute_transition(order)

      SendOrderEmailJob.perform_later(order.id, 'payment_successful')
      Success(order.reload)
    rescue AASM::InvalidTransition, Orders::InvalidTransitionError
      Failure(:invalid_transition)
    rescue Dry::Monads::UnwrapError
      Failure(:ledger_error)
    end

    private

    def execute_transition(order)
      ActiveRecord::Base.transaction do
        order.lock!
        raise Orders::InvalidTransitionError unless order.may_mark_successful?

        apply_credit(order)
        order.mark_successful!
        order.update!(paid_at: Time.zone.now)
      end
    end

    def apply_credit(order)
      Accounts::ApplyLedgerEntry.new.call(
        account: order.user.account,
        order: order,
        entry_type: :credit,
        amount_cents: order.amount_cents,
        reference: "payment_#{order.external_payment_id}",
      ).value!
    end
  end
end
