# frozen_string_literal: true

# app/controllers/application_controller.rb

class ApplicationController < ActionController::API
  rescue_from ApplicationError do |error|
    render json: error.to_h, status: error.status
  end
end
