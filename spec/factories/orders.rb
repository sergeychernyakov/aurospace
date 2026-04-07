# frozen_string_literal: true

# spec/factories/orders.rb

FactoryBot.define do
  factory :order do
    user
    amount_cents { 1000 }
    currency { 'RUB' }
    status { :created }

    trait :payment_pending do
      status { :payment_pending }
    end

    trait :successful do
      status { :successful }
      paid_at { Time.current }
    end

    trait :cancelled do
      status { :cancelled }
      paid_at { 1.hour.ago }
      cancelled_at { Time.current }
    end
  end
end
