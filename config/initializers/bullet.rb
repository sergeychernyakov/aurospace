# frozen_string_literal: true

# config/initializers/bullet.rb
#
# Detects N+1 queries and unused eager loading in development and test.
# Critical for a financial app where query performance matters.
#
# See: https://github.com/flyerhzm/bullet

if defined?(Bullet)
  Bullet.enable = true

  if Rails.env.development?
    Bullet.alert = false
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
  end

  if Rails.env.test?
    Bullet.raise = true # Fail tests on N+1 queries
  end
end
