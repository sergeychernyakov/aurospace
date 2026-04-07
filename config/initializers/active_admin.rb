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
  config.footer = ''.html_safe + <<~HTML.html_safe
    <script>
      (function() {
        var isDark = (localStorage.getItem('theme') || 'dark') === 'dark';
        document.documentElement.classList.toggle('dark', isDark);
        var header = document.getElementById('header');
        if (header && !document.getElementById('aa-theme-toggle')) {
          var btn = document.createElement('button');
          btn.id = 'aa-theme-toggle';
          btn.style.cssText = 'position:absolute;right:20px;top:50%;transform:translateY(-50%);background:none;border:none;font-size:20px;cursor:pointer;z-index:999;';
          btn.textContent = isDark ? '☀️' : '🌙';
          btn.onclick = function() {
            isDark = !isDark;
            document.documentElement.classList.toggle('dark', isDark);
            localStorage.setItem('theme', isDark ? 'dark' : 'light');
            btn.textContent = isDark ? '☀️' : '🌙';
          };
          header.style.position = 'relative';
          header.appendChild(btn);
        }
      })();
    </script>
  HTML
end
