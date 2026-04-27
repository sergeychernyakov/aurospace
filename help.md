# Help — шпаргалка для live coding

Готовые конструкции на копипаст: Ruby, Rails, SQL, JavaScript, React.

---

## Ruby

### Строки

```ruby
name = 'world'
"Hello, #{name}!"           # интерполяция (только в "")
'не интерполируется #{x}'   # одинарные кавычки = literal

s = 'hello world'
s.upcase                    # "HELLO WORLD"
s.downcase
s.capitalize                # "Hello world"
s.length                    # 11
s.reverse
s.include?('world')         # true
s.start_with?('he')         # true
s.end_with?('ld')
s.split(' ')                # ["hello", "world"]
s.gsub('l', 'L')            # глобальная замена
s.sub('l', 'L')             # только первое
s.strip                     # обрезает пробелы
s.chars                     # ['h','e','l',...]
s.to_i; s.to_f; s.to_sym
"%-10s %5d" % ['name', 42]  # форматирование

# heredoc
text = <<~HEREDOC
  Многострочный текст
  с интерполяцией #{name}
HEREDOC
```

### Массивы

```ruby
a = [1, 2, 3, 4, 5]
a = Array.new(5, 0)         # [0,0,0,0,0]
a = (1..5).to_a             # [1,2,3,4,5]

a.first; a.last
a.first(2)                  # [1, 2]
a[0]; a[-1]
a[1..3]                     # [2,3,4] — диапазон
a[1, 2]                     # [2,3] — start, length

a << 6                      # push
a.push(6, 7)
a.pop                       # с конца
a.shift                     # с начала
a.unshift(0)                # в начало
a.delete(3)                 # удалить значение
a.delete_at(0)              # удалить по индексу
a.compact                   # убрать nil
a.uniq                      # уникальные
a.flatten                   # [[1],[2,[3]]] -> [1,2,3]
a.reverse
a.sort
a.sort_by { |x| -x }
a.min; a.max
a.sum
a.size; a.length; a.count

a.include?(3)
a.empty?; a.any?; a.all? { |x| x > 0 }
a.find { |x| x > 3 }        # первый подходящий (alias: detect)
a.index(3)                  # индекс элемента

a + [6]                     # [1,2,3,4,5,6]
a - [2]                     # [1,3,4,5]
a & [3,4,99]                # пересечение [3,4]
a | [4,5,6]                 # объединение [1,2,3,4,5,6]
a.concat([6, 7])            # in-place

a.zip([10, 20, 30])         # [[1,10],[2,20],[3,30]]
[1,2,3].partition(&:odd?)   # [[1,3], [2]]
a.each_slice(2).to_a        # [[1,2],[3,4],[5]]
a.each_cons(2).to_a         # [[1,2],[2,3],[3,4],[4,5]]
a.chunk_while { |i,j| j-i==1 }.to_a # последовательные
```

### Enumerable (must-know)

```ruby
[1,2,3].map { |x| x * 2 }        # [2,4,6]
[1,2,3].select { |x| x.odd? }    # [1,3]
[1,2,3].reject { |x| x.odd? }    # [2]
[1,2,3].reduce(0) { |sum, x| sum + x }     # 6
[1,2,3].reduce(:+)                          # 6
[1,2,3].sum                                 # 6

users.group_by { |u| u[:role] }
users.group_by(&:role)

words = %w[apple banana cherry apple]
words.tally                                 # {"apple"=>2, "banana"=>1, "cherry"=>1}

[1,2,3].each_with_index { |x, i| puts "#{i}: #{x}" }
[1,2,3].each_with_object([]) { |x, acc| acc << x*2 }
[1,2,3].flat_map { |x| [x, x*10] }          # [1,10,2,20,3,30]
[1,2,3].min_by { |x| -x }
[1,2,3].max_by { |x| x }
[1,2,3].sort_by { |x| [x.even? ? 1 : 0, x] }
[1,2,3,4].partition(&:even?)                # [[2,4],[1,3]]
```

### Хеши

