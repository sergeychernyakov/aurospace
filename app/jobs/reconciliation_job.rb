# frozen_string_literal: true

# app/jobs/reconciliation_job.rb

class ReconciliationJob < ApplicationJob
  queue_as :low

  def perform
    Order.stale_payment_pending.find_each do |order|
      reconcile_order(order)
    end
  end

  private

  def reconcile_order(order)
    return if order.external_payment_id.blank?

    client = YookassaClient.new
    payment = client.get_payment(payment_id: order.external_payment_id)

    case payment['status']
    when 'succeeded'
      Orders::MarkSuccessful.new.call(order: order)
    when 'canceled'
      Rails.logger.info("Reconciliation: payment #{order.external_payment_id} canceled")
    end
  rescue Payments::ProviderError => e
    Rails.logger.error("Reconciliation failed for order #{order.id}: #{e.message}")
  end
end
