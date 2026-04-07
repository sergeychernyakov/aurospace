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

Bundler.require(*Rails.groups)

module Aurospace
  class Application < Rails::Application
    config.load_defaults 7.2

    config.api_only = true
    config.time_zone = 'Moscow'
    config.active_job.queue_adapter = :sidekiq

    config.autoload_paths << Rails.root.join('app', 'errors')

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
    end
  end
end
