# frozen_string_literal: true

# spec/factories/ledger_entries.rb

FactoryBot.define do
  factory :ledger_entry do
    account
    order
    entry_type { :credit }
    amount_cents { 1000 }
    currency { 'RUB' }

    trait :debit do
      entry_type { :debit }
    end

    trait :credit do
      entry_type { :credit }
    end

    trait :reversal do
      entry_type { :reversal }
    end
  end
end
