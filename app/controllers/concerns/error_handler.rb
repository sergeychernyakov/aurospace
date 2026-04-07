# frozen_string_literal: true

# app/controllers/concerns/error_handler.rb

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ApplicationError do |error|
      render json: error.to_h, status: error.status
    end

    rescue_from ActiveRecord::RecordNotFound do |_error|
      render json: { error: { code: 'not_found', message: 'Resource not found' } }, status: :not_found
    end
  end
end