```ruby
h = { name: 'Sergey', age: 30 }
h = Hash.new(0)             # default value
h['x'] += 1                 # без падения

h[:name]                    # "Sergey"
h.fetch(:name)              # raise, если нет
h.fetch(:name, 'default')
h.dig(:user, :address, :city) # безопасно для вложенных

h.keys; h.values
h.size; h.empty?; h.any?
h.has_key?(:name); h.key?(:name)
h.has_value?('Sergey')

h.merge(role: 'admin')      # новый хеш
h.merge!(role: 'admin')     # in-place
h.delete(:age)
h.except(:age)              # Rails / Ruby 3.0+
h.slice(:name)              # только указанные ключи
h.transform_keys(&:to_s)
h.transform_values { |v| v.to_s }
h.invert                    # ключи и значения местами

h.each { |k, v| puts "#{k}=#{v}" }
h.map { |k, v| [k, v.to_s] }.to_h
h.select { |_, v| v.is_a?(String) }
h.group_by { |k, v| v.class }

# деструктуризация
name, age = h.values_at(:name, :age)
```

### Условия

```ruby
if x > 0
  'positive'
elsif x < 0
  'negative'
else
  'zero'
end

return :err if invalid?
return :ok unless invalid?
puts 'big' if x > 100

# ternary
x > 0 ? 'positive' : 'non-positive'

# case/when
case status
when 'created', 'pending' then handle_new
when 'successful'         then handle_success
when /^err_/              then handle_error
when 100..199             then :informational
else                            handle_unknown
end

# pattern matching (Ruby 3+)
case payload
in { event: 'payment.succeeded', object: { id: String => id } }
  process(id)
in { event: String => other }
  log("unknown: #{other}")
end
```

### Циклы

```ruby
5.times { |i| puts i }              # 0..4
1.upto(5) { |i| puts i }
5.downto(1) { |i| puts i }
(1..5).each { |i| puts i }
(1...5).each { |i| puts i }         # без 5

while x < 10 do x += 1 end
until x >= 10 do x += 1 end

loop do
  break if done?
  next if skip?
end

# Enumerable вместо while почти всегда лучше
```

### Методы

```ruby
def greet(name = 'world')
  "Hello, #{name}"
end

def total(*nums)                   # splat
  nums.sum
end
total(1, 2, 3)

def call(user_id:, amount_cents:)  # keyword args
  ...
end
call(user_id: 1, amount_cents: 100)

def options(**opts)                 # keyword splat
  opts[:foo]
end

def perform(&block)                 # принять блок
  block.call(42)
end
perform { |x| puts x }

def yielder
  yield(42) if block_given?
end

# несколько возвращаемых
def split_name(s)
  s.split(' ')
end
first, last = split_name('John Doe')
```

### Классы

```ruby
class User
  attr_accessor :name              # геттер + сеттер
  attr_reader :email               # только геттер
  attr_writer :password            # только сеттер

  def initialize(name:, email:)
    @name = name
    @email = email
  end

  def to_s
    "#{@name} <#{@email}>"
  end

  def self.find_by_email(email)    # классовый метод
    # ...
  end

  private

  def hash_password(p)
    Digest::SHA256.hexdigest(p)
  end
end

u = User.new(name: 'A', email: 'a@b.c')
u.name = 'B'

# Наследование
class Admin < User
  def initialize(name:, email:, level:)
    super(name: name, email: email)
    @level = level
  end
end

# Модули (mixin)
module Greetable
  def greet
    "Hello, #{name}"
  end
end

class User
  include Greetable                # instance methods
  extend Greetable                 # class methods
end

# Структуры (быстрый value-object)
Point = Struct.new(:x, :y) do
  def distance
    Math.sqrt(x**2 + y**2)
  end
end
p = Point.new(3, 4)

# Data (Ruby 3.2+, immutable)
Coord = Data.define(:x, :y)
c = Coord.new(x: 1, y: 2)
```

### Блоки, Proc, Lambda

```ruby
# Блок
[1,2,3].each { |x| puts x }
[1,2,3].each do |x|
  puts x
end

# Proc
double = Proc.new { |x| x * 2 }
double = proc { |x| x * 2 }
double.call(5)                     # 10
double.(5); double[5]              # тот же call

# Lambda — строгая по аргументам
sq = ->(x) { x * x }
sq = lambda { |x| x * x }
sq.call(4)                          # 16

# Symbol#to_proc
[1,2,3].map(&:to_s)
users.map(&:email)
```

### Исключения

