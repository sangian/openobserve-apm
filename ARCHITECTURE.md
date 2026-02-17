# Architecture Overview

## System Architecture

OpenObserve is a single binary that handles UI, API, data ingestion, storage, and querying — no separate database required.

```
                                    Internet
                                       │
                                       │ HTTPS / gRPC
                                       │
                              ┌────────▼─────────┐
                              │                   │
                              │     Traefik       │
                              │  Reverse Proxy    │
                              │                   │
                              │  Port 80  → 443   │
                              │  Port 443 (HTTPS) │
                              │  Port 4317 (gRPC) │
                              │                   │
                              └────────┬──────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                   │
          observe.domain        otel.domain        otel-grpc.domain
                    │                  │                   │
                    ▼                  ▼                   ▼
              ┌─────────────────────────────────────────────────┐
              │                                                 │
              │                 OpenObserve                     │
              │                                                 │
              │  ┌───────────┐  ┌────────────┐  ┌───────────┐  │
              │  │  Web UI   │  │  OTLP HTTP │  │ OTLP gRPC │  │
              │  │           │  │  Receiver  │  │ Receiver  │  │
              │  │  :5080    │  │  :5080     │  │  :5081    │  │
              │  └───────────┘  └────────────┘  └───────────┘  │
              │                                                 │
              │  ┌───────────────────────────────────────────┐  │
              │  │         Storage Engine                    │  │
              │  │   Local Disk (/data)  OR  S3-Compatible  │  │
              │  └───────────────────────────────────────────┘  │
              │                                                 │
              └─────────────────────────────────────────────────┘
```

## Data Flow

### 1. Telemetry Ingestion

```
Application
    │
    ├─ OTLP/HTTP ──→ Traefik (otel.domain:443) ──→ OpenObserve :5080
    │                  (TLS termination)              /api/{org}/v1/traces
    │                                                 /api/{org}/v1/metrics
    │                                                 /api/{org}/v1/logs
    │
    └─ OTLP/gRPC ──→ Traefik (otel-grpc.domain:4317) ──→ OpenObserve :5081
                       (TLS passthrough)
```

### 2. User Access

```
User ──→ Traefik (observe.domain:443) ──→ OpenObserve :5080 (Web UI + API)
          (HTTPS + security headers)
```

## Network Configuration

### External Network
- **traefik-network**: Connects Traefik with OpenObserve for reverse proxying

### Exposed Ports
| Port | Protocol | Purpose |
|------|----------|---------|
| 80 | HTTP | Let's Encrypt challenge + HTTPS redirect |
| 443 | HTTPS | UI, API, OTLP HTTP (subdomain-routed) |
| 4317 | gRPC/TLS | OTLP gRPC ingestion (subdomain-routed) |
| 8081 | HTTP | Traefik Dashboard (localhost only) |

### Internal Ports (Docker Network Only)
| Port | Service | Purpose |
|------|---------|---------|
| 5080 | OpenObserve | HTTP: UI + API + OTLP HTTP |
| 5081 | OpenObserve | gRPC: OTLP gRPC receiver |

## Storage

### Local Disk Mode (Default)

```
OpenObserve Container
    │
    └─ /data/  (Docker volume: openobserve-data)
        ├── wal/        # Write-Ahead Log
        ├── stream/     # Compressed data files
        └── meta/       # Metadata (SQLite)
```

### S3 Mode

```
OpenObserve Container
    │
    ├─ /data/           # WAL + cache (local volume, still needed)
    │   ├── wal/
    │   └── meta/
    │
    └─ S3 Bucket        # Compressed data files
        └── stream/
```

## Resource Allocation

### Comparison: OpenObserve vs SkyWalking

OpenObserve's single-binary architecture is significantly simpler:

| | SkyWalking | OpenObserve |
|---|---|---|
| Containers | 3-4 (OAP + DB + UI + Traefik) | 2 (OpenObserve + Traefik) |
| Min RAM | ~4GB | ~2GB |
| Language | Java (JVM) | Rust (native) |
| Database | BanyanDB (separate) | Built-in |
| Auth | External proxy | Built-in |

### Preset Summary

| Preset | OpenObserve | Traefik | Total | OS Reserve |
|--------|-------------|---------|-------|------------|
| 4GB | 3GB / 3 CPU | 192MB / 0.5 CPU | ~3.2GB | ~800MB |
| 8GB | 6GB / 4 CPU | 256MB / 0.5 CPU | ~6.3GB | ~1.7GB |
| 12GB | 9GB / 5 CPU | 256MB / 0.5 CPU | ~9.3GB | ~2.7GB |
| 24GB | 19GB / 7 CPU | 512MB / 1 CPU | ~19.5GB | ~4.5GB |

## OpenObserve Key Tuning Parameters

| Parameter | Description | Effect |
|-----------|-------------|--------|
| `ZO_MEM_TABLE_MAX_SIZE` | Max in-memory table size before flush | Higher = better write throughput, more RAM |
| `ZO_COMPACT_MAX_FILE_SIZE` | Max size of compacted data files | Higher = fewer files, larger reads |
| `ZO_COMPACT_INTERVAL` | Seconds between compaction runs | Lower = fresher data, more CPU |
| `ZO_DATA_WAL_MEMORY_MODE_ENABLED` | Keep WAL in memory | Faster writes, risk of data loss on crash |
| `ZO_COMPACT_DATA_RETENTION_DAYS` | Days to retain data | Controls disk usage |

## Security Features

- **Traefik**: Auto HTTPS, HSTS, XSS protection, content-type nosniff, frame deny
- **OpenObserve**: Built-in user authentication (email/password)
- **OTLP**: Basic Auth required for ingestion
- **Network**: Services only exposed via Traefik, no direct port publishing

## Supported Signals

| Signal | OTLP/HTTP | OTLP/gRPC |
|--------|-----------|-----------|
| Traces | ✅ | ✅ |
| Metrics | ✅ | ✅ |
| Logs | ✅ | ✅ |
