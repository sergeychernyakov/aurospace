# frozen_string_literal: true

# app/controllers/webhooks/yookassa_controller.rb

module Webhooks
  class YookassaController < ApplicationController
    skip_before_action :verify_authenticity_token, raise: false
    before_action :verify_ip

    # YooKassa webhook IP ranges
    # https://yookassa.ru/developers/using-api/webhooks
    ALLOWED_IPS = [
      '185.71.76.0/27',
      '185.71.77.0/27',
      '77.75.153.0/25',
      '77.75.156.11',
      '77.75.156.35',
      '77.75.154.128/25',
      '2a02:5180::/32',
    ].freeze

    def create
      payload = JSON.parse(request.raw_post)
      ProcessWebhookJob.perform_later(payload)
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def verify_ip
      return if Rails.env.local?

      client_ip = request.remote_ip
      allowed = ALLOWED_IPS.any? do |range|
        IPAddr.new(range).include?(client_ip)
      rescue IPAddr::InvalidAddressError
        false
      end

      head :forbidden unless allowed
    end
  end
end
