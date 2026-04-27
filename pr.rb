# bundle exec rails runner pr.rb 

def section(title)
  puts
  puts '=' * 70
  puts "  #{title}"
  puts '=' * 70
end


##### 1. Сумма успешных заказов

orders = [
  { id: 1, status: 'successful', amount_cents: 1000 },
  { id: 2, status: 'cancelled',  amount_cents: 500 },
  { id: 3, status: 'successful', amount_cents: 2500 }
]

def successful_total(orders)
  orders
    .select { |order| order[:status] == 'successful' }
    .sum    { |order| order[:amount_cents] }
end

section '1. Сумма успешных заказов'
puts successful_total(orders) # => 3500


##### 2. Сгруппировать заказы по статусу

def group_orders_by_status(orders)
  orders.group_by { |order| order[:status] }
end

# Чуть более руками
def group_orders_by_status_manual(orders)
  orders.each_with_object({}) do |order, result|
    status = order[:status]
    result[status] ||= []
    result[status] << order
  end
end

section '2. Сгруппировать заказы по статусу'
p group_orders_by_status(orders)
p group_orders_by_status_manual(orders)


##### 3. Уникальные webhook events по external_event_id (оставить первое вхождение)

events_with_payload = [
  { external_event_id: 'a1', payload: 'x' },
  { external_event_id: 'a2', payload: 'y' },
  { external_event_id: 'a1', payload: 'z' }
]

def unique_events(events)
  seen = {}
  events.select do |event|
    event_id = event[:external_event_id]
    next false if seen[event_id]
    seen[event_id] = true
    true
  end
end

# Короче через uniq
def unique_events_short(events)
  events.uniq { |event| event[:external_event_id] }
end

section '3. Уникальные events по external_event_id'
p unique_events(events_with_payload)
p unique_events_short(events_with_payload)


##### 4. Последний заказ каждого пользователя

orders_with_time = [
  { id: 1, user_id: 1, created_at: Time.new(2025, 1, 1) },
  { id: 2, user_id: 1, created_at: Time.new(2025, 5, 1) },
  { id: 3, user_id: 2, created_at: Time.new(2025, 3, 1) },
  { id: 4, user_id: 2, created_at: Time.new(2025, 2, 1) }
]

def latest_orders_by_user(orders)
  orders.each_with_object({}) do |order, result|
    user_id = order[:user_id]
    current = result[user_id]
    if current.nil? || order[:created_at] > current[:created_at]
      result[user_id] = order
    end
  end
end

# Через group_by + max_by
def latest_orders_by_user_grouped(orders)
  orders
    .group_by         { |order| order[:user_id] }
    .transform_values { |user_orders| user_orders.max_by { |o| o[:created_at] } }
end

section '4. Последний заказ каждого пользователя'
p latest_orders_by_user(orders_with_time)
p latest_orders_by_user_grouped(orders_with_time)


##### 5. Можно ли отменить заказ

def can_cancel_order?(order)
  order[:status] == 'successful'
end

# Чуть более явно (на случай, если статусов станет больше)
def can_cancel_order_explicit?(order)
  allowed_statuses = ['successful']
  allowed_statuses.include?(order[:status])
end

section '5. Можно ли отменить заказ'
puts can_cancel_order?({ id: 1, status: 'successful' }) # => true
puts can_cancel_order?({ id: 2, status: 'cancelled'  }) # => false


##### 6. Посчитать баланс по ledger entries

entries = [
  { entry_type: 'credit',   amount_cents: 1000 },
  { entry_type: 'credit',   amount_cents: 500 },
  { entry_type: 'reversal', amount_cents: 300 },
  { entry_type: 'debit',    amount_cents: 1000 }
]

def calculate_balance(entries = [])
  entries.sum do |entry|
    case entry[:entry_type]
    when 'credit'
      entry[:amount_cents]
    when 'debit', 'reversal'
      -entry[:amount_cents]
    else
      raise ArgumentError, "Неизвестный тип: #{entry[:entry_type]}"
    end
  end
end

section '6. Баланс по ledger entries'
puts calculate_balance(entries) # => 200


##### 7. Найти дублирующиеся external_event_id

events = [
  { external_event_id: 'a1' },
  { external_event_id: 'a2' },
  { external_event_id: 'a1' },
  { external_event_id: 'a3' },
  { external_event_id: 'a2' }
]

