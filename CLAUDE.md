# Claude Development Notes

## Ruby Version Management

This project uses **RVM (Ruby Version Manager)** with **Ruby 3.4.1**.

### Running Ruby Commands

All Ruby commands should be executed using RVM to ensure the correct Ruby version:

```bash
# Load RVM and use the correct Ruby version
rvm use 3.4.1

# Or use the project's .ruby-version file
rvm use

# Run Ruby commands
bundle install
bundle exec rails server
bundle exec rspec
bundle exec rake db:seed
```

### RVM Setup

If RVM is not installed:

```bash
# Install RVM
\curl -sSL https://get.rvm.io | bash -s stable

# Install Ruby 3.4.1
rvm install 3.4.1

# Set as default (optional)
rvm use 3.4.1 --default
```

### Project Files

- **Gemfile**: Specifies `ruby "3.4.1"`
- **.ruby-version**: Contains `3.4.1` for automatic RVM switching
- **Dockerfile**: Uses `RUBY_VERSION=3.4.1`

### Important Notes

- Always ensure you're using the correct Ruby version before running commands
- RVM will automatically switch to Ruby 3.4.1 when entering the project directory if configured
- For Docker deployments, the Dockerfile handles Ruby version management

---

## Rails 8.1.3 Upgrade (April 13, 2026)

### Upgrade Summary

Successfully upgraded from Rails 8.0.2 to Rails 8.1.3 with Mongoid 9.0.10.

### Changes Made

1. **Gemfile Updates:**
   - Rails: `~> 8.0.2` → `~> 8.1.3`
   - Mongoid: `~> 8.1` → `~> 9.0` (required for Rails 8.1 compatibility)

2. **Dependencies Updated:**
   - All Rails gems updated to 8.1.3
   - Mongoid updated to 9.0.10 (supports activemodel < 8.2)
   - Various supporting gems updated automatically

### Key Rails 8.1 Changes to Note

#### Schema Changes
- **Table columns in schema.rb are now sorted alphabetically** by default
- This ensures consistent dumps across machines
- Reduces noisy diffs in version control
- If you need exact column order, use `structure.sql` instead

#### Breaking Changes (Minimal Impact)
1. **Action Pack:**
   - Removed deprecated support for leading brackets in parameter names
   - Removed deprecated semicolon as query string separator

2. **Railties:**
   - Removed deprecated `rails/console/methods.rb` file
   - Removed deprecated `bin/rake stats` command
   - Removed deprecated `STATS_DIRECTORIES` constant

3. **Active Record:**
   - Removed deprecated `:retries` option for SQLite3 adapter (not applicable - using MongoDB)
   - Removed deprecated `:unsigned_float` and `:unsigned_decimal` for MySQL (not applicable)

#### New Features Available
1. **Active Job Continuations** - Long-running jobs can be broken into discrete steps
2. **Structured Event Reporting** - `Rails.event.notify()` for structured logging
3. **Local CI** - Built-in CI support
4. **Markdown Rendering** - Native markdown support
5. **Command-line Credentials Fetching** - Easier credential management

### Mongoid 9.0 Compatibility

Mongoid 9.0.10 is fully compatible with Rails 8.1.3:
- Supports activemodel >= 5.1, < 8.2
- No breaking changes affecting this project
- All existing Mongoid functionality preserved

### Post-Upgrade Tasks ✅ COMPLETED

1. ✅ **Updated `config.load_defaults` to `8.1`**
   - Framework defaults updated in `config/application.rb`
   - Created `config/initializers/new_framework_defaults_8_1.rb`

2. ✅ **Fixed Deprecation Warning:**
   - Changed `config.fixture_path` to `config.fixture_paths` (plural) in `spec/rails_helper.rb`

3. ✅ **Test Suite Results:**
   - **243 examples, 1 failure** (pre-existing, unrelated to upgrade)
   - **0 deprecation warnings**
   - All Rails 8.1 functionality working correctly

4. ✅ **Verified Versions:**
   - Rails: **8.1.3** ✓
   - Mongoid: **9.0.10** ✓
   - Ruby: **3.4.1** ✓

### Verification Commands

```bash
# Check Rails version
bin/rails --version

# Check Mongoid version
bundle info mongoid

# Run tests
bundle exec rspec

# Start server
bin/rails server
```

### References

- [Rails 8.1 Release Notes](https://guides.rubyonrails.org/8_1_release_notes.html)
- [Upgrading Ruby on Rails Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [Mongoid 9.0 Documentation](https://www.mongodb.com/docs/mongoid/current/)
