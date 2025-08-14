# Stimulus-Powered Features Documentation

This document provides comprehensive documentation for all Stimulus controllers implemented in the djtip Rails 8 admin interface. These features enhance the user experience with modern, interactive functionality while maintaining Rails conventions.

## Overview

The admin interface includes 8 Stimulus controllers that provide the following functionality:
- **Search & Filtering** - Real-time search and filter capabilities
- **Form Validation** - Client-side form validation with instant feedback
- **Confirmation Dialogs** - Safe deletion and destructive action confirmations
- **Clipboard Operations** - One-click copying of text and data
- **Auto-Save** - Automatic form saving to prevent data loss
- **Table Actions** - Bulk operations and row selection
- **Alert Management** - Dismissible notifications and alerts
- **Mobile Menu** - Responsive navigation for mobile devices

---

## 1. Search & Filter Controller

**File:** `app/javascript/controllers/search_filter_controller.js`
**Data Controller:** `data-controller="search-filter"`

### Purpose
Provides real-time search and filtering capabilities with automatic form submission and loading states.

### Features
- **Auto-submit**: Automatically submits forms after user input with configurable delay
- **Loading states**: Shows visual feedback during form submission
- **Clear functionality**: One-click clearing of all filters
- **Debounced input**: Prevents excessive API calls during typing

### Usage

#### Basic Search Form
```erb
<%= form_with url: admin_users_path, method: :get, local: true,
    data: { 
      controller: "search-filter",
      search_filter_auto_submit_value: true,
      search_filter_delay_value: 500
    },
    class: "card-body" do |f| %>
  
  <!-- Search Input -->
  <div class="form-control">
    <%= f.text_field :search, 
        placeholder: "Search users...",
        value: params[:search],
        data: { search_filter_target: "input" },
        class: "input input-bordered" %>
  </div>

  <!-- Filter Select -->
  <div class="form-control">
    <%= f.select :status, 
        options_for_select([["All", ""], ["Active", "active"], ["Inactive", "inactive"]], params[:status]),
        {},
        data: { search_filter_target: "select" },
        class: "select select-bordered" %>
  </div>

  <!-- Clear Button -->
  <button type="button" 
          data-action="click->search-filter#clear"
          class="btn btn-ghost">
    Clear Filters
  </button>
<% end %>
```

### Configuration Options
- `data-search-filter-auto-submit-value`: Enable/disable auto-submission (boolean)
- `data-search-filter-delay-value`: Delay in milliseconds before auto-submit (default: 500)

### Targets
- `form`: The form element to be submitted
- `input`: Text inputs that trigger debounced submission
- `select`: Select elements that trigger immediate submission

### Actions
- `clear`: Clears all form inputs and submits

---

## 2. Form Validation Controller

**File:** `app/javascript/controllers/form_validation_controller.js`
**Data Controller:** `data-controller="form-validation"`

### Purpose
Provides comprehensive client-side form validation with real-time feedback and custom validation rules.

### Features
- **Real-time validation**: Validates fields on blur and input events
- **Custom validation rules**: Email, phone, URL, number, and date validation
- **Visual feedback**: Adds CSS classes and shows error messages
- **Form submission prevention**: Prevents invalid form submission
- **Accessibility**: Proper ARIA attributes and focus management

### Usage

#### Basic Form with Validation
```erb
<%= form_with model: @user, 
    data: { controller: "form-validation" },
    class: "space-y-4" do |f| %>
  
  <!-- Required Text Field -->
  <div class="form-control">
    <%= f.label :name, class: "label" %>
    <%= f.text_field :name, 
        required: true,
        data: { 
          form_validation_target: "field",
          error_message: "Name is required and must be at least 2 characters"
        },
        class: "input input-bordered",
        minlength: 2 %>
    <div class="label hidden" data-field-error>
      <span class="label-text-alt text-error"></span>
    </div>
  </div>

  <!-- Email Field -->
  <div class="form-control">
    <%= f.label :email, class: "label" %>
    <%= f.email_field :email, 
        required: true,
        data: { form_validation_target: "field" },
        class: "input input-bordered" %>
    <div class="label hidden" data-field-error>
      <span class="label-text-alt text-error"></span>
    </div>
  </div>

  <!-- Phone Field -->
  <div class="form-control">
    <%= f.label :phone, class: "label" %>
    <%= f.telephone_field :phone, 
        data: { form_validation_target: "field" },
        class: "input input-bordered" %>
    <div class="label hidden" data-field-error>
      <span class="label-text-alt text-error"></span>
    </div>
  </div>

  <%= f.submit "Save", 
      data: { form_validation_target: "submit" },
      class: "btn btn-primary" %>
<% end %>
```

