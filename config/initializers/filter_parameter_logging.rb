# frozen_string_literal: true

# config/initializers/filter_parameter_logging.rb
#
# Filter sensitive parameters from Rails logs.
# Critical for financial applications: never log payment data.

if defined?(Rails)
  Rails.application.config.filter_parameters += [
    # Standard auth
    :password,
    :password_confirmation,
    :token,
    :secret,
    :api_key,

    # Payment data (NEVER log these)
    :card_number,
    :cvv,
    :cvc,
    :expiry,
    :payment_method_data,

    # YooKassa
    :shop_secret,
    :yookassa_secret,

    # Personal data
    :email,
    :phone,
  ]
end
