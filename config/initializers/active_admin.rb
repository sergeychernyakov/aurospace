# frozen_string_literal: true

# config/initializers/active_admin.rb

ActiveAdmin.setup do |config|
  config.site_title = 'AUROSPACE Admin'
  config.default_namespace = :a
  config.authentication_method = :authenticate_admin!
  config.current_user_method = false
  config.logout_link_path = false
  config.comments = false
  config.batch_actions = false
  config.root_to = 'dashboard#index'

  # Theme toggle synced with React frontend via localStorage
  config.head = <<~HTML.html_safe
    <script>
      // Apply theme IMMEDIATELY to prevent flash
      (function() {
        var isDark = (localStorage.getItem('theme') || 'dark') === 'dark';
        document.documentElement.classList.toggle('dark', isDark);
      })();
    </script>
  HTML

  config.footer = <<~HTML.html_safe
    <script>
      // Add toggle button after DOM ready
      document.addEventListener('DOMContentLoaded', function() {
        var isDark = (localStorage.getItem('theme') || 'dark') === 'dark';
        var header = document.getElementById('header');
        if (!header || document.getElementById('aa-theme-toggle')) return;

        var btn = document.createElement('button');
        btn.id = 'aa-theme-toggle';
        btn.style.cssText = 'position:absolute;right:20px;top:50%;transform:translateY(-50%);background:none;border:none;font-size:22px;cursor:pointer;z-index:999;padding:4px 8px;';
        btn.textContent = isDark ? '☀️' : '🌙';
        btn.title = isDark ? 'Light mode' : 'Dark mode';
        btn.addEventListener('click', function() {
          isDark = !isDark;
          document.documentElement.classList.toggle('dark', isDark);
          localStorage.setItem('theme', isDark ? 'dark' : 'light');
          btn.textContent = isDark ? '☀️' : '🌙';
          btn.title = isDark ? 'Light mode' : 'Dark mode';
        });
        header.style.position = 'relative';
        header.appendChild(btn);
      });
    </script>
  HTML
end