```ruby
begin
  do_risky
rescue ArgumentError => e
  puts "arg: #{e.message}"
rescue StandardError => e
  puts "other: #{e.message}"
ensure
  cleanup
end

# raise
raise ArgumentError, "bad: #{x}"
raise MyError.new("…") if invalid?

# своё исключение
class PaymentError < StandardError; end
class InsufficientFunds < PaymentError; end
```

### Regex

```ruby
'hello'.match?(/^h/)               # true
'abc123' =~ /\d+/                  # 3 (индекс)
'abc123'.match(/(\d+)/)[1]         # "123"
'abc 123 xyz 456'.scan(/\d+/)      # ["123","456"]
'hello'.gsub(/l/, 'L')
'hello'.sub(/(.)l/) { $1.upcase + 'l' }
```

### File / IO

```ruby
File.read('a.txt')
File.readlines('a.txt')
File.write('b.txt', 'data')
File.open('a.txt', 'r') { |f| f.each_line { |l| puts l } }
File.exist?('a.txt')
JSON.parse(File.read('config.json'))
JSON.generate(data)
```

---

## Rails

### Migration

```ruby
# db/migrate/20260101000000_create_orders.rb
class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string  :currency, null: false, default: 'RUB'
      t.integer :status, null: false, default: 0
      t.datetime :paid_at
      t.datetime :cancelled_at
      t.timestamps
    end

    add_index :orders, :status
    add_index :orders, [:user_id, :status]
    add_index :orders, :external_payment_id, unique: true
  end
end

# add_column / remove_column / change_column
add_column :users, :phone, :string, null: true
remove_column :users, :phone, :string
add_index :users, :email, unique: true
```

### Model

```ruby
class Order < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :ledger_entries, dependent: :restrict_with_error
  has_many :items, dependent: :destroy
  has_one :invoice
  has_and_belongs_to_many :tags
  has_many :reviews, through: :items

  # Validations
  validates :amount_cents, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: %w[created successful cancelled] }
  validates :slug, uniqueness: { scope: :user_id }

  # Enum (Rails 7+)
  enum :status, { created: 0, payment_pending: 1, successful: 2, cancelled: 3 }

  # Scopes
  scope :recent, -> { where('created_at > ?', 7.days.ago) }
  scope :by_user, ->(user) { where(user: user) }
  scope :stale_pending, ->(threshold = 30.minutes) {
    where(status: :payment_pending).where(updated_at: ...threshold.ago)
  }

  # Callbacks
  before_validation :normalize_email
  before_save :calculate_total
  after_create :send_welcome
  after_commit :index_for_search, on: :create

  # Delegation
  delegate :name, :email, to: :user, prefix: true

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end
end
```

### Запросы (ActiveRecord)

```ruby
User.find(1)                           # raise если нет
User.find_by(email: 'a@b.c')           # nil если нет
User.find_by!(email: 'a@b.c')          # raise

User.where(active: true)
User.where('age > ?', 18)
User.where(status: [:created, :pending])
User.where.not(status: :cancelled)
User.where('email LIKE ?', '%@gmail.com')

User.order(created_at: :desc).limit(10).offset(20)
User.first; User.last
User.first(5)
User.pluck(:id, :email)                # [[1,'a@b.c'], ...]
User.ids                               # [1,2,3]
User.distinct.pluck(:country)
User.exists?(email: 'x')

# Aggregates
Order.count
Order.sum(:amount_cents)
Order.average(:amount_cents)
Order.minimum(:amount_cents)
Order.group(:status).count
Order.group(:user_id).sum(:amount_cents)
Order.group('DATE(created_at)').count

# Joins / includes (N+1 fix)
Order.includes(:user).where(users: { active: true })
Order.joins(:user).where(users: { country: 'US' })
Order.left_joins(:reviews).where(reviews: { id: nil })
Order.preload(:items)                  # отдельный запрос
Order.eager_load(:items)               # один LEFT JOIN

# Batches
Order.find_each(batch_size: 1000) { |o| ... }
Order.in_batches(of: 1000) { |relation| relation.update_all(...) }

# Bulk
Order.insert_all([{...}, {...}])       # без коллбэков
Order.upsert_all([{...}], unique_by: :external_id)
Order.where(status: :pending).update_all(status: :cancelled)

# Locks
order.with_lock { ... }                # блокировка + транзакция
order.lock!                            # SELECT FOR UPDATE (внутри транзакции)
Order.lock.find(1)

# Transaction
ActiveRecord::Base.transaction do
  order.save!
  ledger_entry.save!
  raise ActiveRecord::Rollback if condition
end
```

