# frozen_string_literal: true

# spec/factories/webhook_events.rb

FactoryBot.define do
  factory :webhook_event do
    provider { 'yookassa' }
    sequence(:external_event_id) { |n| "evt_#{n}" }
    event_type { 'payment.succeeded' }
    payload { { 'object' => { 'id' => '123' } } }
    status { 'pending' }

    trait :processed do
      status { 'processed' }
      processed_at { Time.current }
    end
  end
end
