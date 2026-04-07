# frozen_string_literal: true

# app/controllers/api_controller.rb
#
# Base controller for all API endpoints.
# Inherits from ActionController::API (no sessions, no CSRF, no cookies).
# ActiveAdmin uses ApplicationController < ActionController::Base separately.

class ApiController < ActionController::API
  include ErrorHandler
end
