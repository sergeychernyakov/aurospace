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
    config.referrer_policy = ['strict-origin-when-cross-origin']

    config.csp = {
      default_src: ["'self'"],
      script_src: ["'self'", "'unsafe-inline'"],
      style_src: ["'self'", "'unsafe-inline'"],
      img_src: ["'self'", 'data:'],
      font_src: ["'self'"],
      connect_src: ["'self'"],
      frame_ancestors: ["'none'"],
      form_action: ["'self'"],
      base_uri: ["'self'"],
    }
  end
end
