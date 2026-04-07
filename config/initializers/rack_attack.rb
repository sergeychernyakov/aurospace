# frozen_string_literal: true

# config/initializers/rack_attack.rb
#
# Rate limiting and request throttling.
# Protects sensitive endpoints from abuse.

if defined?(Rack::Attack)
  # === Throttle: General API ===
  # 300 requests per 5 minutes per IP
  Rack::Attack.throttle('req/ip', limit: 300, period: 5.minutes, &:ip)

  # === Throttle: Webhook endpoint ===
  # YooKassa sends limited webhooks, but protect against replay attacks
  Rack::Attack.throttle('webhooks/ip', limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/webhooks/')
  end

  # === Throttle: Order creation ===
  # Prevent rapid order creation (potential abuse)
  Rack::Attack.throttle('orders/create/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.path == '/orders' && req.post?
  end

  # === Throttle: Admin panel ===
  # Protect admin from brute force
  Rack::Attack.throttle('admin/ip', limit: 30, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/admin')
  end

  # === Blocklist: Known bad actors ===
  # Rack::Attack.blocklist('block bad IPs') do |req|
  #   bad_ips = Rails.cache.fetch('blocked_ips', expires_in: 5.minutes) { [] }
  #   bad_ips.include?(req.ip)
  # end

  # === Response ===
  Rack::Attack.throttled_responder = lambda do |_req|
    [
      429,
      { 'Content-Type' => 'application/json' },
      [{ error: { code: 'rate_limited', message: 'Too many requests. Try again later.' } }.to_json],
    ]
  end
end
