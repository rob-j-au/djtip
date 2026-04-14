# Stimulus JavaScript Features

Interactive features powered by Stimulus controllers for the djtip admin interface.

## Overview

**8 Stimulus controllers** providing modern, interactive functionality:

1. **Search & Filter** - Real-time search with auto-submit
2. **Form Validation** - Client-side validation with instant feedback
3. **Confirmation Dialogs** - Safe deletion confirmations
4. **Clipboard** - One-click copy functionality
5. **Auto-Save** - Automatic form saving
6. **Table Actions** - Bulk operations and row selection
7. **Alert** - Dismissible notifications
8. **Mobile Menu** - Responsive navigation

**Status:** ✅ All controllers tested and working

---

## 1. Search & Filter

**File:** `app/javascript/controllers/search_filter_controller.js`

**Features:**

- Auto-submit with debouncing (500ms)
- Loading states during search
- Clear all filters button
- Works with text inputs and selects

**Usage:**

```erb
<%= form_with url: admin_users_path, method: :get,
    data: { 
      controller: "search-filter",
      search_filter_auto_submit_value: true,
      search_filter_delay_value: 500
    } do |f| %>
  
  <%= f.text_field :search, 
      data: { search_filter_target: "input" },
      placeholder: "Search...",
      class: "input input-bordered" %>
  
  <button type="button" 
          data-action="click->search-filter#clear"
          class="btn btn-ghost">
    Clear
  </button>
<% end %>
```

---

## 2. Form Validation

**File:** `app/javascript/controllers/form_validation_controller.js`

**Features:**

- Real-time validation on blur/input
- Email, phone, URL, number validation
- Visual feedback with error messages
- Prevents invalid form submission

**Usage:**

```erb
<%= form_with model: @user, 
    data: { controller: "form-validation" } do |f| %>
  
  <%= f.text_field :name, 
      required: true,
      data: { 
        form_validation_target: "field",
        error_message: "Name is required"
      },
      class: "input input-bordered",
      minlength: 2 %>
  
  <div class="label hidden" data-field-error>
    <span class="label-text-alt text-error"></span>
  </div>
<% end %>
```

---

## 3. Confirmation Dialog

**File:** `app/javascript/controllers/confirmation_dialog_controller.js`

**Features:**

- Modal dialogs for destructive actions
- Customizable messages and buttons
- Turbo integration
- Keyboard navigation (ESC to cancel)

**Usage:**

```erb
<%= button_to "Delete", admin_user_path(@user), 
    method: :delete,
    data: {
      controller: "confirmation-dialog",
      action: "click->confirmation-dialog#confirm",
      confirmation_dialog_title_value: "Delete User",
      confirmation_dialog_message_value: "Are you sure?",
      confirmation_dialog_confirm_text_value: "Delete",
      confirmation_dialog_destructive_value: true
    },
    class: "btn btn-error btn-sm" %>
```

---

## 4. Clipboard

**File:** `app/javascript/controllers/clipboard_controller.js`

**Features:**

- Modern Clipboard API with fallback
- Visual feedback on copy
- Toast notifications
- Copy from text value or element content

**Usage:**

```erb
<button data-controller="clipboard"
        data-clipboard-text-value="<%= @user.email %>"
        data-clipboard-success-message-value="Email copied!"
        data-action="click->clipboard#copy"
        class="btn btn-xs btn-ghost">
  📋 Copy
</button>
```

---

## 5. Auto-Save

**File:** `app/javascript/controllers/auto_save_controller.js`

**Features:**

- Automatic saving at intervals (default 30s)
- Change detection (only saves if modified)
- Status indicators (unsaved, saving, saved, error)
- Before unload protection
- Manual save trigger

**Usage:**

```erb
<%= form_with model: @user,
    data: {
      controller: "auto-save",
      auto_save_interval_value: 30000,
      auto_save_enabled_value: true
    } do |f| %>
  
  <span data-auto-save-target="status"></span>
  
  <%= f.text_field :name, class: "input input-bordered" %>
  
  <button type="button"
          data-action="click->auto-save#saveNow"
          class="btn btn-outline">
    Save Now
  </button>
<% end %>
```

---

## 6. Table Actions

**File:** `app/javascript/controllers/table_actions_controller.js`

**Features:**

- Row selection (individual and bulk)
- Select all toggle
- Visual feedback for selected rows
- Bulk delete and export
- Selection counter

**Usage:**

```erb
<div data-controller="table-actions">
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
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

---

## 7. Alert

**File:** `app/javascript/controllers/alert_controller.js`

**Features:**

- One-click dismissal
- Fade animations
- Flash message integration

**Usage:**

```erb
<div data-controller="alert" class="alert alert-success">
  <span>Success message!</span>
  <button data-action="click->alert#dismiss" 
          class="btn btn-sm btn-circle btn-ghost">
    ✕
  </button>
</div>
```

---

## 8. Mobile Menu

**File:** `app/javascript/controllers/mobile_menu_controller.js`

**Features:**

- Toggle mobile navigation
- Responsive design
- Touch-friendly

**Usage:**

```erb
<div data-controller="mobile-menu">
  <button data-action="click->mobile-menu#toggle"
          class="btn btn-ghost lg:hidden">
    ☰
  </button>
  
  <div data-mobile-menu-target="menu" 
       class="hidden lg:flex">
    <%= link_to "Dashboard", admin_root_path %>
    <%= link_to "Users", admin_users_path %>
  </div>
</div>
```

---

## Testing

**All controllers tested and verified:**

✅ Search & Filter - Auto-submit with debouncing works  
✅ Form Validation - Real-time validation functional  
✅ Confirmation Dialog - Delete confirmations working  
✅ Clipboard - Copy functionality operational  
✅ Auto-Save - Automatic saving with status indicators  
✅ Table Actions - Bulk operations functional  
✅ Alert - Dismissible notifications working  
✅ Mobile Menu - Responsive navigation operational  

**Test locations:**

- `/admin/users` - Search, table actions, confirmations
- `/admin/users/new` - Form validation, auto-save
- All admin pages - Alerts, mobile menu, clipboard

---

## Browser Compatibility

- Chrome 60+, Firefox 55+, Safari 12+, Edge 79+
- Fallback support for older browsers
- Touch-optimized for mobile devices
- Keyboard navigation and screen reader support

---

## Performance

- Lazy loading (controllers initialize when needed)
- Event delegation for efficient handling
- Debounced inputs to prevent excessive API calls
- Proper cleanup on disconnect
- Minimal bundle size

---

*For implementation details, see controller files in `app/javascript/controllers/`*
