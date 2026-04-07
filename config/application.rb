# frozen_string_literal: true

# config/application.rb

require_relative 'boot'
require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'

Bundler.require(*Rails.groups)

module Aurospace
  class Application < Rails::Application
    config.load_defaults 7.2

    # ActiveAdmin requires the full middleware stack (sessions, cookies, flash, assets, layouts).
    # Set api_only = false so ActionController::Base gets full functionality.
    # API controllers inherit from ActionController::API explicitly.
    config.api_only = false
    config.time_zone = 'Moscow'
    config.active_job.queue_adapter = :sidekiq

    config.autoload_paths << Rails.root.join('app', 'errors')
    config.autoload_paths << Rails.root.join('lib')

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
    end
  end
end
