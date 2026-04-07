# frozen_string_literal: true

# app/controllers/application_controller.rb
#
# Base controller for ActiveAdmin and HTML views.
# API controllers inherit from ApiController instead.

class ApplicationController < ActionController::Base
  private

  def authenticate_admin!
    if Rails.env.production? && (ENV['ADMIN_USER'].blank? || ENV['ADMIN_PASSWORD'].blank?)
      raise 'ADMIN_USER and ADMIN_PASSWORD must be set in production'
    end

    authenticate_or_request_with_http_basic('Admin') do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch('ADMIN_USER', 'admin')) &
        ActiveSupport::SecurityUtils.secure_compare(pass, ENV.fetch('ADMIN_PASSWORD', 'password'))
    end
  end
end
