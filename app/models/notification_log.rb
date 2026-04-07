# frozen_string_literal: true

# app/models/notification_log.rb

class NotificationLog < ApplicationRecord
  belongs_to :order

  validates :mail_type, presence: true, uniqueness: { scope: :order_id }
  validates :recipient, presence: true
end
