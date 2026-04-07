# frozen_string_literal: true

# spec/support/vcr.rb
#
# VCR configuration for recording/replaying HTTP interactions.
# Used for YooKassa API integration tests.
#
# First run: records real HTTP calls (requires test credentials).
# Subsequent runs: replays from cassettes (no network needed).

if defined?(VCR)
  VCR.configure do |config|
    config.cassette_library_dir = 'spec/cassettes'
    config.hook_into :webmock
    config.configure_rspec_metadata!

    # Don't record in CI unless explicitly requested
    config.default_cassette_options = {
      record: ENV['CI'] ? :none : :new_episodes,
      match_requests_on: [:method, :uri, :body],
    }

    # Filter sensitive data from cassettes
    config.filter_sensitive_data('<YOOKASSA_SHOP_ID>') { ENV.fetch('YOOKASSA_SHOP_ID', 'test_shop_id') }
    config.filter_sensitive_data('<YOOKASSA_SECRET>') { ENV.fetch('YOOKASSA_SECRET_KEY', 'test_secret') }
    config.filter_sensitive_data('<BEARER_TOKEN>') do |interaction|
      interaction.request.headers['Authorization']&.first
    end

    # Allow localhost (for test server)
    config.ignore_localhost = true

    # Raise on unmatched requests (no surprise network calls)
    config.allow_http_connections_when_no_cassette = false
  end
end
