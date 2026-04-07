# frozen_string_literal: true

# app/controllers/webhooks/yookassa_controller.rb

module Webhooks
  class YookassaController < ApplicationController
    skip_before_action :verify_authenticity_token, raise: false

    def create
      payload = JSON.parse(request.raw_post)
      ProcessWebhookJob.perform_later(payload)
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end
  end
end
