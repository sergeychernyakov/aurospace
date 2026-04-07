# frozen_string_literal: true

# config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('FRONTEND_URL', 'http://localhost:5173')

    resource '/orders/*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             credentials: true
    resource '/accounts/*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             credentials: true
    resource '/webhooks/*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             credentials: true
    resource '/up',
             headers: :any,
             methods: [:get],
             credentials: true
    resource '/health',
             headers: :any,
             methods: [:get],
             credentials: true
  end
end