def duplicate_event_ids_count(events)
  counts = events.each_with_object(Hash.new(0)) do |event, result|
    result[event[:external_event_id]] += 1
  end
  counts.select { |_event_id, count| count > 1 }.keys
end

def duplicate_event_ids_group(events)
  events
    .group_by { |e| e[:external_event_id] }
    .select   { |_id, group| group.size > 1 }
    .keys
end

def duplicate_event_ids_short(events)
  ids = events.map { |e| e[:external_event_id] }
  ids.uniq.select { |id| ids.count(id) > 1 }
end

section '7. Дублирующиеся external_event_id'
p duplicate_event_ids_count(events)
p duplicate_event_ids_group(events)
p duplicate_event_ids_short(events)


##### 8. Простой service object Orders::Create

module Orders
  class Create
    attr_reader :orders

    def initialize(orders:)
      @orders = orders
    end

    def call(user_id:, amount_cents:)
      return { success: false, error: :invalid_amount } unless amount_cents.positive?

      order = {
        id: next_id,
        user_id: user_id,
        amount_cents: amount_cents,
        status: 'created'
      }
      @orders << order

      { success: true, order: order }
    end

    private

    def next_id
      orders.map { |order| order[:id] }.max.to_i + 1
    end
  end
end

section '8. Service object Orders::Create'
create_service = Orders::Create.new(orders: [])
p create_service.call(user_id: 12, amount_cents: 12_300)
p create_service.orders


##### 9. Отмена успешного заказа с reversal

module Orders
  class Cancel
    def initialize(ledger_entries:)
      @ledger_entries = ledger_entries
    end

    def call(order:)
      return { success: false, error: :invalid_transition } unless order[:status] == 'successful'

      order[:status]       = 'cancelled'
      order[:cancelled_at] = Time.now

      ledger_entries << {
        order_id:     order[:id],
        entry_type:   'reversal',
        amount_cents: order[:amount_cents]
      }

      { success: true, order: order }
    end

    private

    attr_reader :ledger_entries
  end
end

section '9. Отмена заказа + reversal'
ledger = []
successful_order = { id: 1, status: 'successful', amount_cents: 5000 }
cancel_service = Orders::Cancel.new(ledger_entries: ledger)
p cancel_service.call(order: successful_order)
p ledger
p cancel_service.call(order: { id: 2, status: 'created', amount_cents: 100 })


##### 10. Идемпотентная обработка webhook

require 'set'

class ProcessWebhook
  def initialize(processed_event_ids:)
    @processed_event_ids = processed_event_ids
  end

  def call(order:, event:)
    event_id = event[:external_event_id]

    return { success: true, status: :duplicate }          if processed_event_ids.include?(event_id)
    return { success: true, status: :already_successful } if order[:status] == 'successful'

    processed_event_ids.add(event_id)
    order[:status]  = 'successful'
    order[:paid_at] = Time.now

    { success: true, status: :processed, order: order }
  end

  private

  attr_reader :processed_event_ids
end

section '10. Идемпотентная обработка webhook'
processed = Set.new
webhook_service = ProcessWebhook.new(processed_event_ids: processed)

new_order = { id: 1, status: 'created', amount_cents: 1000 }
p webhook_service.call(order: new_order, event: { external_event_id: 'evt_1' }) # :processed
p webhook_service.call(order: new_order, event: { external_event_id: 'evt_1' }) # :duplicate
p webhook_service.call(order: new_order, event: { external_event_id: 'evt_2' }) # :already_successful


############################################################
# Каверзные задачи (Rails / ActiveRecord) — на собес
# Запускать: bundle exec rails runner pr.rb
############################################################

unless defined?(Rails)
  puts
  puts '(Каверзные задачи 11–20 пропущены — нет Rails. Запусти: bundle exec rails runner pr.rb)'
  return
end


##### 11. enum: получить успешные заказы / посчитать по статусам
#
# Грабли: новички пишут Order.where(status: 2). Это работает,
# но завязано на числа. Правильно — через scope, который Rails
# сам сгенерил из enum.

section '11. enum: scope vs where(status:)'
Order.successful                    # scope, читаемо
Order.where(status: :successful)    # тоже ок (по символу)
Order.where(status: 'successful')   # тоже ок (по строке)
# Order.where(status: 2)            # хрупко, не делай так

p Order.group(:status).count        # => {"created"=>3, "successful"=>10, ...}


##### 12. N+1: сумма успешных заказов по пользователям
#
# Грабли: User.all.map { |u| u.orders.sum(:amount_cents) } — N+1.
# Решение в одну строку — agg-запрос.

