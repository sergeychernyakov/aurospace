# frozen_string_literal: true

# Dangerfile
#
# Automated PR quality checks.
# Install: gem install danger
# Run: bundle exec danger

# === Size warning ===
warn "This PR is quite large (#{git.lines_of_code} lines). Consider splitting." if git.lines_of_code > 500

# === No tests for code changes ===
has_app_changes = !git.modified_files.grep(%r{^app/}).empty? ||
                  !git.added_files.grep(%r{^app/}).empty?
has_test_changes = !git.modified_files.grep(%r{^spec/}).empty? ||
                   !git.added_files.grep(%r{^spec/}).empty?

if has_app_changes && !has_test_changes
  raise 'Code changes detected without corresponding test changes. ' \
        'All app/ changes must have spec/ coverage.'
end

# === Critical zone changes need extra attention ===
critical_zones = [
  'app/services/orders/',
  'app/services/accounts/',
  'app/services/yookassa/',
  'app/models/order.rb',
  'app/models/account.rb',
  'app/models/ledger_entry.rb',
  'app/controllers/webhooks/',
  'app/jobs/',
]

changed_critical = (git.modified_files + git.added_files).select do |file|
  critical_zones.any? { |zone| file.start_with?(zone) }
end

if changed_critical.any?
  warn "Changes in **critical money domain** files:\n" \
       "#{changed_critical.map { |f| "- `#{f}`" }.join("\n")}\n\n" \
       'Ensure service tests, request tests, and integration tests cover these changes.'
end

# === Migration without rollback plan ===
has_migrations = !git.added_files.grep(%r{^db/migrate/}).empty?
if has_migrations
  warn 'New database migration detected. Ensure it is reversible and ' \
       'has been tested with `rails db:migrate && rails db:rollback`.'
end

# === TODO/FIXME in critical code ===
(git.modified_files + git.added_files).each do |file|
  next unless critical_zones.any? { |zone| file.start_with?(zone) }
  next unless File.exist?(file)

  File.readlines(file).each_with_index do |line, idx|
    if line.match?(/\b(TODO|FIXME|HACK|XXX)\b/i)
      warn "#{file}:#{idx + 1} contains TODO/FIXME in critical code. " \
           'Resolve before merging.'
    end
  end
end

# === Gemfile changes ===
if git.modified_files.include?('Gemfile') || git.modified_files.include?('Gemfile.lock')
  warn 'Gemfile changed. Run `bundle audit` and verify no vulnerabilities introduced.'
end

# === .env or secrets ===
secrets_patterns = /\.(env|pem|key)$|credentials|secrets/
leaked = (git.modified_files + git.added_files).grep(secrets_patterns)
if leaked.any?
  raise "Possible secrets/credentials files detected:\n" \
        "#{leaked.map { |f| "- `#{f}`" }.join("\n")}\n\n" \
        'Remove them from the commit immediately.'
end

# === PR description ===
warn 'PR description is too short. Explain what changed and why.' if github.pr_body.length < 50

# === Encourage small PRs ===
message 'Consider keeping PRs under 300 lines for easier review.' if git.lines_of_code > 300
