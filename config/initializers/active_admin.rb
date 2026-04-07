# frozen_string_literal: true

# config/initializers/active_admin.rb

ActiveAdmin.setup do |config|
  config.site_title = 'AUROSPACE Admin'
  config.default_namespace = :a
  config.authentication_method = :authenticate_admin!
  config.current_user_method = false
  config.logout_link_path = false
  config.comments = false
  config.batch_actions = false
  config.root_to = 'dashboard#index'
end