### Validation Rules
- **Email**: RFC-compliant email validation
- **Phone**: International phone number format
- **URL**: Valid URL format validation
- **Number**: Min/max range validation
- **Date**: Date format and range validation
- **Required**: HTML5 required attribute support

### CSS Classes
- `form-validation.invalidClass`: Applied to invalid fields (default: CSS class name)
- `form-validation.validClass`: Applied to valid fields (default: CSS class name)

### Targets
- `field`: Input fields to be validated
- `error`: Error message containers
- `submit`: Submit button (for form-level validation)

---

## 3. Confirmation Dialog Controller

**File:** `app/javascript/controllers/confirmation_dialog_controller.js`
**Data Controller:** `data-controller="confirmation-dialog"`

### Purpose
Provides safe confirmation dialogs for destructive actions like deletions, preventing accidental data loss.

### Features
- **Modal dialogs**: Native HTML dialog elements for confirmations
- **Customizable messages**: Configurable titles, messages, and button text
- **Turbo integration**: Works seamlessly with Turbo forms and links
- **CSRF protection**: Automatically includes CSRF tokens
- **Keyboard navigation**: ESC key and click-outside to cancel

### Usage

#### Delete Confirmation
```erb
<!-- Confirmation Dialog Modal -->
<dialog data-confirmation-dialog-target="modal" class="modal">
  <div class="modal-box">
    <h3 class="font-bold text-lg" data-confirmation-dialog-target="title">
      Confirm Action
    </h3>
    <p class="py-4" data-confirmation-dialog-target="message">
      Are you sure you want to proceed?
    </p>
    <div class="modal-action">
      <button data-confirmation-dialog-target="cancelButton" 
              data-action="click->confirmation-dialog#cancel"
              class="btn btn-ghost">
        Cancel
      </button>
      <button data-confirmation-dialog-target="confirmButton"
              data-action="click->confirmation-dialog#proceed" 
              class="btn btn-error">
        Delete
      </button>
    </div>
  </div>
</dialog>

<!-- Delete Button -->
<%= button_to "Delete User", admin_user_path(@user), 
    method: :delete,
    data: {
      controller: "confirmation-dialog",
      action: "click->confirmation-dialog#confirm",
      confirmation_dialog_title_value: "Delete User",
      confirmation_dialog_message_value: "Are you sure you want to delete this user? This action cannot be undone.",
      confirmation_dialog_confirm_text_value: "Delete User",
      confirmation_dialog_destructive_value: true
    },
    class: "btn btn-error btn-sm" %>
```

### Configuration Options
- `data-confirmation-dialog-title-value`: Modal title text
- `data-confirmation-dialog-message-value`: Confirmation message
- `data-confirmation-dialog-confirm-text-value`: Confirm button text (default: "Confirm")
- `data-confirmation-dialog-cancel-text-value`: Cancel button text (default: "Cancel")
- `data-confirmation-dialog-confirm-class-value`: Confirm button CSS class (default: "btn-error")
- `data-confirmation-dialog-destructive-value`: Adds destructive styling (boolean)

### Targets
- `modal`: The dialog element
- `title`: Title text element
- `message`: Message text element
- `confirmButton`: Confirm action button
- `cancelButton`: Cancel action button

### Actions
- `confirm`: Shows the confirmation dialog
- `proceed`: Executes the confirmed action
- `cancel`: Cancels and closes the dialog

