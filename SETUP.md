# Setup Guide

## Prerequisites

- **VPS**: Ubuntu 22.04+ (or any Linux with Docker support), 4GB+ RAM
- **Docker**: 20.10+ with Compose v2
- **Domain**: DNS A records pointing to your VPS IP
- **Firewall**: Ports 80, 443, 4317 open

### DNS Configuration

Create the following DNS A records pointing to your VPS IP:

| Record | Type | Value |
|--------|------|-------|
| `observe.yourdomain.com` | A | Your VPS IP |
| `traefik.yourdomain.com` | A | Your VPS IP |
| `otel.yourdomain.com` | A | Your VPS IP |
| `otel-grpc.yourdomain.com` | A | Your VPS IP |

### Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Verify
docker --version
docker compose version
```

## Installation

### 1. Clone Repository

```bash
git clone https://github.com/sangian/openobserve-apm.git
cd openobserve-apm
```

### 2. Run Setup Script

```bash
# Interactive mode
./setup.sh

# Or specify preset directly
./setup.sh 8gb
```

This copies `.env.example` to `.env` and appends the selected resource preset.

### 3. Configure Environment

Edit `.env` with your settings:

```bash
nano .env
```

**Required changes:**

```env
# Your domains
OPENOBSERVE_DOMAIN=observe.yourdomain.com
TRAEFIK_DOMAIN=traefik.yourdomain.com
OTEL_DOMAIN=otel.yourdomain.com
OTEL_GRPC_DOMAIN=otel-grpc.yourdomain.com

# SSL email
LETSENCRYPT_EMAIL=you@yourdomain.com

# OpenObserve credentials (CHANGE THESE!)
ZO_ROOT_USER_EMAIL=admin@yourdomain.com
ZO_ROOT_USER_PASSWORD=YourStrongPassword123!

# Traefik dashboard password (generate with ./generate-password.sh)
TRAEFIK_DASHBOARD_USERS=admin:$$apr1$$...
```

### 4. Generate Traefik Password

```bash
./generate-password.sh
```

Copy the output to `TRAEFIK_DASHBOARD_USERS` in `.env`.

### 5. Start Services

```bash
./start.sh
```

### 6. Verify

- **OpenObserve UI**: `https://observe.yourdomain.com`
- **Traefik Dashboard**: `https://traefik.yourdomain.com/dashboard/`

## Storage Configuration

### Local Disk (Default)

Data is stored in a Docker volume mounted at `/data` inside the container. No additional configuration needed.

### S3-Compatible Storage

OpenObserve supports S3-compatible storage for data (Contabo Object Storage, MinIO, AWS S3, etc.):

```env
ZO_LOCAL_MODE_STORAGE=s3
ZO_S3_SERVER_URL=https://eu2.contabostorage.com
ZO_S3_REGION_NAME=EU
ZO_S3_ACCESS_KEY=your-access-key
ZO_S3_SECRET_KEY=your-secret-key
ZO_S3_BUCKET_NAME=openobserve
```

> **Note:** Even with S3 storage, OpenObserve still uses local disk for WAL (Write-Ahead Log) and caching. The Docker volume remains necessary.

## OpenTelemetry Integration

### Configure Your Application

OpenObserve accepts OTLP data natively. Configure your OpenTelemetry SDK:

#### OTLP/HTTP

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=https://otel.yourdomain.com
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic $(echo -n 'admin@yourdomain.com:YourPassword' | base64)"
```

#### OTLP/gRPC

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=https://otel-grpc.yourdomain.com:4317
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic $(echo -n 'admin@yourdomain.com:YourPassword' | base64)"
```

> **Important:** OpenObserve requires Basic Auth for OTLP ingestion. Include the `Authorization` header.

### Python Example

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
import base64

credentials = base64.b64encode(b"admin@yourdomain.com:YourPassword").decode()

exporter = OTLPSpanExporter(
    endpoint="https://otel.yourdomain.com/api/default/v1/traces",
    headers={"Authorization": f"Basic {credentials}"}
)

trace.set_tracer_provider(TracerProvider())
trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(exporter))

tracer = trace.get_tracer(__name__)
with tracer.start_as_current_span("my-operation"):
    pass  # Your code here
```

### .NET Example

```csharp
using OpenTelemetry;
using OpenTelemetry.Trace;
using System.Net.Http.Headers;

var credentials = Convert.ToBase64String(
    System.Text.Encoding.UTF8.GetBytes("admin@yourdomain.com:YourPassword"));

Sdk.CreateTracerProviderBuilder()
    .AddOtlpExporter(opt =>
    {
        opt.Endpoint = new Uri("https://otel.yourdomain.com/api/default/");
        opt.Protocol = OpenTelemetry.Exporter.OtlpExportProtocol.HttpProtobuf;
        opt.Headers = $"Authorization=Basic {credentials}";
    })
    .Build();
```

## Security

### Firewall

```bash
sudo ufw allow 80/tcp    # HTTP (Let's Encrypt + redirect)
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 4317/tcp  # OTLP gRPC
sudo ufw enable
```

### Checklist

- [ ] Changed `ZO_ROOT_USER_PASSWORD` from default
- [ ] Changed `TRAEFIK_DASHBOARD_USERS` from default
- [ ] Set valid `LETSENCRYPT_EMAIL`
- [ ] DNS records point to VPS
- [ ] Firewall configured
- [ ] Regular backups scheduled

## Backup & Restore

### Backup

```bash
mkdir -p backup

# Backup OpenObserve data
docker run --rm \
  -v openobserve-apm_openobserve-data:/data \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/openobserve-$(date +%Y%m%d).tar.gz /data

# Backup Traefik certificates
docker run --rm \
  -v openobserve-apm_traefik-certificates:/certs \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/traefik-$(date +%Y%m%d).tar.gz /certs
```

### Restore

```bash
docker compose down

docker run --rm \
  -v openobserve-apm_openobserve-data:/data \
  -v $(pwd)/backup:/backup \
  alpine tar xzf /backup/openobserve-YYYYMMDD.tar.gz -C /

docker compose up -d
```

## Maintenance

### Update OpenObserve

```bash
docker compose pull
docker compose up -d
```

### View Logs

```bash
docker compose logs -f openobserve
docker compose -f docker-compose.traefik.yml logs -f traefik
```

### Resource Monitoring

```bash
docker stats
```