### Controller (RESTful)

```ruby
class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: %i[show edit update destroy]

  def index
    @orders = current_user.orders.includes(:items).page(params[:page])
  end

  def show
  end

  def new
    @order = Order.new
  end

  def create
    @order = current_user.orders.build(order_params)
    if @order.save
      redirect_to @order, notice: t('orders.created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @order.update(order_params)
      redirect_to @order, notice: t('orders.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order.destroy
    redirect_to orders_path, notice: t('orders.deleted')
  end

  private

  def set_order
    @order = current_user.orders.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:amount_cents, :currency, items_attributes: [:id, :name, :_destroy])
  end
end
```

### Routes

```ruby
Rails.application.routes.draw do
  root 'home#index'

  resources :orders                                       # 7 RESTful actions
  resources :orders, only: [:index, :show]
  resources :orders, except: [:destroy]

  resources :orders do
    member do
      post :cancel                                        # /orders/:id/cancel
      patch :pay
    end
    collection do
      get :search                                         # /orders/search
    end
    resources :items, only: [:index, :create]             # nested
  end

  namespace :admin do
    resources :users
  end

  scope '/api' do
    resources :webhooks, only: :create
  end

  namespace :api do
    namespace :v1 do
      resources :users, only: [:index, :show]
    end
  end

  get '/about', to: 'pages#about', as: :about
  match '/health', to: 'health#show', via: :all

  # Constraints
  resources :orders, constraints: { id: /\d+/ }

  # Devise
  devise_for :users
  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end
end
```

### View / ERB / Helpers

```erb
<%= link_to 'Cancel', cancel_order_path(@order), method: :post, data: { turbo_confirm: 'Sure?' }, class: 'btn' %>
<%= form_with model: @order, local: true do |f| %>
  <div class="field">
    <%= f.label :amount_cents %>
    <%= f.number_field :amount_cents, required: true %>
    <%= f.error_message :amount_cents %>
  </div>
  <%= f.select :currency, [['Ruble','RUB'], ['Euro','EUR']] %>
  <%= f.submit class: 'btn cursor-pointer' %>
<% end %>

<% @orders.each do |order| %>
  <%= render order %>
<% end %>

<%= render partial: 'order', collection: @orders %>

<%= number_to_currency(amount, unit: '₽') %>
<%= time_ago_in_words(@order.created_at) %>
<%= l(@order.created_at, format: :short) %>            # I18n
<%= t('orders.title') %>

<% if @order.successful? %>
  <span class="badge">Paid</span>
<% end %>
```

### Service object

```ruby
# app/services/orders/create.rb
module Orders
  class Create
    include Dry::Monads[:result]

    def call(user:, amount_cents:, currency: 'RUB')
      return Failure(:invalid_amount) unless amount_cents.positive?

      ActiveRecord::Base.transaction do
        order = Order.create!(user: user, amount_cents: amount_cents, currency: currency)
        Accounts::ApplyLedgerEntry.new.call(
          account: user.account, order: order,
          entry_type: :debit, amount_cents: amount_cents,
        ).value!
        Success(order)
      end
    rescue ActiveRecord::RecordInvalid => e
      Failure([:validation, e.record.errors])
    end
  end
end

# Использование
result = Orders::Create.new.call(user: current_user, amount_cents: 1000)
result.success? ? result.value! : handle_error(result.failure)
```

### Background job

```ruby
class SendOrderEmailJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  def perform(order_id, template)
    order = Order.find(order_id)
    OrderMailer.with(order: order).public_send(template).deliver_now
  end
end

SendOrderEmailJob.perform_later(order.id, 'cancelled')
SendOrderEmailJob.set(wait: 5.minutes).perform_later(order.id, 'reminder')
```

### Mailer

```ruby
class OrderMailer < ApplicationMailer
  default from: 'noreply@example.com'

  def cancelled
    @order = params[:order]
    mail(to: @order.user.email, subject: t('mailer.cancelled.subject'))
  end
end

OrderMailer.with(order: @order).cancelled.deliver_later
```

### RSpec — request, model, service

