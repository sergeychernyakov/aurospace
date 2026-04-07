# frozen_string_literal: true

# app/jobs/application_job.rb

class ApplicationJob < ActiveJob::Base
  retry_on StandardError, wait: :polynomially_longer, attempts: 3
end
