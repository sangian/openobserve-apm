# Quick Reference

## Installation

```bash
git clone https://github.com/sangian/openobserve-apm.git
cd openobserve-apm
./setup.sh          # Select VPS preset
nano .env           # Configure domains + credentials
./start.sh          # Launch everything
```

## Service Management

```bash
# Start
./start.sh

# Stop (OpenObserve only)
./stop.sh

# Stop everything
./stop.sh --with-traefik

# Stop and delete all data
./stop.sh --with-traefik --remove-volumes

# Restart OpenObserve
docker compose restart openobserve

# View logs
docker compose logs -f openobserve
docker compose -f docker-compose.traefik.yml logs -f traefik

# Check status
docker compose ps
docker stats
```

## Health Checks

```bash
# OpenObserve
docker exec openobserve wget -q -O- http://localhost:5080/healthz

# Traefik
docker exec traefik traefik healthcheck --ping
```

## Update

```bash
docker compose pull
docker compose up -d
docker compose -f docker-compose.traefik.yml pull
docker compose -f docker-compose.traefik.yml up -d
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
| Traefik Dashboard | `https://${TRAEFIK_DOMAIN}/dashboard/` |
| OTLP HTTP | `https://${OTEL_DOMAIN}/api/default/v1/traces` |
| OTLP gRPC | `${OTEL_GRPC_DOMAIN}:4317` |

## Ports

| Port | Purpose |
|------|---------|
| 80 | HTTP → HTTPS redirect |
| 443 | HTTPS (UI, API, OTLP HTTP) |
| 4317 | OTLP gRPC |
| 5080 | OpenObserve HTTP (internal) |
| 5081 | OpenObserve gRPC (internal) |
| 8081 | Traefik Dashboard (localhost) |

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
- [ ] Changed `TRAEFIK_DASHBOARD_USERS`
- [ ] Set `LETSENCRYPT_EMAIL`
- [ ] DNS records configured
- [ ] Firewall: allow 80, 443, 4317
- [ ] Backups scheduled
