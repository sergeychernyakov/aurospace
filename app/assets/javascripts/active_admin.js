//= require active_admin/base
//= require chartkick
//= require Chart.bundle

// Theme toggle — syncs with React frontend via localStorage
(function() {
  function applyTheme(dark) {
    document.documentElement.classList.toggle('dark', dark);
    document.body.classList.toggle('dark-theme', dark);
    localStorage.setItem('theme', dark ? 'dark' : 'light');
  }

  // Apply saved theme on load
  var saved = localStorage.getItem('theme');
  var isDark = saved ? saved === 'dark' : true;
  applyTheme(isDark);

  // Add toggle button to header
  document.addEventListener('DOMContentLoaded', function() {
    var header = document.getElementById('header');
    if (!header) return;

    var btn = document.createElement('button');
    btn.id = 'theme-toggle';
    btn.style.cssText = 'position:absolute;right:20px;top:8px;background:none;border:none;font-size:20px;cursor:pointer;z-index:999;';
    btn.textContent = isDark ? '☀️' : '🌙';
    btn.title = isDark ? 'Switch to light' : 'Switch to dark';
    btn.onclick = function() {
      isDark = !isDark;
      applyTheme(isDark);
      btn.textContent = isDark ? '☀️' : '🌙';
      btn.title = isDark ? 'Switch to light' : 'Switch to dark';
    };
    header.style.position = 'relative';
    header.appendChild(btn);
  });
})();
