# frozen_string_literal: true

# app/services/yookassa/process_webhook.rb

module Yookassa
  class ProcessWebhook
    include Dry::Monads[:result]

    def call(payload:)
      event_type = payload['event']
      object = payload['object'] || {}
      external_event_id = object['id']

      return Failure(:invalid_payload) if external_event_id.blank? || event_type.blank?

      webhook_event = create_event(event_type, external_event_id, payload)
      return Success(:duplicate) unless webhook_event

      process_and_finalize(webhook_event, event_type, object)
    end

    private

    def create_event(event_type, external_event_id, payload)
      WebhookEvent.create!(
        provider: 'yookassa',
        external_event_id: external_event_id,
        event_type: event_type,
        payload: payload,
      )
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      nil
    end

    def process_and_finalize(webhook_event, event_type, object)
      result = route_event(event_type, object)
      status = result.success? ? 'processed' : 'failed'
      webhook_event.update!(status: status, processed_at: Time.zone.now)
      result
    end

    def route_event(event_type, object)
      case event_type
      when 'payment.succeeded' then handle_payment_succeeded(object)
      when 'payment.canceled' then handle_payment_canceled(object)
      when 'refund.succeeded' then handle_refund_succeeded(object)
      else Success(:unknown_event_type)
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

    def handle_refund_succeeded(object)
      Rails.logger.info("Refund succeeded for payment #{object["payment_id"]}")
      Success(:refund_logged)
    end
  end
end