```ruby
# spec/models/order_spec.rb
RSpec.describe Order, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:amount_cents) }
    it { is_expected.to validate_numericality_of(:amount_cents).is_greater_than(0) }
  end

  describe '.stale_pending' do
    let!(:fresh) { create(:order, status: :payment_pending, updated_at: 1.minute.ago) }
    let!(:stale) { create(:order, status: :payment_pending, updated_at: 1.hour.ago) }

    it 'returns only stale orders' do
      expect(Order.stale_pending).to contain_exactly(stale)
    end
  end
end

# spec/requests/orders_spec.rb
RSpec.describe 'Orders', type: :request do
  let(:user) { create(:user) }
  before { sign_in user }

  describe 'POST /orders' do
    context 'with valid params' do
      let(:params) { { order: { amount_cents: 1000, currency: 'RUB' } } }

      it 'creates an order' do
        expect { post orders_path, params: params }.to change(Order, :count).by(1)
        expect(response).to redirect_to(order_path(Order.last))
      end
    end

    context 'with invalid params' do
      it 'renders new' do
        post orders_path, params: { order: { amount_cents: 0 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end

# spec/services/orders/create_spec.rb
RSpec.describe Orders::Create do
  subject(:result) { described_class.new.call(user: user, amount_cents: 1000) }
  let(:user) { create(:user, :with_account) }

  it 'returns Success with order' do
    expect(result).to be_success
    expect(result.value!).to be_a(Order)
  end

  it 'creates ledger entry' do
    expect { result }.to change(LedgerEntry, :count).by(1)
  end
end
```

### FactoryBot

```ruby
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { 'Test User' }

    trait :with_account do
      after(:create) { |u| create(:account, user: u) }
    end
  end

  factory :order do
    user
    amount_cents { 1000 }
    currency     { 'RUB' }
    status       { :created }
  end
end

create(:user, :with_account)
build(:order, amount_cents: 5000)
create_list(:order, 3, user: user)
```

---

## SQL

### SELECT / WHERE

```sql
SELECT id, email, created_at FROM users;
SELECT * FROM users WHERE active = TRUE AND age >= 18;
SELECT * FROM users WHERE country IN ('US', 'CA', 'GB');
SELECT * FROM users WHERE created_at BETWEEN '2025-01-01' AND '2025-12-31';
SELECT * FROM users WHERE email LIKE '%@gmail.com';
SELECT * FROM users WHERE email ILIKE '%@GMAIL.com';   -- PG, без регистра
SELECT * FROM users WHERE deleted_at IS NULL;
SELECT * FROM users WHERE name ~ '^A';                  -- PG regex

SELECT DISTINCT country FROM users;
SELECT * FROM users ORDER BY created_at DESC, id ASC;
SELECT * FROM users LIMIT 10 OFFSET 20;
```

### JOIN

```sql
SELECT u.email, o.amount_cents
FROM users u
INNER JOIN orders o ON o.user_id = u.id;

SELECT u.email, COALESCE(SUM(o.amount_cents), 0) AS total
FROM users u
LEFT JOIN orders o ON o.user_id = u.id AND o.status = 'successful'
GROUP BY u.id, u.email;

-- Anti-join (юзеры без заказов)
SELECT u.*
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE o.id IS NULL;

-- Self-join (иерархия)
SELECT e.name, m.name AS manager
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id;
```

### GROUP BY / HAVING / агрегаты

```sql
SELECT user_id, COUNT(*) AS orders, SUM(amount_cents) AS total
FROM orders
WHERE status = 'successful'
GROUP BY user_id
HAVING COUNT(*) > 5
ORDER BY total DESC
LIMIT 10;

SELECT
  COUNT(*) AS total,
  COUNT(DISTINCT user_id) AS users,
  AVG(amount_cents) AS avg_amt,
  MIN(created_at), MAX(created_at)
FROM orders;
```

### Subquery / EXISTS

```sql
SELECT * FROM users
WHERE id IN (SELECT user_id FROM orders WHERE status = 'successful');

SELECT * FROM users u
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id AND o.amount_cents > 10000);

SELECT *,
  (SELECT COUNT(*) FROM orders o WHERE o.user_id = u.id) AS orders_count
FROM users u;
```

### CTE (WITH)

