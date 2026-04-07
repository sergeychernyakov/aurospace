# frozen_string_literal: true

# spec/support/factory_bot_lint.rb
#
# Validates ALL factories on CI to catch broken factories early.
# A broken factory = silent test corruption.

RSpec.configure do |config|
  config.before(:suite) do
    if ENV['CI'] || ENV['LINT_FACTORIES']
      DatabaseCleaner.cleaning do
        FactoryBot.lint(traits: true, strategy: :create)
      end
    end
  end
end
