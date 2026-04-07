# frozen_string_literal: true

# app/services/yookassa/process_webhook.rb

module Yookassa
  class ProcessWebhook
    include Dry::Monads[:result]

    # @param payload [Hash] webhook payload from YooKassa
    # @return [Dry::Monads::Result] Success or Failure
    def call(payload:)
      event_type = payload['event']
      object = payload['object'] || {}
      external_event_id = object['id']

      return Failure(:invalid_payload) if external_event_id.blank? || event_type.blank?

      webhook_event = WebhookEvent.create!(
        provider: 'yookassa',
        external_event_id: external_event_id,
        event_type: event_type,
        payload: payload,
      )

      result = route_event(event_type, object)

      webhook_event.update!(status: 'processed', processed_at: Time.zone.now)
      result
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
      raise e unless e.is_a?(ActiveRecord::RecordInvalid) && duplicate_event?(e)

      Success(:duplicate)
    end

    private

    def duplicate_event?(error)
      error.record.is_a?(WebhookEvent) && error.record.errors[:external_event_id].present?
    end

    def route_event(event_type, object)
      case event_type
      when 'payment.succeeded'
        handle_payment_succeeded(object)
      when 'payment.canceled'
        handle_payment_canceled(object)
      else
        Success(:unknown_event_type)
      end
    end

    def handle_payment_succeeded(object)
      order = Order.find_by(external_payment_id: object['id'])
      return Failure(:unknown_order) unless order

      Orders::MarkSuccessful.new.call(order: order)
    end

    def handle_payment_canceled(object)
      order = Order.find_by(external_payment_id: object['id'])
      return Failure(:unknown_order) unless order

      Success(:payment_canceled)
    end
  end
end
