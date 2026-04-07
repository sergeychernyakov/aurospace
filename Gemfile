# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 3.3.0'

# === Core ===
gem 'bootsnap', require: false
gem 'pg', '~> 1.5'
gem 'puma', '~> 6.4'
gem 'rails', '~> 7.2', '>= 7.2.3.1'
gem 'redis', '~> 5.0'
gem 'sidekiq', '~> 7.2'
gem 'sidekiq-unique-jobs', '~> 8.0'

# === State machine ===
gem 'aasm', '~> 5.5'

# === Monadic results ===
gem 'dry-monads', '~> 1.6'
gem 'dry-struct', '~> 1.6'

# === Admin ===
gem 'activeadmin', '~> 3.2'
gem 'sassc-rails'

# === API ===
gem 'jbuilder', '~> 2.11'
gem 'rack-cors'
gem 'rswag-api', '~> 2.13'
gem 'rswag-ui', '~> 2.13'

# === Security ===
gem 'rack-attack', '~> 6.7'
gem 'secure_headers', '~> 6.5'

# === Database quality ===
gem 'strong_migrations', '~> 1.8'

# === Observability ===
gem 'opentelemetry-exporter-otlp', '~> 0.28'
gem 'opentelemetry-instrumentation-net_http', '~> 0.22'
gem 'opentelemetry-instrumentation-pg', '~> 0.29'
gem 'opentelemetry-instrumentation-rails', '~> 0.31'
gem 'opentelemetry-instrumentation-redis', '~> 0.25'
gem 'opentelemetry-instrumentation-sidekiq', '~> 0.25'
gem 'opentelemetry-sdk', '~> 1.4'

# === Module boundaries ===
gem 'packwerk', '~> 3.2'

# === HTTP client ===
gem 'faraday', '~> 2.9'

# === Payments ===
gem 'money-rails', '~> 1.15'
gem 'yookassa', '~> 0.1'

group :development, :test do
  # === Debugging ===
  gem 'debug', platforms: [:mri]
  gem 'pry-rails'

  # === Testing ===
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.2'
  gem 'rspec-rails', '~> 6.1'
  gem 'shoulda-matchers', '~> 6.1'

  # === Linting ===
  gem 'rubocop', '~> 1.68', '< 1.70', require: false
  gem 'rubocop-factory_bot', '~> 2.25', require: false
  gem 'rubocop-performance', '~> 1.20', require: false
  gem 'rubocop-rails', '~> 2.23', require: false
  gem 'rubocop-rspec', '~> 2.26', require: false

  # === Security ===
  gem 'brakeman', '~> 6.1', require: false
  gem 'bundler-audit', '~> 0.9', require: false

  # === DB quality ===
  gem 'annotate', '~> 3.2'
  gem 'bullet', '~> 7.1'
  gem 'database_consistency', '~> 1.7', require: false

  # === API docs ===
  gem 'rswag-specs', '~> 2.13'
end

group :test do
  # === Coverage ===
  gem 'simplecov', '~> 0.22', require: false
  gem 'simplecov-json', '~> 0.2', require: false

  # === Database cleaning ===
  gem 'database_cleaner-active_record', '~> 2.1'

  # === HTTP mocking ===
  gem 'vcr', '~> 6.2'
  gem 'webmock', '~> 3.23'

  # === Diff coverage ===
  # gem 'diff-cover' -- placeholder for future diff coverage tool

  # === PR automation ===
  gem 'danger', '~> 9.4', require: false

  # === YARD docs ===
  gem 'redcarpet', '~> 3.6', require: false
  gem 'yard', '~> 0.9', require: false
end

group :development do
  gem 'listen', '~> 3.8'
  gem 'rack-mini-profiler', '~> 3.3'
end