---

## 4. Clipboard Controller

**File:** `app/javascript/controllers/clipboard_controller.js`
**Data Controller:** `data-controller="clipboard"`

### Purpose
Enables one-click copying of text content to the clipboard with visual feedback.

### Features
- **Modern Clipboard API**: Uses native browser clipboard API when available
- **Fallback support**: Falls back to legacy methods for older browsers
- **Visual feedback**: Button text changes and toast notifications
- **Flexible content**: Copy from text values, element content, or data attributes
- **Toast notifications**: Shows success/error messages

### Usage

#### Copy Button with Text Value
```erb
<button data-controller="clipboard"
        data-clipboard-text-value="https://example.com/share/123"
        data-action="click->clipboard#copy"
        class="btn btn-sm btn-outline">
  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
          d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
  </svg>
  Copy Link
</button>
```

#### Copy from Element Content
```erb
<div data-controller="clipboard">
  <code data-clipboard-target="source" class="bg-base-200 p-2 rounded">
    rails generate controller Users
  </code>
  <button data-clipboard-target="button"
          data-action="click->clipboard#copy"
          class="btn btn-xs btn-ghost ml-2">
    Copy
  </button>
</div>
```

#### Copy User Email
```erb
<div class="flex items-center gap-2">
  <span><%= @user.email %></span>
  <button data-controller="clipboard"
          data-clipboard-text-value="<%= @user.email %>"
          data-clipboard-success-message-value="Email copied!"
          data-action="click->clipboard#copy"
          class="btn btn-xs btn-ghost">
    📋
  </button>
</div>
```

### Configuration Options
- `data-clipboard-text-value`: Static text to copy
- `data-clipboard-success-message-value`: Success message (default: "Copied!")
- `data-clipboard-error-message-value`: Error message (default: "Failed to copy")

### Targets
- `source`: Element containing text to copy
- `button`: Button element that shows feedback

### Actions
- `copy`: Copies text to clipboard

---

## 5. Auto-Save Controller

**File:** `app/javascript/controllers/auto_save_controller.js`
**Data Controller:** `data-controller="auto-save"`

### Purpose
Automatically saves form data at regular intervals to prevent data loss, with visual status indicators.

### Features
- **Automatic saving**: Saves forms at configurable intervals
- **Change detection**: Only saves when form data has changed
- **Status indicators**: Shows save status (unsaved, saving, saved, error)
- **Before unload protection**: Warns users about unsaved changes
- **Manual save trigger**: Allows immediate saving
- **AJAX submission**: Uses fetch API for background saves

### Usage

#### Auto-Save Form
```erb
<%= form_with model: @user,
    data: {
      controller: "auto-save",
      auto_save_interval_value: 30000,  # 30 seconds
      auto_save_url_value: admin_user_path(@user),
      auto_save_enabled_value: true
    } do |f| %>
  
  <!-- Status Indicator -->
  <div class="flex justify-between items-center mb-4">
    <h2>Edit User</h2>
    <span data-auto-save-target="status" class="text-sm"></span>
  </div>

  <!-- Form Fields -->
  <div class="form-control">
    <%= f.label :name, class: "label" %>
    <%= f.text_field :name, class: "input input-bordered" %>
  </div>

  <div class="form-control">
    <%= f.label :email, class: "label" %>
    <%= f.email_field :email, class: "input input-bordered" %>
  </div>

  <!-- Manual Save Button -->
  <div class="flex justify-between">
    <button type="button"
            data-action="click->auto-save#saveNow"
            class="btn btn-outline">
      Save Now
    </button>
    
    <button type="button"
            data-action="click->auto-save#toggle"
            class="btn btn-ghost btn-sm">
      Toggle Auto-Save
    </button>
  </div>

  <%= f.submit "Save", class: "btn btn-primary" %>
<% end %>
```

### Configuration Options
- `data-auto-save-interval-value`: Save interval in milliseconds (default: 30000)
- `data-auto-save-url-value`: Custom save URL (defaults to form action)
- `data-auto-save-enabled-value`: Enable/disable auto-save (default: true)

