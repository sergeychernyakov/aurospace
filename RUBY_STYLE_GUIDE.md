# RUBY_STYLE_GUIDE.md

## 💎 **Ruby & Rails Development Guide**

## 📦 General Guidelines

* Write **clean**, **readable**, and **modular** code.
* Follow **DRY**, **KISS**, and **YAGNI** principles.
* Use meaningful, descriptive names for all entities.
* The **first line of each file** must be a comment with the file path, e.g.:

  ```ruby
  # app/services/user_service.rb
  ```
* Use **blocks**, **enumerables**, and **Ruby idioms** where appropriate.
* One file = one responsibility. No dumping ground modules.
* Consistent naming across the repo. Be a naming ninja.
* **Follow Rails conventions** — convention over configuration
* **All requires must be at the top of the file** — no requires inside methods.
* **Do not define methods inside other methods** — keep code structure flat and clear.
* **Make methods private** if they are only used within the class.

---

## 📁 Project Structure (Rails Convention over Configuration)

```
project/
├── app/
│   ├── models/          # ActiveRecord models with business logic
│   ├── services/        # Service objects (one action per class)
│   ├── validators/      # Custom validation logic
│   ├── helpers/         # View helpers and utility methods
│   ├── queries/         # Query objects for complex ActiveRecord operations
│   ├── presenters/      # Data presentation/formatting (also called Decorators)
│   ├── jobs/            # Background jobs (ActiveJob, Sidekiq)
│   ├── mailers/         # Email senders (ActionMailer)
│   ├── controllers/     # Request handlers
│   └── concerns/        # Shared modules and mixins
├── lib/
│   ├── tasks/           # Rake tasks
│   └── modules/         # Reusable library code
├── spec/                # RSpec tests (mirror app/ structure)
│   ├── models/
│   ├── services/
│   ├── requests/        # Integration/API tests
│   ├── factories/       # FactoryBot factories
│   └── support/         # Test helpers
└── config/              # Configuration files
```

---

## 🧱 Naming Conventions (Rails-style)

### ✅ File Names (snake_case)

* Lowercase with underscores.
* Example: `user_controller.rb`, `order_mailer.rb`, `payment_service.rb`

### ✅ Class Names (CamelCase)

* Use singular nouns for models and services.
* Use plural for controllers: `UsersController`
* Example: `User`, `InvoiceMailer`, `PaymentService`

### ✅ Method & Variable Names (snake_case)

* Use action-based, meaningful verbs.
* Example: `send_email`, `create_user`, `process_payment`
* Predicate methods end with `?`: `valid?`, `active?`, `empty?`
* Dangerous methods end with `!`: `save!`, `destroy!`, `update!`

### ✅ Constants (SCREAMING_SNAKE_CASE)

* All uppercase with underscores.
* Example: `MAX_RETRIES`, `DEFAULT_TIMEOUT`, `API_VERSION`

### ✅ Test File Naming

* Match source file: `user_service.rb` → `user_service_spec.rb`
* Describe blocks: `describe '#create_user'`
* Context blocks: `context 'when user is valid'`

---

## ⚙️ OOP & Design Patterns

### Core OOP Principles
* Use OOP principles: **encapsulation**, **abstraction**, **polymorphism**, **inheritance**.
* Favor **composition over inheritance** (use modules and mixins).
* Follow **SOLID** principles.
* Use **modules** for shared behavior, **concerns** for ActiveRecord models.

### Rails-inspired Patterns

#### Service Objects
* **One class = One action**
* Naming: `VerbNounService` (e.g., `CreateUserService`, `ProcessPaymentService`)
* Single public method: `call` or `execute`
```ruby
# app/services/create_user_service.rb
class CreateUserService
  def initialize(user_params)
    @user_params = user_params
  end

  def call
    # Validation, creation, notifications, etc.
    User.create!(@user_params)
  end

  private

  attr_reader :user_params
end
```

