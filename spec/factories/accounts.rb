# frozen_string_literal: true

# spec/factories/accounts.rb

FactoryBot.define do
  factory :account do
    user
    balance_cents { 0 }
    currency { 'RUB' }
  end
end
