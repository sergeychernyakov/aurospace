//= require active_admin/base
//= require chartkick
//= require Chart.bundle

// === Theme toggle — syncs with React frontend via localStorage ===

// Apply immediately (before DOMContentLoaded to prevent flash)
(function() {
  var isDark = (localStorage.getItem('theme') || 'dark') === 'dark';
  document.documentElement.classList.toggle('dark', isDark);
})();

// Add toggle button after DOM ready
document.addEventListener('DOMContentLoaded', function() {
  var isDark = (localStorage.getItem('theme') || 'dark') === 'dark';
  var header = document.getElementById('header');
  if (!header || document.getElementById('aa-theme-toggle')) return;

  var btn = document.createElement('button');
  btn.id = 'aa-theme-toggle';
  btn.style.cssText = [
    'position:absolute',
    'right:20px',
    'top:50%',
    'transform:translateY(-50%)',
    'background:none',
    'border:none',
    'font-size:22px',
    'cursor:pointer',
    'z-index:999',
    'padding:4px 8px',
    'line-height:1'
  ].join(';');
  btn.textContent = isDark ? '\u2600\uFE0F' : '\uD83C\uDF19'; // ☀️ or 🌙
  btn.title = isDark ? 'Light mode' : 'Dark mode';

  btn.addEventListener('click', function() {
    isDark = !isDark;
    document.documentElement.classList.toggle('dark', isDark);
    localStorage.setItem('theme', isDark ? 'dark' : 'light');
    btn.textContent = isDark ? '\u2600\uFE0F' : '\uD83C\uDF19';
    btn.title = isDark ? 'Light mode' : 'Dark mode';
  });

  header.style.position = 'relative';
  header.appendChild(btn);
});
