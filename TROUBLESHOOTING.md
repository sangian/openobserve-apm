# Troubleshooting Guide

## Quick Diagnostics

```bash
echo "=== Services Status ==="
docker compose ps
echo ""
echo "=== Resource Usage ==="
docker stats --no-stream
echo ""
echo "=== OpenObserve Health ==="
docker exec openobserve wget -q -O- http://localhost:5080/healthz || echo "OpenObserve not accessible"
echo ""
echo "=== Networks ==="
docker network ls | grep traefik
```

## Common Issues

### 1. Services Won't Start

**Check logs:**
```bash
docker compose logs openobserve
```

**Insufficient memory:**
```bash
free -h
# If low, use a smaller preset: ./setup.sh 4gb
```

**Port conflicts (if exposing ports directly):**
```bash
sudo netstat -tlnp | grep -E ':(5080|5081)'
```

Note: Ports 80, 443, 4317 are managed by your external Traefik instance.

### 2. SSL Certificate Issues

SSL certificates are managed by your external Traefik instance.

**Verify DNS:**
```bash
dig +short observe.yourdomain.com
```

**Test certificate:**
```bash
curl -vI https://observe.yourdomain.com
```

**Solutions:**
- Ensure your external Traefik is properly configured for SSL
- Verify DNS A records point to your server IP
- Check your external Traefik logs for ACME/Let's Encrypt errors
- Ensure ports 80 and 443 are accessible to your Traefik instance

### 3. Cannot Access OpenObserve UI

```bash
# Check if OpenObserve is healthy
docker compose ps

# Verify network
docker network inspect traefik-network
```

**Solutions:**
- Ensure `traefik-network` exists and is connected to your external Traefik
- Check `OPENOBSERVE_DOMAIN` matches your DNS and Traefik configuration
- Verify your external Traefik is routing to the OpenObserve container
- Restart OpenObserve: `docker compose down && docker compose up -d`

### 4. Cannot Login to OpenObserve

- Verify `ZO_ROOT_USER_EMAIL` and `ZO_ROOT_USER_PASSWORD` in `.env`
- After changing credentials, you must recreate the container:
  ```bash
  docker compose down
  docker compose up -d
  ```
- Note: Changing root password after first run requires resetting the data volume

### 5. No Traces/Metrics/Logs Appearing

```bash
# Check OpenObserve logs for ingestion
docker compose logs openobserve | tail -100
```

**Common causes:**
- **Missing auth**: OpenObserve requires Basic Auth for OTLP. Include `Authorization` header.
- **Wrong endpoint**: OTLP HTTP goes to `https://otel.domain/api/default/v1/traces` (not `/v1/traces` directly)
- **Wrong org**: Default organization is `default`
- **Firewall**: Ensure port 4317 is open for gRPC

**Test ingestion:**
```bash
# Send a test log via curl
curl -u "admin@yourdomain.com:YourPassword" \
  -X POST "https://otel.yourdomain.com/api/default/_json" \
  -H "Content-Type: application/json" \
  -d '[{"message": "test log", "level": "info"}]'
```

### 6. High Memory Usage

```bash
docker stats --no-stream

# Check if OOM killed
dmesg | grep -i "out of memory"
```

**Solutions:**
- Use a smaller preset: `./setup.sh 4gb`
- Reduce `ZO_MEM_TABLE_MAX_SIZE`
- Set `ZO_DATA_WAL_MEMORY_MODE_ENABLED=false`
- Reduce `ZO_COMPACT_DATA_RETENTION_DAYS`

### 7. S3 Storage Issues

```bash
docker compose logs openobserve | grep -i "s3\|bucket\|storage"
```

**Checklist:**
- `ZO_LOCAL_MODE_STORAGE=s3` is set
- `ZO_S3_SERVER_URL` includes protocol (e.g., `https://eu2.contabostorage.com`)
- Bucket exists and is accessible with provided credentials
- Region matches your bucket's region

### 8. Disk Space Running Out

```bash
df -h
docker system df
```

**Solutions:**
- Reduce `ZO_COMPACT_DATA_RETENTION_DAYS`
- Switch to S3 storage for data
- Clean Docker resources: `docker system prune -a`
- Manually trigger compaction via OpenObserve API

## Emergency Recovery

### Complete Reset

```bash
./stop.sh --remove-volumes
docker network rm traefik-network 2>/dev/null
# Recreate network with external Traefik
docker network create traefik-network
./start.sh
```

### Backup Before Reset

```bash
mkdir -p backup/emergency
docker run --rm \
  -v openobserve-apm_openobserve-data:/data \
  -v $(pwd)/backup/emergency:/backup \
  alpine tar czf /backup/data-$(date +%Y%m%d-%H%M%S).tar.gz /data
```

## Collecting Diagnostics

```bash
cat > diagnostic-report.txt << EOF
=== System ===
$(uname -a)
$(free -h)
$(df -h)

=== Docker ===
$(docker --version)
$(docker compose version)

=== Services ===
$(docker compose ps)

=== Resources ===
$(docker stats --no-stream)

=== OpenObserve Logs (last 50) ===
$(docker compose logs --tail=50 openobserve)

=== Network ===
$(docker network inspect traefik-network)
EOF
```
