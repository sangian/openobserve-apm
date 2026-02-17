# OpenObserve APM - Production Docker Setup

Production-grade Docker Compose setup for [OpenObserve](https://openobserve.ai/) — a high-performance, Rust-based observability platform that accepts logs, metrics, and traces via OpenTelemetry (OTLP). Designed to work with an external Traefik reverse proxy.

## Features

- ✅ **OpenObserve v0.14.5** — Single binary, no separate database needed
- ✅ **OpenTelemetry native** — OTLP traces, metrics, and logs out of the box
- ✅ **External Traefik ready** — Works with external Traefik reverse proxy
- ✅ **VPS presets** for 4GB/8GB/12GB/24GB RAM
- ✅ **Flexible storage** — Local disk (default) or S3-compatible (Contabo, MinIO, AWS)
- ✅ **Built-in auth** — No external auth proxy needed
- ✅ **Production-ready** with health checks, resource limits, and log rotation
- ✅ **Written in Rust** — Low memory footprint, no JVM tuning

## Quick Start

```bash
# 1. Clone and configure
git clone https://github.com/sangian/openobserve-apm.git
cd openobserve-apm

# 2. Ensure external Traefik network exists
docker network create traefik-network

# 3. Run setup (select your VPS size)
./setup.sh

# 4. Edit .env with your domains and credentials
nano .env

# 5. Start OpenObserve
./start.sh

# 6. Access
# OpenObserve UI: https://observe.yourdomain.com
```

## Documentation

- 📖 **[Setup Guide](SETUP.md)** — Detailed installation and configuration
- 🏗️ **[Architecture](ARCHITECTURE.md)** — System design, data flow, network topology
- 🔧 **[Troubleshooting](TROUBLESHOOTING.md)** — Common issues and solutions
- 📚 **[Quick Reference](QUICK-REFERENCE.md)** — Commands cheat sheet
- 📁 **[File Structure](FILES.md)** — Repository file documentation

## Architecture

```
                         Internet
                            │ (External)
                     ┌──────▼──────┐
                     │   Traefik   │
                     │  :80 :443   │
                     │  :4317      │
                     └──────┬──────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
    observe.domain    otel.domain   otel-grpc.domain
              │             │             │
              └─────────────┼─────────────┘
                            │
                   ┌────────▼────────┐
                   │   OpenObserve   │
                   │  :5080 (HTTP)   │
                   │  :5081 (gRPC)   │
                   └─────────────────┘
```

## OpenTelemetry Endpoints

| Signal | Protocol | Endpoint |
|--------|----------|----------|
| Traces | OTLP/HTTP | `https://otel.yourdomain.com/api/default/v1/traces` |
| Metrics | OTLP/HTTP | `https://otel.yourdomain.com/api/default/v1/metrics` |
| Logs | OTLP/HTTP | `https://otel.yourdomain.com/api/default/v1/logs` |
| All | OTLP/gRPC | `https://otel-grpc.yourdomain.com:4317` |

> **Note:** OTLP HTTP requests require Basic Auth with your OpenObserve root credentials.

## Requirements

- Docker 20.10+
- Docker Compose 2.0+
- External Traefik reverse proxy with traefik-network
- Domain name with DNS configured
- VPS with 4GB+ RAM

## License

[MIT](LICENSE)