```sql
WITH recent_orders AS (
  SELECT * FROM orders WHERE created_at > NOW() - INTERVAL '30 days'
),
totals AS (
  SELECT user_id, SUM(amount_cents) AS total
  FROM recent_orders
  GROUP BY user_id
)
SELECT u.email, t.total
FROM users u
JOIN totals t ON t.user_id = u.id
WHERE t.total > 100000
ORDER BY t.total DESC;

-- Recursive CTE (категории/дерево)
WITH RECURSIVE tree AS (
  SELECT id, parent_id, name, 0 AS depth
  FROM categories WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, c.parent_id, c.name, t.depth + 1
  FROM categories c JOIN tree t ON c.parent_id = t.id
)
SELECT * FROM tree ORDER BY depth, name;
```

### Window functions

```sql
-- Нумерация заказов внутри пользователя
SELECT id, user_id, amount_cents,
       ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at)  AS n,
       RANK()       OVER (PARTITION BY user_id ORDER BY amount_cents DESC) AS rk,
       SUM(amount_cents) OVER (PARTITION BY user_id) AS user_total,
       LAG(amount_cents)  OVER (PARTITION BY user_id ORDER BY created_at) AS prev_amt,
       LEAD(amount_cents) OVER (PARTITION BY user_id ORDER BY created_at) AS next_amt
FROM orders;

-- Топ-3 заказа на пользователя
SELECT * FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount_cents DESC) AS rn
  FROM orders
) ranked
WHERE rn <= 3;
```

### INSERT / UPDATE / DELETE

```sql
INSERT INTO users (email, name) VALUES ('a@b.c', 'A');
INSERT INTO users (email, name) VALUES ('a@b.c', 'A'), ('x@y.z', 'X');
INSERT INTO users (email, name) VALUES ('a@b.c', 'A')
  ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO users (email) VALUES ('a@b.c') ON CONFLICT DO NOTHING;

UPDATE orders SET status = 'cancelled', cancelled_at = NOW()
WHERE id = 42;

UPDATE accounts SET balance_cents = balance_cents + 1000
WHERE id = 1;                                -- атомарный инкремент

DELETE FROM orders WHERE created_at < NOW() - INTERVAL '1 year';
TRUNCATE TABLE logs RESTART IDENTITY;
```

### Transactions / locks (PostgreSQL)

```sql
BEGIN;
SELECT * FROM accounts WHERE id = 1 FOR UPDATE;     -- pessimistic lock
UPDATE accounts SET balance_cents = balance_cents - 100 WHERE id = 1;
UPDATE accounts SET balance_cents = balance_cents + 100 WHERE id = 2;
COMMIT;
-- ROLLBACK;
```

### Indexes

```sql
CREATE INDEX idx_orders_status ON orders (status);
CREATE INDEX idx_orders_user_status ON orders (user_id, status);
CREATE UNIQUE INDEX idx_users_email ON users (LOWER(email));
CREATE INDEX idx_orders_paid ON orders (paid_at) WHERE status = 'successful';  -- partial
CREATE INDEX idx_users_email_trgm ON users USING gin (email gin_trgm_ops);     -- LIKE поиск
```

### Полезное

```sql
-- Дедупликация
DELETE FROM orders a
USING orders b
WHERE a.id > b.id AND a.external_id = b.external_id;

-- Топ-N с тай-брейком
SELECT * FROM users ORDER BY score DESC, created_at ASC LIMIT 10;

-- Pivot вручную
SELECT
  user_id,
  COUNT(*) FILTER (WHERE status = 'created')    AS created,
  COUNT(*) FILTER (WHERE status = 'successful') AS successful,
  COUNT(*) FILTER (WHERE status = 'cancelled')  AS cancelled
FROM orders GROUP BY user_id;

-- EXPLAIN
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 1;
```

---

## JavaScript

### Переменные / типы

```js
const x = 1;            // immutable binding
let y = 2;              // изменяемая
// var — не используй

typeof 'a';             // 'string'
Array.isArray([1,2]);   // true
```

### Строки

```js
const name = 'world';
`Hello, ${name}!`;                       // template literal
'abc'.length;
'abc'.includes('b');
'abc'.startsWith('a'); 'abc'.endsWith('c');
'a,b,c'.split(',');
[1,2,3].join('-');
'  abc  '.trim();
'abc'.repeat(3);
'abc'.padStart(5, '0');                  // "00abc"
'AbC'.toLowerCase(); 'abc'.toUpperCase();
'abc'.replace(/b/, 'B');
'abc'.replaceAll('a', 'A');
```

