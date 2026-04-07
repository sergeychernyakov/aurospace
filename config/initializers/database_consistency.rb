# frozen_string_literal: true

# config/initializers/database_consistency.rb
#
# Checks that database constraints match model validations.
# Catches mismatches like: model validates presence, but column allows NULL.
#
# Run: bundle exec database_consistency
#
# See: https://github.com/djezzzl/database_consistency