section '12. N+1 — сумма по пользователям одной группировкой'
# Плохо (N+1):
# User.kept.map { |u| [u.email, u.orders.successful.sum(:amount_cents)] }

# Хорошо: одна группировка в БД
totals_by_user = Order.successful.group(:user_id).sum(:amount_cents)
p totals_by_user # => {1 => 5000, 2 => 12_300}


##### 13. Race condition: атомарное обновление баланса
#
# Грабли: read-modify-write без блокировки = потеряем апдейты
# при параллельных вызовах. Два варианта правильно:
#   а) пессимистичная блокировка (lock!/with_lock)
#   б) атомарный UPDATE в БД (update_all с выражением)

section '13. Race condition — атомарное обновление баланса'
account = Account.first
unless account
  puts '(нет Account в БД, пропускаем)'
else
  # а) Блокировка строки до конца транзакции — так делает наш ApplyLedgerEntry
  ActiveRecord::Base.transaction do
    account.lock!
    account.update!(balance_cents: account.balance_cents + 1000)
  end
  puts "после lock!:       #{account.reload.balance_cents}"

  # б) Атомарно через SQL — без загрузки/сохранения объекта
  Account.where(id: account.id).update_all('balance_cents = balance_cents + 1000')
  puts "после update_all:  #{account.reload.balance_cents}"
end


##### 14. Идемпотентность через unique-индекс + rescue
#
# Грабли:
#  - проверять "если уже есть — пропустить" двумя запросами:
#    между find_by и create! приедет второй webhook → дубль.
#  - ловить только RecordNotUnique: validates :uniqueness срабатывает
#    раньше и кидает RecordInvalid, RecordNotUnique прилетает только
#    при race condition (когда два create! проскочили валидацию).
#
# Правильно: уникальный индекс в БД + rescue ОБЕИХ.
# Именно так и сделано в Yookassa::ProcessWebhook.

def store_event(payload)
  WebhookEvent.create!(
    provider: 'yookassa',
    external_event_id: payload['object']['id'],
    event_type: payload['event'],
    payload: payload,
  )
rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
  :duplicate
end

section '14. Идемпотентность через unique index + rescue'
event_id = "evt_#{Time.now.to_i}"
p store_event('event' => 'payment.succeeded', 'object' => { 'id' => event_id })
p store_event('event' => 'payment.succeeded', 'object' => { 'id' => event_id }) # => :duplicate


##### 15. Транзакция: либо всё, либо ничего
#
# Грабли: создать ledger entry и обновить баланс отдельно — упадёт
# в середине, баланс уедет. Всё, что атомарно по смыслу — в одну
# транзакцию + lock.

section '15. Транзакция + lock — атомарная отмена'
order_to_cancel = Order.successful.first
if order_to_cancel
  puts "найден order ##{order_to_cancel.id} — пример паттерна (выполнять не будем):"
  puts <<~RUBY
    ActiveRecord::Base.transaction do
      order.lock!
      raise unless order.may_cancel?
      LedgerEntry.create!(account: ..., entry_type: :reversal, ...)
      order.cancel!
    end
  RUBY
else
  puts '(нет successful Order, паттерн только в коде)'
end


##### 16. Discard (soft delete): живые vs удалённые
#
# Грабли: думать что .all уже фильтрует. У Discard НЕТ default_scope —
# .all отдаёт И удалённые тоже. Используй .kept / .discarded.

section '16. Discard — kept vs discarded vs all'
puts "User.kept.count       = #{User.kept.count}        # только живые"
puts "User.discarded.count  = #{User.discarded.count}   # только soft-deleted"
puts "User.all.count        = #{User.all.count}         # ВСЕ (← частая ошибка)"

# Удаление без потери данных:
# user.discard   # ставит discarded_at = now
# user.undiscard # возвращает


##### 17. AASM: безопасная отмена без исключений
#
# Грабли: order.cancel! на created → AASM::InvalidTransition.
# Перед вызовом проверяй may_*? — это уже сделано в Orders::Cancel.

def safe_cancel(order)
  return :already_cancelled if order.cancelled?
  return :invalid_transition unless order.may_cancel?

  order.cancel!
  :ok
end

section '17. AASM — безопасная отмена через may_cancel?'
p safe_cancel(Order.new(status: :created))     # => :invalid_transition
p safe_cancel(Order.new(status: :cancelled))   # => :already_cancelled


