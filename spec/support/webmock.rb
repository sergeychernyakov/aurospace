# frozen_string_literal: true

# spec/support/webmock.rb
#
# Block all real HTTP requests in tests by default.
# External API calls must be explicitly stubbed or use VCR cassettes.

if defined?(WebMock)
  WebMock.disable_net_connect!(
    allow_localhost: true,
    allow: [
      'chromedriver.storage.googleapis.com', # System tests
    ],
  )
end
