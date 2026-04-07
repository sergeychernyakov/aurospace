# frozen_string_literal: true

# app/services/orders/create.rb

module Orders
  class Create
    include Dry::Monads[:result]

    # @param user [User] the user creating the order
    # @param amount_cents [Integer] positive amount in cents
    # @param currency [String] currency code (default: 'RUB')
    # @return [Dry::Monads::Result] Success(Order) or Failure(Symbol)
    def call(user:, amount_cents:, currency: 'RUB')
      return Failure(:invalid_amount) unless amount_cents.is_a?(Integer) && amount_cents.positive?
      return Failure(:account_missing) unless user.account

      order = Order.create!(
        user: user,
        amount_cents: amount_cents,
        currency: currency,
      )

      SendOrderEmailJob.perform_later(order.id, 'order_created')
      Success(order)
    end
  end
end
