# DJ Tip App

A modern Ruby on Rails 8.1 application for managing DJ events and tips, built with MongoDB, deployed on Kubernetes, and featuring production-grade observability.

## 🎯 Overview

DJ Tip is a full-stack web application that allows event organizers to manage DJ events, track attendees, and collect tips for performers. Built with modern technologies and best practices, it includes:

- **Rails 8.1** with Mongoid 9 (MongoDB ODM)
- **daisyUI 5** + Tailwind CSS for beautiful, responsive UI
- **Kubernetes deployment** via ArgoCD GitOps
- **Production observability** with OpenTelemetry, Prometheus, Grafana, Loki, and Tempo
- **Docker containerization** with multi-stage builds
- **Devise authentication** with user management
- **Shrine file uploads** for user avatars
- **Sidekiq** for background job processing
- **Comprehensive testing** with RSpec

## 🔐 Admin Access

**Email:** admin@djtip.com  
**Password:** password123

## ✨ Features

### Core Functionality
- **Event Management**: Create and manage DJ events with dates, locations, and details
- **User Management**: User registration, authentication, and profile management
- **Tip Tracking**: Track and manage tips for DJs/performers
- **Image Uploads**: User profile images with Shrine and image processing
- **Geocoding**: Location-based features with Geocoder gem

### UI/UX
- **daisyUI 5 Components**: Modern, accessible component library
- **Tailwind CSS**: Utility-first styling with custom theme
- **Responsive Design**: Mobile-first, works on all devices
- **Dark Mode**: Theme switching with localStorage persistence
- **Stimulus Controllers**: Interactive JavaScript features

### DevOps & Observability
- **Kubernetes Deployment**: Helm charts with ArgoCD GitOps
- **OpenTelemetry Tracing**: Distributed tracing for all requests
- **Prometheus Metrics**: Application and business metrics
- **Grafana Dashboards**: Visualization and monitoring
- **Loki Log Aggregation**: Centralized logging
- **Tempo Distributed Tracing**: Request flow visualization

## 🚀 Quick Start

### Local Development

#### Prerequisites
- Ruby 3.4.1
- MongoDB 7.0+
- Redis 7.0+
- Node.js 18+ (for Tailwind CSS)

#### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/rob-j-au/djtip.git
   cd djtip
   ```

2. **Install dependencies:**
   ```bash
   bundle install
   ```

3. **Start services:**
   ```bash
   # MongoDB
   brew services start mongodb-community
   
   # Redis
   brew services start redis
   ```

4. **Setup database:**
   ```bash
   rails db:seed
   ```

5. **Start the Rails server:**
   ```bash
   bin/dev
   ```

6. **Visit the application:**
   Open `http://localhost:3000`

### Docker Development

```bash
# Build and run with Docker Compose
docker-compose up

# Access at http://localhost:3000
```

See `docs/DOCKER.md` for detailed Docker instructions.

### Kubernetes Deployment

**Quick setup with automated TLS:**

```bash
# 1. Setup DNS and TLS certificates
cd .terraform/cloudflare && terraform init && terraform apply
export CLOUDFLARE_API_TOKEN="your-token"
./scripts/setup-cert-manager-wildcard.sh

# 2. Deploy infrastructure
kubectl apply -f .cicd/argocd/haproxy-ingress-app.yaml
kubectl apply -f .cicd/argocd/observability-app.yaml

# 3. Deploy application
kubectl apply -f .cicd/argocd/djtip-development.yaml

# Done! Access at https://app.dev.yourdomain.com
```

**Environments:**
- **Development**: `app.dev.yourdomain.com` - 2 pods, auto-sync
- **Staging**: `app.staging.yourdomain.com` - 4 pods, auto-sync
- **Production**: `app.yourdomain.com` - 4 pods, manual sync

📖 **Guides:**
- [Complete Setup](docs/CERT_MANAGER.md) - TLS certificates with cert-manager
- [ArgoCD Deployment](docs/ARGO.md) - Full Kubernetes guide
- [Terraform DNS](.terraform/cloudflare/README.md) - DNS automation

## Usage

1. **Create Events**: Start by creating events from the main page
2. **Add Users**: Register users and optionally assign them to events
3. **Add Performers**: Add performers and assign them to events
4. **Manage Relationships**: View events to see associated users and performers

### 🛠 Tech Stack

