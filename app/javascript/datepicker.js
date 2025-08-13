// Initialize daisyUI-compatible Datepickers
function initializeDatepickers() {
  const datepickers = document.querySelectorAll('[datepicker]:not([data-datepicker-initialized])');
  
  datepickers.forEach(function(datepicker) {
    try {
      // Convert to HTML5 datetime-local input for better native support
      datepicker.type = 'datetime-local';
      
      // Update classes for daisyUI styling
      datepicker.classList.remove('pl-10'); // Remove left padding for icon
      datepicker.classList.add('input', 'input-bordered', 'w-full');
      
      // Handle value formatting for datetime-local
      const currentValue = datepicker.value;
      if (currentValue && currentValue.includes('/')) {
        // Convert MM/DD/YYYY HH:MM AM/PM to YYYY-MM-DDTHH:MM format
        try {
          const date = new Date(currentValue);
          if (!isNaN(date.getTime())) {
            const year = date.getFullYear();
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const day = String(date.getDate()).padStart(2, '0');
            const hours = String(date.getHours()).padStart(2, '0');
            const minutes = String(date.getMinutes()).padStart(2, '0');
            datepicker.value = `${year}-${month}-${day}T${hours}:${minutes}`;
          }
        } catch (e) {
          console.log('Date conversion error:', e);
        }
      }
      
      // Remove the calendar icon container since we're using native datetime input
      const iconContainer = datepicker.parentElement.querySelector('.absolute');
      if (iconContainer) {
        iconContainer.remove();
      }
      
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
