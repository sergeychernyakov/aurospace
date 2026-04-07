# frozen_string_literal: true

# spec/factories/notification_logs.rb

FactoryBot.define do
  factory :notification_log do
    order
    mail_type { 'order_confirmation' }
    recipient { Faker::Internet.email }

    trait :sent do
      sent_at { Time.current }
    end
  end
end
