# Docker Deployment Guide

This guide covers building and deploying the DJ Tip Rails application using Docker.

## Prerequisites

- Docker 20.10 or later
- Docker Compose 2.0 or later (for local development)

## Dockerfile Features

The Dockerfile implements best practices for layer caching and production deployment:

### Multi-Stage Build
- **Build stage**: Compiles gems, precompiles assets, and prepares bootsnap cache
- **Final stage**: Contains only runtime dependencies and compiled artifacts

### Layer Caching Optimization
1. **Base dependencies** (rarely change) - cached efficiently
2. **Gemfile/Gemfile.lock** (change occasionally) - separate layer
3. **Application code** (changes frequently) - copied last
4. **Asset precompilation** - only runs when code or assets change

### Security & Performance
- Runs as non-root user (UID 1000)
- Uses jemalloc for better memory management
- Minimal final image size (only production dependencies)
- Bootsnap precompilation for faster boot times

## Building the Image

### Basic Build
```bash
docker build -t djtip:latest .
```

### Build with Custom Ruby Version
```bash
docker build --build-arg RUBY_VERSION=3.4.1 -t djtip:latest .
```

### Build for Production
```bash
docker build -t robj/djtip:latest .
docker push robj/djtip:latest
```

## Running with Docker Compose

### 1. Create Environment File
```bash
cp .env.example .env
# Edit .env and add your credentials
```

Required environment variables:
- `RAILS_MASTER_KEY` - Your Rails master key from `config/master.key`
- `GOOGLE_MAPS_API_KEY` - Google Maps API key
- `IPINFO_API_KEY` - (Optional) IPInfo API key

### 2. Start All Services
```bash
docker-compose up -d
```

This starts:
- MongoDB database
- Redis cache
- Rails web server (port 3000)
- Sidekiq background worker

### 3. View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f sidekiq
```

### 4. Stop Services
```bash
docker-compose down
```

### 5. Stop and Remove Volumes
```bash
docker-compose down -v
```

## Running Standalone Container

### With External MongoDB and Redis
```bash
docker run -d \
  --name djtip-web \
  -p 3000:3000 \
  -e RAILS_ENV=production \
  -e MONGODB_URL=mongodb://your-mongodb:27017/performer_tip_production \
  -e REDIS_URL=redis://your-redis:6379/0 \
  -e RAILS_MASTER_KEY=your_master_key \
  -e GOOGLE_MAPS_API_KEY=your_api_key \
  robj/djtip:latest
```

## Database Setup

The entrypoint script automatically runs `rails db:prepare` which:
- Creates the database if it doesn't exist
- Runs pending migrations
- Seeds the database (if needed)

### Manual Database Commands
```bash
# Run migrations
docker-compose exec web rails db:migrate

# Seed database
docker-compose exec web rails db:seed

# Rails console
docker-compose exec web rails console

# Reset database (WARNING: destroys data)
docker-compose exec web rails db:reset
```

## Kubernetes Deployment

The Helm chart in `.cicd/helm/djtip/` is configured to use this Docker image.

### Update Image Tag
Edit `.cicd/helm/djtip/values.yaml`:
```yaml
image:
  repository: robj/djtip
  tag: "latest@sha256:your-image-digest"
```

### Deploy to Kubernetes
```bash
helm upgrade --install djtip .cicd/helm/djtip \
  --set image.tag=latest \
  --set-string env.RAILS_MASTER_KEY=your_master_key \
  --set-string env.GOOGLE_MAPS_API_KEY=your_api_key
```

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker logs djtip-web

# Check if MongoDB is accessible
docker-compose exec web nc -zv mongodb 27017
```

### Asset Precompilation Fails
```bash
# Rebuild without cache
docker build --no-cache -t djtip:latest .
```

### Permission Issues
The application runs as user `rails` (UID 1000). Ensure mounted volumes have correct permissions:
```bash
chown -R 1000:1000 storage/ tmp/ log/
```

### Memory Issues
The Dockerfile uses jemalloc for better memory management. If you experience issues:
```bash
# Disable jemalloc
docker run -e LD_PRELOAD= djtip:latest
```

## Development vs Production

This Dockerfile is optimized for **production**. For development:
- Use `docker-compose.dev.yml` (if available)
- Mount source code as volume for live reloading
- Use `RAILS_ENV=development`

## Image Size Optimization

Current optimizations:
- Multi-stage build (removes build dependencies)
- Slim base image
- Cleaned gem cache
- Only production gems installed

Typical image size: ~500-800 MB

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Build and push Docker image
  run: |
    docker build -t robj/djtip:${{ github.sha }} .
    docker push robj/djtip:${{ github.sha }}
```

### Update Helm Chart
```bash
# Update values.yaml with new image digest
kubectl set image deployment/djtip djtip=robj/djtip:$NEW_TAG
```