**Backend:**
- Rails 8.1.3
- Ruby 3.4.1
- Mongoid 9.0 (MongoDB ODM)
- Devise 4.9 (Authentication)
- Sidekiq 8.0 (Background Jobs)
- Shrine (File Uploads)

**Frontend:**
- daisyUI 5 (Component Library)
- Tailwind CSS 4 (Styling)
- Stimulus (JavaScript)
- Turbo (SPA-like Navigation)
- Importmap (JavaScript Modules)

**Observability:**
- OpenTelemetry (Distributed Tracing)
- Prometheus (Metrics)
- Grafana (Visualization)
- Loki (Log Aggregation)
- Tempo (Trace Storage)

**Infrastructure:**
- Docker (Containerization)
- Kubernetes (Orchestration)
- ArgoCD (GitOps)
- Helm (Package Management)
- HAProxy Ingress (Load Balancing)
- cert-manager (Automated TLS with Let's Encrypt)

### 📁 Project Structure

```
djtip/
├── app/
│   ├── controllers/           # Rails controllers
│   ├── models/               # Mongoid models
│   │   └── concerns/         # Traceable, BusinessMetrics
│   ├── views/                # ERB templates with daisyUI
│   ├── uploaders/            # Shrine uploaders
│   └── jobs/                 # Sidekiq background jobs
├── config/
│   ├── initializers/         # OpenTelemetry, Prometheus, etc.
│   ├── mongoid.yml           # MongoDB configuration
│   └── routes.rb             # Application routes
├── .cicd/
│   ├── helm/                 # Helm charts
│   │   ├── djtip/           # Application chart
│   │   └── observability/   # Observability stack
│   └── argocd/              # ArgoCD applications
├── docs/                     # Documentation
│   ├── CERT_MANAGER.md      # TLS certificates
│   ├── ENDPOINTS.md         # Service URLs
│   ├── DEPLOYMENT.md        # Deployment guide
│   ├── OBSERVABILITY.md     # Monitoring stack
│   └── STIMULUS.md          # JavaScript features
└── spec/                     # RSpec tests
```

## 📚 Documentation

### Setup & Deployment
- **[Service Endpoints](docs/ENDPOINTS.md)** - URLs for all environments
- **[cert-manager Setup](docs/CERT_MANAGER.md)** - Wildcard TLS with Cloudflare DNS-01
- **[ArgoCD & Kubernetes](docs/ARGO.md)** - Complete deployment guide
- **[Docker Setup](docs/DOCKER.md)** - Docker and Docker Compose
- **[Pi Deployment](.cicd/argocd/pi/README.md)** - Raspberry Pi Kubernetes cluster
- **[Terraform DNS](.terraform/cloudflare/README.md)** - DNS automation

### Observability & Monitoring
- **[Observability Stack](docs/OBSERVABILITY.md)** - Prometheus, Grafana, Loki, Tempo
- **[Application Instrumentation](docs/INSTRUMENTATION.md)** - OpenTelemetry setup
- **[OpenTelemetry Enhancements](docs/OTEL_ENHANCEMENTS.md)** - Rails-specific tracing
- **[Observability Naming](docs/OBSERVABILITY_NAMING.md)** - Naming conventions

### Development & Features
- **[API Documentation](docs/API_DOCUMENTATION.md)** - REST API reference
- **[Google Maps Setup](docs/GOOGLE_MAPS_SETUP.md)** - Maps integration
- **[Stimulus Controllers](docs/STIMULUS.md)** - Interactive JavaScript features

### Operations
- **[Deployment Guide](docs/DEPLOYMENT.md)** - Complete deployment summary

## 🔍 Observability

**Production-grade monitoring and tracing:**

- ✅ **Distributed tracing** with OpenTelemetry
- ✅ **Automatic log-trace correlation** - Link logs to traces
- ✅ **User context in traces** - Track user actions
- ✅ **Slow query detection** - Automatic alerts (>100ms)
- ✅ **Business metrics** - Custom metrics tracking
- ✅ **Enhanced Sidekiq tracing** - Background job visibility

**Access:**
- **Local**: http://localhost:3000/metrics
- **Kubernetes**: https://grafana.{env}.yourdomain.com

See [Observability Stack](docs/OBSERVABILITY.md) for complete guide.

## 🧪 Testing

```bash
bundle exec rspec                    # Run all tests
COVERAGE=true bundle exec rspec      # With coverage report
bundle exec rspec spec/models/       # Specific tests
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

Built with modern Rails best practices and production-grade observability.