##### 18. Stale payment_pending — закрыть зависшие платежи
#
# Используем готовый scope из модели. Грабли: each вместо find_each —
# на больших таблицах съест память.

section '18. Stale payment_pending + find_each'
stale = Order.stale_payment_pending(30.minutes)
puts "найдено stale: #{stale.count}"
stale.find_each(batch_size: 500) do |o|
  Rails.logger.info("Stale order #{o.id}, last update: #{o.updated_at}")
  # CancelStaleOrderJob.perform_later(o.id)
end


##### 19. count vs size vs length / pluck vs select
#
# Грабли: путать .count и .size на ассоциациях.
#   .count   — всегда SELECT COUNT(*) (новый запрос)
#   .size    — умный: если уже загружено — Array#size, иначе COUNT(*)
#   .length  — ЗАГРУЗИТ ВСЁ в память и посчитает (плохо для больших)

section '19. count / size / length, pluck vs select'
user = User.first
if user
  puts "user.orders.count  = #{user.orders.count}   # SQL COUNT всегда"
  puts "user.orders.size   = #{user.orders.size}    # COUNT, если не загружено"
  puts "user.orders.length = #{user.orders.length}  # SELECT * + Array#length"
end

# pluck vs select:
p User.pluck(:id, :email).first(3)         # массив массивов
p User.select(:id, :email).first(3).map { |u| [u.id, u.email] } # AR-объекты


##### 20. Hash#dig для вложенных payload + safe-навигация по AR
#
# Грабли: payload['object']['id'] упадёт NoMethodError, если object отсутствует.
# Используй dig, особенно для внешних webhook'ов.

section '20. Hash#dig + safe navigation'
payload = { 'event' => 'payment.succeeded', 'object' => { 'id' => 'evt_1', 'metadata' => { 'order_id' => 42 } } }

p payload.dig('object', 'id')                       # => "evt_1"
p payload.dig('object', 'metadata', 'order_id')     # => 42
p payload.dig('object', 'metadata', 'missing')      # => nil (а не NoMethodError)

# AR: &. чтобы не падать на nil-ассоциациях
ghost_order = Order.find_by(id: -1)
p ghost_order&.user&.account&.balance_cents         # => nil вместо NoMethodError


############################################################
# Оригинальная версия (вналом, как писал руками)
############################################################

##### Посчитать баланс по ledger entries

entries = [
  { entry_type: 'credit', amount_cents: 1000 },
  { entry_type: 'credit', amount_cents: 500 },
  { entry_type: 'reversal', amount_cents: 300 },
  { entry_type: 'debit', amount_cents: 1000 },
]

def calculate_balabce(entries = [])
  entries.sum do |entry|
    case entry[:entry_type]
    when 'credit'
      entry[:amount_cents]
    when 'debit', 'reversal'
      -entry[:amount_cents]
    else
      raise ArgumentError, "Неизвестный тип: #{entry[:entry_type]}"
    end
  end
end

puts calculate_balabce(entries)


##### Найти дублирующиеся external_event_id

events = [
  { external_event_id: 'a1' },
  { external_event_id: 'a2' },
  { external_event_id: 'a1' },
  { external_event_id: 'a3' },
  { external_event_id: 'a2' }
]

def duplicate_event_ids(events)
  counts = events.each_with_object(Hash.new(0)) do |event, result|
    result[event[:external_event_id]] += 1
  end

  counts.select { |_event_id, count| count > 1 }.keys
end

puts duplicate_event_ids(events)

def duplicate_event_ids(events)
  events
    .group_by { |e| e[:external_event_id] }
    .select { |_id, group| group.size > 1 }
    .keys
end

puts duplicate_event_ids(events)

def duplicate_event_ids(events)
  ids = events.map { |e| e[:external_event_id] }
  ids.uniq.select { |id| ids.count(id) > 1 }
end

puts duplicate_event_ids(events)


##### Реализовать простой service object

class Orders::Create
  attr_reader :orders

  def initialize(orders:)
    @orders = orders
  end

  def call(user_id:, amount_cents:)
    return { success: false, error: :invalid_amount } unless amount_cents.positive?

    order = {
      id: next_id,
      user_id: user_id,
      amount_cents: amount_cents,
      status: 'created'
    }
    @orders << order

    { success: true, order: order }
  end

  private

  def next_id
    orders.map { |order| order[:id] }.max.to_i + 1
  end
end

order = Orders::Create.new(orders: []).call(user_id: 12, amount_cents: 12300)
puts order