#### Query Objects
* Encapsulate complex database queries
* Naming: `ModelQuery` (e.g., `UserQuery`, `OrderQuery`)
* Chainable methods using ActiveRecord scopes
```ruby
# app/queries/user_query.rb
class UserQuery
  def initialize(relation = User.all)
    @relation = relation
  end

  def active
    @relation = @relation.where(active: true)
    self
  end

  def with_subscription
    @relation = @relation.joins(:subscription)
    self
  end

  def results
    @relation
  end
end
```

#### Form Objects
* Separate validation from models
* Naming: `ActionForm` (e.g., `RegistrationForm`, `CheckoutForm`)
* Include `ActiveModel::Model` for Rails validations
```ruby
# app/forms/registration_form.rb
class RegistrationForm
  include ActiveModel::Model

  attr_accessor :email, :password, :name

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }
  validates :name, presence: true

  def save
    return false unless valid?

    User.create!(attributes)
  end

  private

  def attributes
    { email: email, password: password, name: name }
  end
end
```

#### Presenter/Decorator Pattern
* Separate presentation logic from models
* Naming: `ModelPresenter` or `ModelDecorator`
* Can use Draper gem
```ruby
# app/presenters/user_presenter.rb
class UserPresenter
  def initialize(user)
    @user = user
  end

  def full_name
    "#{@user.first_name} #{@user.last_name}"
  end

  def formatted_created_at
    @user.created_at.strftime('%B %d, %Y')
  end

  private

  attr_reader :user
end
```

#### Callbacks/Hooks (ActiveRecord)
* Use `before_`, `after_`, `around_` naming
* Clear execution order
* **Prefer service objects over heavy callbacks**
```ruby
class User < ApplicationRecord
  before_save :normalize_email
  after_create :send_welcome_email

  private

  def normalize_email
    self.email = email.downcase.strip
  end

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end
end
```

#### Concerns (Shared Modules)
* Extract shared behavior into modules
* Place in `app/models/concerns/` or `app/controllers/concerns/`
```ruby
# app/models/concerns/searchable.rb
module Searchable
  extend ActiveSupport::Concern

  included do
    scope :search, ->(query) { where('name ILIKE ?', "%#{query}%") }
  end

  class_methods do
    def find_by_search(query)
      search(query).first
    end
  end
end

# Usage in model
class User < ApplicationRecord
  include Searchable
end
```

---

## 📝 Documentation & Comments

* Use **YARD** for documenting public APIs
* Comments explain **"why"**, not **"what"**
* Document method parameters and return values:

  ```ruby
  # Sends an email using ActionMailer
  #
  # @param to [String] recipient's email address
  # @param subject [String] email subject
  # @param body [String] email body text
  # @return [Mail::Message] the email message
  def send_email(to:, subject:, body:)
    UserMailer.custom_email(to, subject, body).deliver_now
  end
  ```

* TODO comments must include date and context:
  ```ruby
  # TODO (2024-01-15): Refactor after API v2 migration
  ```
* No commented-out code—use version control
* Update docs when changing functionality

---

## 🧪 Testing (RSpec)

### Test Structure
* Use `rspec` for all tests (or `minitest` if preferred)
* Tests mirror application structure exactly
* Separate directories for:
  - `spec/models/` — Model tests
  - `spec/services/` — Service object tests
  - `spec/requests/` — Integration/API tests
  - `spec/factories/` — FactoryBot factories

### Test Naming (RSpec conventions)
* Use `describe` for grouping by class/method
* Use `context` for different scenarios
* Use `it` with clear descriptions:
```ruby
# spec/services/create_user_service_spec.rb
RSpec.describe CreateUserService do
  describe '#call' do
    context 'when user data is valid' do
      it 'creates a new user' do
        # Test implementation
      end

      it 'sends welcome email' do
        # Test implementation
      end
    end

    context 'when email is duplicate' do
      it 'raises validation error' do
        # Test implementation
      end
    end
  end
end
```

### Test Patterns
* Follow **AAA pattern**: Arrange → Act → Assert
* **One expectation per test** (when possible)
* Use **FactoryBot** for test data:
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    name { Faker::Name.name }
    password { 'password123' }

    trait :admin do
      role { 'admin' }
    end

    trait :with_subscription do
      association :subscription
    end
  end
