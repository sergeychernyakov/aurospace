# frozen_string_literal: true

# config/initializers/secure_headers.rb
#
# HTTP security headers configuration.
# Protects against XSS, clickjacking, MIME sniffing, etc.

if defined?(SecureHeaders)
  SecureHeaders::Configuration.default do |config|
    config.x_frame_options = 'SAMEORIGIN'
    config.x_content_type_options = 'nosniff'
    config.x_xss_protection = '0' # Deprecated in modern browsers, CSP is preferred
    config.x_permitted_cross_domain_policies = 'none'
    config.referrer_policy = %w[strict-origin-when-cross-origin]

    config.csp = {
      default_src: %w['self'],
      script_src: %w['self' 'unsafe-inline'],
      style_src: %w['self' 'unsafe-inline'],
      img_src: %w['self' data:],
      font_src: %w['self'],
      connect_src: %w['self'],
      frame_ancestors: %w['none'],
      form_action: %w['self'],
      base_uri: %w['self'],
    }
  end
end
