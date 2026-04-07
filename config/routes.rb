# frozen_string_literal: true

# config/routes.rb

require 'sidekiq/web'

Sidekiq::Web.use Rack::Auth::Basic do |user, pass|
  ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch('ADMIN_USER', 'admin')) &
    ActiveSupport::SecurityUtils.secure_compare(pass, ENV.fetch('ADMIN_PASSWORD', 'password'))
end

Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  mount Sidekiq::Web => '/admin/sidekiq'

  draw(:health)

  resources :orders, only: [:index, :show, :create] do
    member do
      post :pay
      post :cancel
    end
  end

  resources :accounts, only: [:show]

  namespace :webhooks do
    post :yookassa, to: 'yookassa#create'
  end

  root to: redirect(ENV.fetch('FRONTEND_URL', 'http://localhost:5173'))
end
