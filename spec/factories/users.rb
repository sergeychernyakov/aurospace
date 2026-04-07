# frozen_string_literal: true

# spec/factories/users.rb

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    name { Faker::Name.name }

    trait :with_account do
      after(:create) do |user|
        create(:account, user: user)
      end
    end
  end
end
