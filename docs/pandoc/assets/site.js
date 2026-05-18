(function () {
  // Theme toggle
  var toggle = document.getElementById('theme-toggle');
  function syncPressed() {
    if (!toggle) return;
    var isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    toggle.setAttribute('aria-pressed', isDark ? 'true' : 'false');
  }
  syncPressed();
  if (toggle) {
    toggle.addEventListener('click', function () {
      var current = document.documentElement.getAttribute('data-theme') || 'light';
      var next = current === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      try { localStorage.setItem('theme', next); } catch (e) {}
      syncPressed();
    });
  }

  // Sidebar toggle (mobile)
  var sbToggle = document.getElementById('sidebar-toggle');
  var sbClose = document.getElementById('sidebar-close');
  function setSidebarOpen(open) {
    document.body.classList.toggle('sidebar-open', open);
    if (sbToggle) sbToggle.setAttribute('aria-expanded', open ? 'true' : 'false');
  }
  if (sbToggle) {
    sbToggle.addEventListener('click', function () {
      setSidebarOpen(!document.body.classList.contains('sidebar-open'));
    });
  }
  if (sbClose) {
    sbClose.addEventListener('click', function () { setSidebarOpen(false); });
  }
})();
