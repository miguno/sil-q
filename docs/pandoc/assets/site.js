(function () {
  // Theme toggle
  var toggle = document.getElementById('theme-toggle');
  if (toggle) {
    toggle.addEventListener('click', function () {
      var current = document.documentElement.getAttribute('data-theme') || 'light';
      var next = current === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      try { localStorage.setItem('theme', next); } catch (e) {}
    });
  }

  // Sidebar toggle (mobile)
  var sbToggle = document.getElementById('sidebar-toggle');
  if (sbToggle) {
    sbToggle.addEventListener('click', function () {
      var open = document.body.classList.toggle('sidebar-open');
      sbToggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
  }
})();
