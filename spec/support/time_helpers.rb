# frozen_string_literal: true

# spec/support/time_helpers.rb
#
# Time safety for financial tests.
# Always use freeze_time/travel_to in tests that depend on timestamps.
# Never use Time.now in application code --- use Time.zone.now.

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
end

# Custom matcher to catch Time.now usage in production code
RSpec::Matchers.define :use_time_zone_now do
  match do |file_content|
    !file_content.match?(/\bTime\.now\b/)
  end

  failure_message do
    'Use Time.zone.now instead of Time.now for timezone safety'
  end
end
