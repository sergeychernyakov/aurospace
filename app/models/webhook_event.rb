# frozen_string_literal: true

# app/models/webhook_event.rb

class WebhookEvent < ApplicationRecord
  validates :provider, presence: true
  validates :external_event_id, presence: true, uniqueness: true
  validates :event_type, presence: true
end
