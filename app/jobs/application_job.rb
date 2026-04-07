# frozen_string_literal: true

# app/jobs/application_job.rb

class ApplicationJob < ActiveJob::Base
  # Individual jobs define their own retry policy.
  # Do not retry programmer errors (NameError, TypeError, etc.) globally.
end
