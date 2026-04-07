# frozen_string_literal: true

# lib/yookassa_client.rb

class YookassaClient
  BASE_URL = 'https://api.yookassa.ru/v3'

  def initialize
    @shop_id = ENV.fetch('YOOKASSA_SHOP_ID')
    @secret_key = ENV.fetch('YOOKASSA_SECRET_KEY')
  end

  # @param amount_cents [Integer] amount in cents
  # @param currency [String] currency code
  # @param description [String] payment description
  # @param return_url [String] URL to redirect user after payment
  # @param idempotence_key [String] unique key for idempotent requests
  # @return [Hash] parsed response body
  def create_payment(amount_cents:, currency:, description:, return_url:, idempotence_key:)
    response = connection.post('/v3/payments') do |req|
      req.headers['Idempotence-Key'] = idempotence_key
      req.body = {
        amount: { value: (amount_cents / 100.0).to_s, currency: currency },
        confirmation: { type: 'redirect', return_url: return_url },
        capture: true,
        description: description,
      }.to_json
    end

    handle_response(response)
  end

  # @param payment_id [String] external payment ID to refund
  # @param amount_cents [Integer] amount in cents to refund
  # @param currency [String] currency code
  # @param idempotence_key [String] unique key for idempotent requests
  # @return [Hash] parsed response body
  def create_refund(payment_id:, amount_cents:, currency:, idempotence_key:)
    response = connection.post('/v3/refunds') do |req|
      req.headers['Idempotence-Key'] = idempotence_key
      req.body = {
        payment_id: payment_id,
        amount: { value: (amount_cents / 100.0).to_s, currency: currency },
      }.to_json
    end

    handle_response(response)
  end

  # @param payment_id [String] external payment ID
  # @return [Hash] parsed response body
  def get_payment(payment_id:)
    response = connection.get("/v3/payments/#{payment_id}")
    handle_response(response)
  end

  private

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.request :authorization, :basic, @shop_id, @secret_key
      f.response :json
      f.options.timeout = 10
      f.options.open_timeout = 5
      f.adapter Faraday.default_adapter
    end
  end

  def handle_response(response)
    return response.body if response.success?

    raise Payments::ProviderError.new(
      message: "YooKassa API error: #{response.status}",
      details: { status: response.status, body: response.body },
    )
  end
end