end

# Usage
user = create(:user)
admin = create(:user, :admin)
```

### Coverage & Quality
* Target **90%+ test coverage** (SimpleCov)
* Cover:
  - Happy paths ✅
  - Edge cases ⚠️
  - Error conditions 💣
  - Boundary values
* Test behavior, not implementation
* Use mocks/stubs sparingly—prefer real objects

### Test Tools
* `rspec-rails` — Rails integration
* `factory_bot_rails` — Test data factories
* `faker` — Fake data generation
* `shoulda-matchers` — Model/controller matchers
* `webmock` — HTTP request stubbing
* `timecop` or `ActiveSupport::Testing::TimeHelpers` for time-based tests
* `database_cleaner` — Clean test database

---

## ✅ Linting & Code Quality

* Follow **Ruby Style Guide** (rubystyle.guide)
* Tools:

  * `rubocop` (linting and formatting)
  * `rubocop-rails` (Rails-specific cops)
  * `rubocop-rspec` (RSpec-specific cops)
  * `brakeman` (security scanner)
  * `reek` (code smell detector)

* Avoid:

  * Long methods → break them up (max 10 lines)
  * Long classes → use concerns and services
  * Magic numbers → name them
  * Cyclic dependencies → restructure
  * Global variables → use constants or dependency injection

* Max line length: 100-120 chars (configure in .rubocop.yml)

### RuboCop Configuration Example
```yaml
# .rubocop.yml
AllCops:
  NewCops: enable
  TargetRubyVersion: 3.2
  Exclude:
    - 'db/schema.rb'
    - 'vendor/**/*'

Metrics/MethodLength:
  Max: 10

Metrics/ClassLength:
  Max: 100

Style/Documentation:
  Enabled: false  # Or true if you want mandatory docs

Layout/LineLength:
  Max: 120
