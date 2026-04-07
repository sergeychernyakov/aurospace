# frozen_string_literal: true

# app/jobs/send_order_email_job.rb

class SendOrderEmailJob < ApplicationJob
  queue_as :mailers

  def perform(order_id, mail_type)
    order = Order.find(order_id)

    return if NotificationLog.exists?(order_id: order_id, mail_type: mail_type)

    OrderMailer.public_send(mail_type, order).deliver_now

    NotificationLog.create!(
      order: order,
      mail_type: mail_type,
      recipient: order.user.email,
      sent_at: Time.zone.now,
    )
  end
end
