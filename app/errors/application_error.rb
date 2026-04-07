# frozen_string_literal: true

# app/errors/application_error.rb
#
# Base error class for all domain errors.
# Provides structured error responses for API consumers.
#
# Usage:
#   raise Orders::InvalidTransitionError.new(
#     message: "Cannot cancel order in 'created' state",
#     details: { current_status: 'created', attempted: 'cancelled' }
#   )

class ApplicationError < StandardError
  attr_reader :code, :status, :details

  def initialize(message: nil, code: nil, status: :unprocessable_entity, details: {})
    @code = code || self.class.name.demodulize.underscore.delete_suffix('_error')
    @status = status
    @details = details
    super(message || default_message)
  end

  # Structured response for API
  def to_h
    {
      error: {
        code: code,
        message: message,
        details: details,
      }.compact_blank,
    }
  end

  private

  def default_message
    'An error occurred'
  end
end
