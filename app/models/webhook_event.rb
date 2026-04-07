# frozen_string_literal: true

# app/models/webhook_event.rb

class WebhookEvent < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  validates :provider, presence: true
  validates :external_event_id, presence: true, uniqueness: true
  validates :event_type, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    ['id', 'provider', 'external_event_id', 'event_type', 'status', 'processed_at', 'created_at', 'updated_at',
     'discarded_at',]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