```

---

## 🪵 Logging & Error Handling

* Use Rails logger, never `puts` or `print`
* Log levels: `debug`, `info`, `warn`, `error`, `fatal`
* Don't log secrets or PII
* Use tagged logging:

  ```ruby
  Rails.logger.tagged("UserService") do
    Rails.logger.info "Processing user #{user.id}"
  end
  ```

* Raise **custom exceptions** with helpful messages:
  ```ruby
  class UserService
    class InvalidUserError < StandardError; end

    def create_user(params)
      raise InvalidUserError, "Email is required" if params[:email].blank?
      # ...
    end
  end
  ```

* **FAIL FAST principle**:
  * Do **NOT** mask problems with unnecessary fallbacks
  * Use `begin/rescue` **only** for specific, expected errors
  * Do **NOT** use `respond_to?` or `try` for required methods
  * Access methods directly: `user.email` NOT `user.try(:email)`
  * If required data is missing—**raise an error**, don't silently continue
  * Use `!` methods (`save!`, `create!`) to raise on failure
  * Let the application crash if something is wrong—fix the root cause

* Prefer structured logging (e.g., Lograge) in production

---

## 🔧 Constants & Configuration

* All constants in **SCREAMING_SNAKE_CASE**: `MAX_RETRIES = 3`
* Extract magic numbers to named constants:
  ```ruby
  # Bad
  return if items.length > 100

  # Good
  MAX_ITEMS_PER_PAGE = 100
  return if items.length > MAX_ITEMS_PER_PAGE
  ```

* Configuration through Rails credentials or ENV variables—**never hardcode**
* Use `config/initializers/` for app-wide settings
* Group related constants in modules:
  ```ruby
  module PaymentConstants
    TIMEOUT = 30
    MAX_RETRIES = 3
    SUPPORTED_CURRENCIES = %w[USD EUR GBP].freeze
  end
  ```

---

## 📚 Working with Collections

* Prefer Ruby enumerables to loops:
  ```ruby
  # Good
  squares = numbers.select(&:positive?).map { |x| x**2 }

  # Avoid
  squares = []
  numbers.each do |x|
    squares << x**2 if x.positive?
  end
  ```

* Use correct methods:
  - `map` for transformations
  - `select`/`reject` for filtering
  - `reduce` for aggregations
  - `any?`/`all?`/`none?` for checks
  - `find`/`detect` for single item
  - `pluck` for ActiveRecord column values

* **Never mutate collections during iteration**
* Use `each_with_index` instead of manual counter
* Use `zip` for parallel iteration
* Prefer symbol-to-proc: `&:method_name` when possible

---

## 🚀 Performance Guidelines

* **No premature optimization**—measure first with `benchmark` or `rack-mini-profiler`
* Cache expensive operations:
  ```ruby
  # Rails fragment caching
  def expensive_calculation
    Rails.cache.fetch("calculation_#{id}", expires_in: 1.hour) do
      # expensive operation
    end
  end

  # Memoization
  def user_count
    @user_count ||= User.count
  end
  ```

* **Avoid N+1 queries** — use `includes`, `eager_load`, or `preload`:
  ```ruby
  # Bad
  users.each { |user| puts user.posts.count }

  # Good
  users.includes(:posts).each { |user| puts user.posts.size }
  ```

* Use `find_each` or `in_batches` for large datasets
* Use database indexes on frequently queried columns
* Use `select` to load only needed columns
* Use background jobs (Sidekiq) for slow operations
* Use `pluck` instead of `map` for single columns

---

## 🔐 Security Best Practices

* Never hardcode secrets — use Rails credentials or ENV variables
* Use strong parameters in controllers:
  ```ruby
  def user_params
    params.require(:user).permit(:email, :name)
  end
  ```
* Sanitize user inputs
* Use parameterized queries (ActiveRecord does this automatically)
* Protect against mass assignment with `attr_accessible` or strong params
* Enable CSRF protection (Rails default)
* Use `SecureRandom` for tokens
* Audit dependencies with `bundle audit`

---

## 🌿 Git & Version Control

* **Atomic commits**—one commit = one logical change
* Commit messages in **imperative mood**: "Add feature" NOT "Added feature"
* Message format:
  ```
  Short summary (50 chars max)

  Detailed explanation if needed (wrap at 72 chars)
  - Bullet points for multiple changes
  - Reference issue numbers: #123
  ```

* **Never commit**:
  - Commented-out code
  - Debug statements (`puts`, `binding.pry`)
  - Personal TODO comments
  - Generated files (`tmp/`, `log/`)
  - Secrets or credentials

* Use `.gitignore` properly
* Branch naming: `feature/`, `bugfix/`, `hotfix/` prefixes
* Squash commits before merging to main

---

## 💎 Ruby Idioms & Best Practices

### Prefer Ruby Idioms
```ruby
# Good - Ruby way
return unless valid?
return if empty?
result = value || default
hash[:key] ||= []

# Avoid - verbose
return if !valid?
return if empty? == true
result = value ? value : default
hash[:key] = [] if hash[:key].nil?
```

### Use Blocks Effectively
```ruby
# Good
File.open('file.txt') do |f|
  f.read
end

# Good - custom blocks
def with_logging
  Rails.logger.info "Starting"
  result = yield
  Rails.logger.info "Finished"
  result
end
```

### Symbol vs String
```ruby
# Use symbols for keys and identifiers
user = { name: 'John', email: 'john@example.com' }

# Use strings for user data
message = "Hello, #{user[:name]}"
```

### Safe Navigation Operator
```ruby
# Use &. for potential nil values
user&.email&.downcase

# But prefer explicit checks for required data
raise "User required" unless user
email = user.email.downcase
```

---

## 📦 Deliverables

* Clean, modular code following Rails conventions
* Comprehensive documentation for public APIs (YARD)
* 90%+ test coverage via RSpec + SimpleCov
* Fully linted with RuboCop (≥ 90 score)
* Strong parameters and security best practices
* Structured logging and clean error handling
* Code structured around services, not fat controllers
* English-only code comments and docs
