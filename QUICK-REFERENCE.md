# Quick Reference

## Installation

```bash
git clone https://github.com/sangian/openobserve-apm.git
cd openobserve-apm

# Ensure external Traefik network exists
docker network create traefik-network

./setup.sh          # Select VPS preset
nano .env           # Configure domains + credentials
./start.sh          # Launch OpenObserve
```

## Service Management

```bash
# Start
./start.sh

# Stop
./stop.sh

# Stop and delete all data
./stop.sh --remove-volumes

# Restart OpenObserve
docker compose restart openobserve

# View logs
docker compose logs -f openobserve

# Check status
docker compose ps
docker stats
```

## Health Checks

```bash
# OpenObserve
docker exec openobserve wget -q -O- http://localhost:5080/healthz
```

## Update

```bash
docker compose pull
docker compose up -d
```

## Backup & Restore

```bash
# Backup
mkdir -p backup
docker run --rm \
  -v openobserve-apm_openobserve-data:/data \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/openobserve-$(date +%Y%m%d).tar.gz /data

# Restore
docker compose down
docker run --rm \
  -v openobserve-apm_openobserve-data:/data \
  -v $(pwd)/backup:/backup \
  alpine tar xzf /backup/openobserve-YYYYMMDD.tar.gz -C /
docker compose up -d
```

## URLs

| Service | URL |
|---------|-----|
| OpenObserve UI | `https://${OPENOBSERVE_DOMAIN}` |
| OTLP HTTP | `https://${OTEL_DOMAIN}/api/default/v1/traces` |
| OTLP gRPC | `${OTEL_GRPC_DOMAIN}:4317` |

## Ports

| Port | Purpose |
|------|---------|
| 5080 | OpenObserve HTTP (internal) |
| 5081 | OpenObserve gRPC (internal) |

Note: External ports (80, 443, 4317) are managed by your external Traefik instance.

## Key Environment Variables

| Variable | Description |
|----------|-------------|
| `OPENOBSERVE_DOMAIN` | Domain for UI |
| `OTEL_DOMAIN` | OTLP HTTP subdomain |
| `OTEL_GRPC_DOMAIN` | OTLP gRPC subdomain |
| `ZO_ROOT_USER_EMAIL` | Admin email |
| `ZO_ROOT_USER_PASSWORD` | Admin password |
| `ZO_LOCAL_MODE_STORAGE` | `disk` or `s3` |
| `ZO_COMPACT_DATA_RETENTION_DAYS` | Data retention (days) |

## Test Ingestion

```bash
# Send test log
curl -u "admin@yourdomain.com:password" \
  -X POST "https://otel.yourdomain.com/api/default/_json" \
  -H "Content-Type: application/json" \
  -d '[{"message": "test", "level": "info"}]'
```

## Security Checklist

- [ ] Changed `ZO_ROOT_USER_PASSWORD`
- [ ] DNS records configured
- [ ] External Traefik configured with SSL
- [ ] Backups scheduled
