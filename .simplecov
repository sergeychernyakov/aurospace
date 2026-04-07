# .simplecov
# frozen_string_literal: true

SimpleCov.start 'rails' do
  # Branch coverage: catches untested if/else, case/when, ternary
  enable_coverage :branch

  # === Global thresholds ===
  # Enforced by bin/check_coverage (handles scaffold state gracefully).
  # SimpleCov's built-in minimum_coverage is intentionally NOT set here
  # because it fails on zero-line scaffold with no domain code yet.
  # bin/check_coverage enforces: 90% global, 95% critical, 80% per-file.

  # === Critical domain folders: 95%+ ===
  # These are the money paths. 90% global is not enough here.
  # Enforced separately in CI via custom check script.
  #
  # app/services/orders/     - order lifecycle
  # app/services/accounts/   - ledger operations
  # app/services/yookassa/   - payment provider
  # app/jobs/                - async processing
  # app/mailers/             - email delivery

  # === Groups for reporting ===
  add_group 'Models',           'app/models'
  add_group 'Controllers',      'app/controllers'
  add_group 'Order Services',   'app/services/orders'
  add_group 'Account Services', 'app/services/accounts'
  add_group 'YooKassa',         'app/services/yookassa'
  add_group 'Other Services',   'app/services'
  add_group 'Jobs',             'app/jobs'
  add_group 'Mailers',          'app/mailers'
  add_group 'Queries',          'app/queries'
  add_group 'Policies',         'app/policies'
  add_group 'Serializers',      'app/serializers'
  add_group 'Libraries',        'lib'

  # === Exclusions ===
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/db/'
  add_filter '/vendor/'
  add_filter '/app/admin/'

  # Track files even if they have 0 coverage (exposes untested code)
  track_files '{app,lib}/**/*.rb'

  # === Output ===
  if ENV['CI']
    require 'simplecov-json'
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::JSONFormatter,
    ])
  else
    formatter SimpleCov::Formatter::HTMLFormatter
  end

  # Refuse to merge results older than 10 minutes
  merge_timeout 600
end