### Status Messages
- **Unsaved changes**: Yellow warning indicator
- **Saving...**: Blue info indicator with spinner
- **All changes saved**: Green success indicator
- **Save failed**: Red error indicator

### Targets
- `form`: The form to auto-save
- `status`: Status message display element

### Actions
- `saveNow`: Manually trigger save
- `toggle`: Enable/disable auto-save

### Events
- `auto-save:saved`: Fired when save succeeds
- `auto-save:error`: Fired when save fails

---

## 6. Table Actions Controller

**File:** `app/javascript/controllers/table_actions_controller.js`
**Data Controller:** `data-controller="table-actions"`

### Purpose
Provides bulk operations and row selection functionality for data tables.

### Features
- **Row selection**: Individual and bulk row selection
- **Select all**: Toggle all visible rows
- **Visual feedback**: Highlights selected rows
- **Bulk operations**: Delete, export, and custom actions
- **Selection counter**: Shows number of selected items
- **Indeterminate state**: Proper checkbox states for partial selections

### Usage

#### Data Table with Bulk Actions
```erb
<div data-controller="table-actions" 
     data-table-actions-total-count-value="<%= @users.count %>">
  
  <!-- Bulk Actions Bar -->
  <div data-table-actions-target="bulkActions" class="hidden mb-4">
    <div class="flex items-center justify-between bg-primary/10 p-3 rounded-lg">
      <span data-table-actions-target="counter" class="text-sm font-medium">
        0 selected
      </span>
      <div class="flex gap-2">
        <button data-action="click->table-actions#bulkDelete"
                class="btn btn-error btn-sm">
          Delete Selected
        </button>
        <button data-action="click->table-actions#exportSelected"
                class="btn btn-outline btn-sm">
          Export Selected
        </button>
        <button data-action="click->table-actions#clearSelection"
                class="btn btn-ghost btn-sm">
          Clear Selection
        </button>
      </div>
    </div>
  </div>

  <!-- Table -->
  <div class="overflow-x-auto">
    <table class="table">
      <thead>
        <tr>
          <th>
            <input type="checkbox" 
                   data-table-actions-target="selectAll"
                   data-action="change->table-actions#toggleAll"
                   class="checkbox" />
          </th>
          <th>Name</th>
          <th>Email</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <% @users.each do |user| %>
          <tr data-table-actions-target="row">
            <td>
              <input type="checkbox" 
                     value="<%= user.id %>"
                     data-table-actions-target="checkbox"
                     data-action="change->table-actions#toggleRow"
                     class="checkbox" />
            </td>
            <td><%= user.name %></td>
            <td><%= user.email %></td>
            <td>
              <%= link_to "Edit", edit_admin_user_path(user), 
                  class: "btn btn-ghost btn-xs" %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
```

### Configuration Options
- `data-table-actions-total-count-value`: Total number of items
- `data-bulk-url`: URL for bulk operations (default: `/admin/bulk_actions`)
- `data-export-url`: URL for export operations (default: `/admin/export`)

### Targets
- `row`: Table rows that can be selected
- `checkbox`: Individual row checkboxes
- `bulkActions`: Bulk actions container
- `selectAll`: Select all checkbox
- `counter`: Selection counter display

### Actions
- `toggleRow`: Toggle individual row selection
- `toggleAll`: Toggle all visible rows
- `clearSelection`: Clear all selections
- `bulkDelete`: Delete selected items with confirmation
- `exportSelected`: Export selected items

### Events
- `table-actions:selectionChanged`: Fired when selection changes

---

## 7. Alert Controller

**File:** `app/javascript/controllers/alert_controller.js`
**Data Controller:** `data-controller="alert"`

### Purpose
Provides dismissible alert notifications and flash messages.

### Features
- **One-click dismissal**: Remove alerts with a single click
- **Fade animations**: Smooth removal animations
- **Flash message integration**: Works with Rails flash messages

