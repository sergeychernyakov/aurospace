# frozen_string_literal: true

# app/models/notification_log.rb

class NotificationLog < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  belongs_to :order

  validates :mail_type, presence: true, uniqueness: { scope: :order_id }
  validates :recipient, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    ['id', 'order_id', 'mail_type', 'recipient', 'sent_at', 'created_at', 'updated_at', 'discarded_at']
  end

  def self.ransackable_associations(_auth_object = nil)
    ['order']
  end
end
