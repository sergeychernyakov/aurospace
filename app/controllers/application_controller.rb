# frozen_string_literal: true

# app/controllers/application_controller.rb

class ApplicationController < ActionController::Base
  include ErrorHandler

  # Skip CSRF verification for API requests (JSON)
  skip_before_action :verify_authenticity_token

  private

  def authenticate_admin!
    authenticate_or_request_with_http_basic('Admin') do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch('ADMIN_USER', 'admin')) &
        ActiveSupport::SecurityUtils.secure_compare(pass, ENV.fetch('ADMIN_PASSWORD', 'password'))
    end
  end
end