### Usage

#### Dismissible Alert
```erb
<div data-controller="alert" 
     class="alert alert-success mb-4">
  <svg xmlns="http://www.w3.org/2000/svg" 
       class="stroke-current shrink-0 h-6 w-6" 
       fill="none" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
          d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
  </svg>
  <span>User successfully created!</span>
  <button data-action="click->alert#dismiss" 
          class="btn btn-sm btn-circle btn-ghost">
    ✕
  </button>
</div>
```

#### Flash Messages
```erb
<% flash.each do |type, message| %>
  <div data-controller="alert" 
       class="alert alert-<%= type == 'notice' ? 'success' : 'error' %> mb-4">
    <span><%= message %></span>
    <button data-action="click->alert#dismiss" 
            class="btn btn-sm btn-circle btn-ghost">
      ✕
    </button>
  </div>
<% end %>
```

### Actions
- `dismiss`: Removes the alert element

---

## 8. Mobile Menu Controller

**File:** `app/javascript/controllers/mobile_menu_controller.js`
**Data Controller:** `data-controller="mobile-menu"`

### Purpose
Provides responsive navigation menu functionality for mobile devices.

### Features
- **Toggle visibility**: Show/hide mobile navigation
- **Responsive design**: Works with Tailwind CSS responsive utilities
- **Touch-friendly**: Optimized for mobile interaction

### Usage

#### Mobile Navigation
```erb
<div data-controller="mobile-menu">
  <!-- Mobile Menu Button -->
  <button data-action="click->mobile-menu#toggle"
          class="btn btn-ghost lg:hidden">
    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
            d="M4 6h16M4 12h16M4 18h16" />
    </svg>
  </button>

  <!-- Mobile Menu -->
  <div data-mobile-menu-target="menu" 
       class="hidden lg:flex lg:items-center lg:space-x-6">
    <%= link_to "Dashboard", admin_root_path, 
        class: "block py-2 px-4 hover:bg-base-200 lg:p-0" %>
    <%= link_to "Users", admin_users_path, 
        class: "block py-2 px-4 hover:bg-base-200 lg:p-0" %>
    <%= link_to "Events", admin_events_path, 
        class: "block py-2 px-4 hover:bg-base-200 lg:p-0" %>
  </div>
</div>
```

### Targets
- `menu`: The menu element to show/hide

### Actions
- `toggle`: Toggle menu visibility

---

## Testing the Features

To test these Stimulus features in the admin interface:

1. **Search & Filter**: Visit any admin index page (users, events, tips, performers) and use the search/filter forms
2. **Form Validation**: Try creating/editing records with invalid data
3. **Confirmation Dialogs**: Attempt to delete any record
4. **Clipboard**: Use copy buttons on show pages or in tables
5. **Auto-Save**: Edit forms and watch for auto-save status indicators
6. **Table Actions**: Select multiple rows in any admin table
7. **Alerts**: Look for flash messages after form submissions
8. **Mobile Menu**: Resize browser to mobile width and test navigation

## Browser Compatibility

All Stimulus controllers are designed to work with:
- **Modern browsers**: Chrome 60+, Firefox 55+, Safari 12+, Edge 79+
- **Fallback support**: Graceful degradation for older browsers
- **Mobile devices**: Touch-optimized interactions
- **Accessibility**: Keyboard navigation and screen reader support

## Performance Considerations

- **Lazy loading**: Controllers only initialize when needed
- **Event delegation**: Efficient event handling
- **Debounced inputs**: Prevents excessive API calls
- **Memory management**: Proper cleanup on disconnect
- **Minimal bundle size**: Lightweight implementation

## Customization

Each controller can be customized through:
- **Data attributes**: Configuration values and options
- **CSS classes**: Styling and visual feedback
- **Event listeners**: Custom behavior integration
- **Inheritance**: Extending controllers for specific needs

---

*This documentation covers all Stimulus-powered features in the djtip admin interface. For implementation details, refer to the individual controller files in `app/javascript/controllers/`.*
