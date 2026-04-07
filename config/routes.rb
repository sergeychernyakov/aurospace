# frozen_string_literal: true

# config/routes.rb

Rails.application.routes.draw do
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
end