### Массивы

```js
const a = [1, 2, 3];
a.length;
a[0]; a.at(-1);                          // последний

a.push(4); a.pop();
a.unshift(0); a.shift();
a.slice(1, 3);                           // копия [1,3)
a.splice(1, 2);                          // in-place
[...a, 4, 5];                            // spread
a.concat([4, 5]);

a.includes(2);
a.indexOf(2); a.lastIndexOf(2);
a.find(x => x > 1);
a.findIndex(x => x > 1);
a.some(x => x > 2);
a.every(x => x > 0);

a.map(x => x * 2);
a.filter(x => x > 1);
a.reduce((acc, x) => acc + x, 0);
a.reduceRight(...);
a.flat();
a.flatMap(x => [x, x*10]);
a.sort((x, y) => x - y);                 // numeric
a.reverse();

Array.from({length: 5}, (_, i) => i);    // [0,1,2,3,4]
Array.of(1, 2, 3);
Array(5).fill(0);

// destructuring
const [first, second, ...rest] = [1,2,3,4,5];
```

### Объекты

```js
const user = { name: 'A', age: 30 };
user.name; user['name'];

Object.keys(user);
Object.values(user);
Object.entries(user);                    // [['name','A'], ['age',30]]
Object.fromEntries([['a', 1], ['b', 2]]);

// spread / merge
const merged = { ...user, role: 'admin' };
const { name, ...rest } = user;          // destructuring

// shorthand
const make = (name, age) => ({ name, age });

// computed key
const key = 'foo';
const obj = { [key]: 'bar' };

// optional chaining + nullish
user?.address?.city ?? 'unknown';
```

### Функции

```js
function greet(name = 'world') {
  return `Hello, ${name}`;
}

const greet = (name = 'world') => `Hello, ${name}`;
const sum = (...nums) => nums.reduce((a, b) => a + b, 0);

const fetchUser = async (id) => {
  const res = await fetch(`/users/${id}`);
  if (!res.ok) throw new Error('failed');
  return res.json();
};
```

### Классы

```js
class User {
  static count = 0;
  #password;                              // private field

  constructor(name, password) {
    this.name = name;
    this.#password = password;
    User.count++;
  }

  greet() {
    return `Hello, ${this.name}`;
  }

  get displayName() { return this.name.toUpperCase(); }
  set displayName(v) { this.name = v; }

  static fromJSON(json) {
    return new User(json.name, json.password);
  }
}

class Admin extends User {
  constructor(name, password, level) {
    super(name, password);
    this.level = level;
  }
}
```

### Циклы

```js
for (let i = 0; i < 5; i++) { ... }
for (const x of [1,2,3]) { ... }         // values
for (const k in obj) { ... }             // keys (с учётом prototype, осторожно)
arr.forEach(x => console.log(x));

while (cond) { ... }
do { ... } while (cond);
```

### Async / Promise / fetch

```js
// Promise
new Promise((resolve, reject) => {
  setTimeout(() => resolve(42), 1000);
});

fetch('/api/users')
  .then(r => r.json())
  .then(data => console.log(data))
  .catch(err => console.error(err));

// async/await
async function load() {
  try {
    const res = await fetch('/api/users');
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    return data;
  } catch (err) {
    console.error(err);
    return [];
  }
}

// параллельно
const [users, orders] = await Promise.all([
  fetch('/users').then(r => r.json()),
  fetch('/orders').then(r => r.json()),
]);

await Promise.allSettled([p1, p2, p3]);
```

### Map / Set

```js
const m = new Map();
m.set('a', 1); m.get('a'); m.has('a'); m.delete('a');
m.size;
for (const [k, v] of m) { ... }

const s = new Set([1,2,2,3]);            // {1,2,3}
s.add(4); s.has(2); s.delete(1); s.size;
[...s];                                   // в массив
```

### Modules

```js
// utils.js
export const sum = (a, b) => a + b;
export default function greet() { ... }

// app.js
import greet, { sum } from './utils.js';
import * as utils from './utils.js';
```

---

## React

### Function component

