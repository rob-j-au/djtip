# syntax=docker/dockerfile:1
# This Dockerfile is optimized for production deployment with layer caching best practices

# Use official Ruby image as base
ARG RUBY_VERSION=3.4.1
FROM ruby:${RUBY_VERSION}-slim AS base

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Install base dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set working directory
WORKDIR /rails

# ============================================================================
# Stage: Build dependencies
# ============================================================================
FROM base AS build

# Install build dependencies (these change rarely, so cache this layer)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    pkg-config \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy Gemfile and Gemfile.lock first (for better caching)
# These files change less frequently than application code
COPY Gemfile Gemfile.lock ./

# Install Ruby gems
# This layer is cached unless Gemfile or Gemfile.lock changes
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    find "${BUNDLE_PATH}" -name "*.o" -delete && \
    find "${BUNDLE_PATH}" -name "*.c" -delete && \
    bundle exec bootsnap precompile --gemfile

# Copy application code (excludes files listed in .dockerignore)
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets
# SECRET_KEY_BASE is required for asset precompilation but not used at runtime
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# ============================================================================
# Stage: Final production image
# ============================================================================
FROM base

# Copy installed gems from build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"

# Copy application code and precompiled assets from build stage
COPY --from=build /rails /rails

# Create non-root user for running the application
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p db log storage tmp && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Expose port 3000
EXPOSE 3000

# Start the server by default
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
