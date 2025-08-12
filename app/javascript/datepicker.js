// Initialize Flowbite Datepickers
function initializeDatepickers() {
  // Wait for Flowbite to be available
  if (typeof window.Datepicker === 'undefined') {
    setTimeout(initializeDatepickers, 100);
    return;
  }

  const datepickers = document.querySelectorAll('[datepicker]:not([data-datepicker-initialized])');
  
  datepickers.forEach(function(datepicker) {
    try {
      // Initialize Flowbite datepicker
      new window.Datepicker(datepicker, {
        format: 'mm/dd/yyyy',
        autohide: true,
        todayBtn: true,
        clearBtn: true,
        todayBtnText: 'Today',
        clearBtnText: 'Clear',
        orientation: 'bottom auto',
        container: 'body'
      });
      datepicker.setAttribute('data-datepicker-initialized', 'true');
    } catch (error) {
      console.log('Datepicker initialization error:', error);
    }
  });
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', initializeDatepickers);

// Handle Turbo navigation
document.addEventListener('turbo:load', initializeDatepickers);

// Handle Turbo frame loads
document.addEventListener('turbo:frame-load', initializeDatepickers);
