# frozen_string_literal: true

# config/initializers/money.rb

MoneyRails.configure do |config|
  config.default_currency = :rub
  config.rounding_mode = BigDecimal::ROUND_HALF_UP
end
