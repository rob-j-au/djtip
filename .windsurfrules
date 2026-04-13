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
