# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.2.2'

# === Core ===
gem 'rails', '~> 7.1'
gem 'pg', '~> 1.5'
gem 'puma', '~> 6.4'
gem 'redis', '~> 5.0'
gem 'sidekiq', '~> 7.2'
gem 'sidekiq-unique-jobs', '~> 8.0'
gem 'bootsnap', require: false

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
gem 'opentelemetry-sdk', '~> 1.4'
gem 'opentelemetry-exporter-otlp', '~> 0.28'
gem 'opentelemetry-instrumentation-rails', '~> 0.31'
gem 'opentelemetry-instrumentation-pg', '~> 0.29'
gem 'opentelemetry-instrumentation-redis', '~> 0.25'
gem 'opentelemetry-instrumentation-sidekiq', '~> 0.25'
gem 'opentelemetry-instrumentation-net_http', '~> 0.22'

# === Module boundaries ===
gem 'packwerk', '~> 3.2'

# === Payments ===
gem 'yookassa', '~> 0.1'
gem 'money-rails', '~> 1.15'

group :development, :test do
  # === Debugging ===
  gem 'debug', platforms: [:mri]
  gem 'pry-rails'

  # === Testing ===
  gem 'rspec-rails', '~> 6.1'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.2'
  gem 'shoulda-matchers', '~> 6.1'

  # === Linting ===
  gem 'rubocop', '~> 1.60', require: false
  gem 'rubocop-rails', '~> 2.23', require: false
  gem 'rubocop-rspec', '~> 2.26', require: false
  gem 'rubocop-performance', '~> 1.20', require: false
  gem 'rubocop-factory_bot', '~> 2.25', require: false

  # === Security ===
  gem 'brakeman', '~> 6.1', require: false
  gem 'bundler-audit', '~> 0.9', require: false

  # === DB quality ===
  gem 'database_consistency', '~> 1.7', require: false
  gem 'annotate', '~> 3.2'
  gem 'bullet', '~> 7.1'

  # === API docs ===
  gem 'rswag-specs', '~> 2.13'
end

group :test do
  # === Coverage ===
  gem 'simplecov', '~> 0.22', require: false
  gem 'simplecov-json', '~> 0.2', require: false

  # === HTTP mocking ===
  gem 'webmock', '~> 3.23'
  gem 'vcr', '~> 6.2'

  # === Diff coverage ===
  gem 'diff-cover', '~> 0.1', require: false

  # === PR automation ===
  gem 'danger', '~> 9.4', require: false

  # === YARD docs ===
  gem 'yard', '~> 0.9', require: false
  gem 'redcarpet', '~> 3.6', require: false
end

group :development do
  gem 'listen', '~> 3.8'
  gem 'rack-mini-profiler', '~> 3.3'
  gem 'web-console'
end
