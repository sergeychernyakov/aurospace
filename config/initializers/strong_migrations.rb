# frozen_string_literal: true

# config/initializers/strong_migrations.rb
#
# Prevents dangerous migrations from running in production.
# Catches: removing columns, changing column types, adding indexes
# without CONCURRENTLY, etc.
#
# See: https://github.com/ankane/strong_migrations

if defined?(StrongMigrations)
  # Mark existing migrations as safe
  StrongMigrations.start_after = 20_260_407_000_000

  # Custom error messages
  StrongMigrations.error_messages[:remove_column] =
    "Removing a column is dangerous. Use a multi-step approach:\n" \
    "1. Ignore the column: self.ignored_columns += [\"column_name\"]\n" \
    "2. Deploy\n" \
    "3. Remove the column in a separate migration\n" \
    "If you're sure, use safety_assured { ... }"
end