```jsx
function Greeting({ name = 'world', children }) {
  return (
    <div className="greeting">
      <h1>Hello, {name}!</h1>
      {children}
    </div>
  );
}

// usage
<Greeting name="Sergey">
  <p>nested</p>
</Greeting>
```

### useState

```jsx
import { useState } from 'react';

function Counter() {
  const [count, setCount] = useState(0);

  return (
    <button onClick={() => setCount(c => c + 1)} className="cursor-pointer">
      {count}
    </button>
  );
}

// объект-стейт — обязательно spread (или несколько useState)
const [form, setForm] = useState({ name: '', email: '' });
setForm(f => ({ ...f, name: 'A' }));
```

### useEffect

```jsx
import { useEffect, useState } from 'react';

function UserList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    fetch('/api/users')
      .then(r => r.json())
      .then(data => { if (!cancelled) setUsers(data); })
      .finally(() => { if (!cancelled) setLoading(false); });

    return () => { cancelled = true; };          // cleanup
  }, []);                                          // [] — один раз

  if (loading) return <p>Loading…</p>;
  return (
    <ul>
      {users.map(u => <li key={u.id}>{u.email}</li>)}
    </ul>
  );
}
```

### Условный рендер / списки

```jsx
{user ? <Profile user={user} /> : <Login />}
{isAdmin && <AdminBar />}
{error && <p className="error">{error}</p>}

<ul>
  {items.map(item => (
    <li key={item.id}>{item.name}</li>          // key обязательно
  ))}
</ul>
```

### Формы (controlled)

```jsx
function OrderForm() {
  const [form, setForm] = useState({ amount: '', currency: 'RUB' });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm(f => ({ ...f, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const res = await fetch('/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(form),
    });
    if (res.ok) { /* redirect */ }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input name="amount" value={form.amount} onChange={handleChange} required />
      <select name="currency" value={form.currency} onChange={handleChange}>
        <option value="RUB">RUB</option>
        <option value="EUR">EUR</option>
      </select>
      <button type="submit" className="cursor-pointer">Save</button>
    </form>
  );
}
```

### useMemo / useCallback / useRef

```jsx
import { useMemo, useCallback, useRef } from 'react';

const total = useMemo(() => orders.reduce((s, o) => s + o.amount, 0), [orders]);

const onSelect = useCallback((id) => setSelected(id), []);

const inputRef = useRef(null);
useEffect(() => { inputRef.current?.focus(); }, []);

return <input ref={inputRef} />;
```

### Custom hook

```jsx
function useFetch(url) {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    fetch(url)
      .then(r => r.ok ? r.json() : Promise.reject(r.status))
      .then(d => { if (!cancelled) setData(d); })
      .catch(e => { if (!cancelled) setError(e); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [url]);

  return { data, error, loading };
}

// использование
const { data: users, loading } = useFetch('/api/users');
```

### Context

```jsx
import { createContext, useContext, useState } from 'react';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  return (
    <AuthContext.Provider value={{ user, setUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);

// в компоненте
const { user, setUser } = useAuth();
```

### useReducer

```jsx
function reducer(state, action) {
  switch (action.type) {
    case 'add':    return { count: state.count + 1 };
    case 'reset':  return { count: 0 };
    default:       throw new Error(`unknown ${action.type}`);
  }
}

const [state, dispatch] = useReducer(reducer, { count: 0 });
<button onClick={() => dispatch({ type: 'add' })}>+</button>
```

### React Router (v6+)

```jsx
import { BrowserRouter, Routes, Route, Link, useParams, useNavigate } from 'react-router-dom';

<BrowserRouter>
  <Routes>
    <Route path="/" element={<Home />} />
    <Route path="/orders" element={<Orders />} />
    <Route path="/orders/:id" element={<OrderShow />} />
    <Route path="*" element={<NotFound />} />
  </Routes>
</BrowserRouter>

function OrderShow() {
  const { id } = useParams();
  const navigate = useNavigate();
  return <button onClick={() => navigate('/orders')}>Back</button>;
}
```

### Тесты (RTL)

```jsx
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('increments on click', async () => {
  render(<Counter />);
  const btn = screen.getByRole('button', { name: /0/ });
  await userEvent.click(btn);
  expect(screen.getByRole('button')).toHaveTextContent('1');
});
```
