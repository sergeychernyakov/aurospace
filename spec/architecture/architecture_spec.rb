# frozen_string_literal: true

# spec/architecture/architecture_spec.rb
#
# Architecture enforcement tests.
# These specs ensure structural invariants of the codebase:
# - Controllers stay thin
# - Models don't call external APIs
# - Mailers don't contain business logic
# - Jobs only orchestrate, don't implement business logic
# - Balance changes only through ledger services

RSpec.describe 'Architecture constraints' do
  # Collect all Ruby files in given directory
  def ruby_files_in(dir)
    Dir.glob(Rails.root.join(dir, '**', '*.rb'))
  end

  def file_content(path)
    File.read(path)
  end

  describe 'Controllers' do
    it 'do not contain business logic (max 15 lines per action)' do
      violations = []

      ruby_files_in('app/controllers').each do |file|
        content = file_content(file)
        # Match method definitions and count lines until next def or end
        content.scan(/^\s*def (\w+).*?(?=\n\s*def |\n\s*private|\nend)/m).each do |match|
          method_body = match[0]
          line_count = method_body.lines.count
          if line_count > 15
            violations << "#{file}##{method_body.lines.first.strip} (#{line_count} lines)"
          end
        end
      end

      expect(violations).to be_empty,
        "Fat controller methods found:\n#{violations.join("\n")}"
    end

    it 'do not directly modify Account#balance_cents' do
      violations = []

      ruby_files_in('app/controllers').each do |file|
        content = file_content(file)
        if content.match?(/balance_cents\s*[+-]?=/)
          violations << file
        end
      end

      expect(violations).to be_empty,
        "Controllers must not modify balance directly:\n#{violations.join("\n")}"
    end
  end

  describe 'Models' do
    it 'do not call external APIs (HTTP clients)' do
      violations = []
      http_patterns = /\b(Net::HTTP|HTTParty|Faraday|RestClient|URI\.open|Typhoeus)\b/

      ruby_files_in('app/models').each do |file|
        content = file_content(file)
        if content.match?(http_patterns)
          violations << file
        end
      end

      expect(violations).to be_empty,
        "Models must not call external APIs. Use service objects:\n#{violations.join("\n")}"
    end

    it 'do not modify balance_cents directly (except Account model)' do
      violations = []

      ruby_files_in('app/models').each do |file|
        next if file.end_with?('account.rb')

        content = file_content(file)
        if content.match?(/balance_cents\s*[+-]?=/)
          violations << file
        end
      end

      expect(violations).to be_empty,
        "Only Account model (via ledger service) may touch balance_cents:\n#{violations.join("\n")}"
    end
  end

  describe 'Services' do
    it 'do not depend on controllers' do
      violations = []

      ruby_files_in('app/services').each do |file|
        content = file_content(file)
        if content.match?(/Controller|params\[|request\.|response\./)
          violations << file
        end
      end

      expect(violations).to be_empty,
        "Services must not depend on controllers:\n#{violations.join("\n")}"
    end
  end

  describe 'Jobs' do
    it 'only orchestrate, do not contain business logic' do
      violations = []

      ruby_files_in('app/jobs').each do |file|
        content = file_content(file)
        # Jobs should delegate to services, not contain SQL or balance logic
        if content.match?(/\.where\(|\.update!?\(|balance_cents|ActiveRecord::Base\.transaction/)
          violations << file
        end
      end

      expect(violations).to be_empty,
        "Jobs must delegate to services, not implement business logic:\n#{violations.join("\n")}"
    end
  end

  describe 'Mailers' do
    it 'do not contain business logic' do
      violations = []

      ruby_files_in('app/mailers').each do |file|
        content = file_content(file)
        if content.match?(/\.update!?\(|\.create!?\(|\.save!?\(|\.destroy/)
          violations << file
        end
      end

      expect(violations).to be_empty,
        "Mailers must not modify data. They only format and send:\n#{violations.join("\n")}"
    end
  end

  describe 'Money invariants' do
    it 'balance changes only happen through ledger services' do
      violations = []
      safe_paths = ['app/services/accounts/', 'spec/']

      Dir.glob(Rails.root.join('app', '**', '*.rb')).each do |file|
        next if safe_paths.any? { |safe| file.include?(safe) }

        content = file_content(file)
        if content.match?(/\.update.*balance_cents|\.increment.*balance_cents|balance_cents\s*[+-]?=/)
          violations << file
        end
      end

      expect(violations).to be_empty,
        "Balance mutations outside Accounts service detected:\n#{violations.join("\n")}"
    end
  end

  describe 'Side effects' do
    it 'emails are sent only via after_commit or jobs, not inside transactions' do
      violations = []

      ruby_files_in('app/services').each do |file|
        content = file_content(file)
        # Check for deliver_now/deliver_later inside service (should be after_commit)
        if content.match?(/\.deliver_(now|later)/) && !content.match?(/after_commit/)
          violations << file
        end
      end

      # This is a warning, not a hard failure (some patterns are valid)
      if violations.any?
        warn "Services sending email directly (prefer after_commit/jobs):\n#{violations.join("\n")}"
      end
    end
  end

  describe 'No debug statements in production code' do
    it 'does not contain binding.pry, byebug, debugger, puts, or pp' do
      violations = []
      debug_patterns = /\b(binding\.pry|binding\.irb|byebug|debugger)\b|^\s*(puts |pp |print )/

      Dir.glob(Rails.root.join('app', '**', '*.rb')).each do |file|
        content = file_content(file)
        content.lines.each_with_index do |line, idx|
          next if line.strip.start_with?('#')

          if line.match?(debug_patterns)
            violations << "#{file}:#{idx + 1}: #{line.strip}"
          end
        end
      end

      expect(violations).to be_empty,
        "Debug statements in production code:\n#{violations.join("\n")}"
    end
  end
end
