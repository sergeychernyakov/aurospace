# frozen_string_literal: true

# db/seeds.rb
#
# Idempotent seed data for AUROSPACE Orders Demo.
# Creates demo users, orders in every AASM state, ledger entries,
# webhook events, and notification logs.

Rails.logger = Logger.new($stdout)

puts '=== Seeding AUROSPACE Demo Data ==='

# --- Demo Users ---

user1 = User.find_or_create_by!(email: 'demo1@aurospace.dev') do |u|
  u.name = 'Demo User 1'
end
Account.find_or_create_by!(user: user1) do |a|
  a.currency = 'RUB'
  a.balance_cents = 0
end

user2 = User.find_or_create_by!(email: 'demo2@aurospace.dev') do |u|
  u.name = 'Demo User 2'
end
Account.find_or_create_by!(user: user2) do |a|
  a.currency = 'RUB'
  a.balance_cents = 0
end

puts "Users: #{User.count}"

# --- Helper to create orders idempotently ---

def find_or_create_order(user, amount_cents, tag)
  existing = Order.unscoped.find_by(user: user, amount_cents: amount_cents,
                                    payment_provider: "seed_#{tag}",)
  return existing if existing

  Order.create!(
    user: user,
    amount_cents: amount_cents,
    currency: 'RUB',
    payment_provider: "seed_#{tag}",
  )
end

# --- Created Orders (3x) ---

[1000, 2500, 5000].each_with_index do |amount, i|
  user = i.even? ? user1 : user2
  find_or_create_order(user, amount, "created_#{i}")
end
puts 'Created orders: 3'

# --- Payment Pending Orders (2x) ---

[3000, 7500].each_with_index do |amount, i|
  user = i.even? ? user1 : user2
  order = find_or_create_order(user, amount, "pending_#{i}")
  unless order.payment_pending?
    order.start_payment! if order.may_start_payment?
    order.update!(external_payment_id: "seed_pay_#{SecureRandom.hex(8)}")
  end
end
puts 'Payment pending orders: 2'

# --- Successful Orders (3x) with ledger entries ---

[2000, 4000, 10_000].each_with_index do |amount, i|
  user = i.even? ? user1 : user2
  order = find_or_create_order(user, amount, "successful_#{i}")

  next if order.successful?

  order.start_payment! if order.may_start_payment?
  order.update!(external_payment_id: "seed_pay_#{SecureRandom.hex(8)}")

  if order.may_mark_successful?
    result = Orders::MarkSuccessful.new.call(order: order)
    puts "  WARNING: Could not mark order #{order.id} as successful: #{result.failure}" if result.failure?
  end
end
puts 'Successful orders: 3'

# --- Cancelled Orders (2x) with credit + reversal entries ---

[1500, 6000].each_with_index do |amount, i|
  user = i.even? ? user1 : user2
  order = find_or_create_order(user, amount, "cancelled_#{i}")

  next if order.cancelled?

  order.start_payment! if order.may_start_payment?
  order.update!(external_payment_id: "seed_pay_#{SecureRandom.hex(8)}")

  Orders::MarkSuccessful.new.call(order: order) if order.may_mark_successful?

  if order.reload.may_cancel?
    result = Orders::Cancel.new.call(order: order)
    puts "  WARNING: Could not cancel order #{order.id}: #{result.failure}" if result.failure?
  end
end
puts 'Cancelled orders: 2'

# --- Webhook Events ---

Order.unscoped.where.not(external_payment_id: nil).find_each do |order|
  event_id = "seed_evt_#{order.external_payment_id}"
  event_type = order.cancelled? ? 'payment.canceled' : 'payment.succeeded'

  WebhookEvent.find_or_create_by!(external_event_id: event_id) do |we|
    we.provider = 'yookassa'
    we.event_type = event_type
    we.payload = { 'event' => event_type, 'object' => { 'id' => order.external_payment_id } }
    we.status = 'processed'
    we.processed_at = Time.current
  end
end
puts "Webhook events: #{WebhookEvent.count}"

# --- Notification Logs ---

Order.unscoped.find_each do |order|
  NotificationLog.find_or_create_by!(order: order, mail_type: 'order_created') do |nl|
    nl.recipient = order.user.email
    nl.sent_at = order.created_at
  end

  if order.successful? || order.cancelled?
    NotificationLog.find_or_create_by!(order: order, mail_type: 'payment_successful') do |nl|
      nl.recipient = order.user.email
      nl.sent_at = order.paid_at || order.created_at
    end
  end

  next unless order.cancelled?

  NotificationLog.find_or_create_by!(order: order, mail_type: 'order_cancelled') do |nl|
    nl.recipient = order.user.email
    nl.sent_at = order.cancelled_at || order.created_at
  end
end
puts "Notification logs: #{NotificationLog.count}"

# --- Summary ---

puts ''
puts '=== Seed Summary ==='
puts "Users:             #{User.count}"
puts "Accounts:          #{Account.count}"
puts "Orders:            #{Order.unscoped.count}"
puts "  Created:         #{Order.unscoped.created.count}"
puts "  Payment Pending: #{Order.unscoped.payment_pending.count}"
puts "  Successful:      #{Order.unscoped.successful.count}"
puts "  Cancelled:       #{Order.unscoped.cancelled.count}"
puts "Ledger Entries:    #{LedgerEntry.count}"
puts "Webhook Events:    #{WebhookEvent.count}"
puts "Notification Logs: #{NotificationLog.count}"
puts 'Account Balances:'
Account.unscoped.includes(:user).find_each do |account|
  puts "  #{account.user.email}: #{account.balance_cents / 100.0} #{account.currency}"
end
puts '=== Done ==='
