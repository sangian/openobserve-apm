# File Structure

```
.
├── README.md                    # Quick start guide
├── SETUP.md                     # Detailed setup guide
├── ARCHITECTURE.md              # System design & data flow
├── TROUBLESHOOTING.md           # Common issues & solutions
├── QUICK-REFERENCE.md           # Commands cheat sheet
├── FILES.md                     # This file
├── LICENSE                      # MIT License
├── .gitignore                   # Git ignore rules
├── .env.example                 # Environment template
├── docker-compose.yml           # OpenObserve service
├── docker-compose.traefik.yml   # Traefik reverse proxy
├── setup.sh                     # Interactive preset selector
├── start.sh                     # Startup script
├── stop.sh                      # Shutdown script
├── generate-password.sh         # Traefik password generator
├── presets/                     # VPS resource presets
│   ├── 4gb.env                  # 4GB RAM preset
│   ├── 8gb.env                  # 8GB RAM preset
│   ├── 12gb.env                 # 12GB RAM preset
│   └── 24gb.env                 # 24GB RAM preset
└── traefik/                     # Traefik configuration
    ├── traefik.yml              # Static config
    └── dynamic/
        └── middlewares.yml      # Dynamic config (extensible)
```

## Docker Compose Files

### `docker-compose.yml`
OpenObserve service with:
- Resource limits from presets
- Health checks
- Traefik labels for routing (UI, OTLP HTTP, OTLP gRPC)
- Storage configuration (local or S3)
- Log rotation

### `docker-compose.traefik.yml`
Traefik reverse proxy with:
- Let's Encrypt SSL (HTTP challenge)
- HTTP → HTTPS redirect
- Dashboard with Basic Auth
- Security headers
- OTLP gRPC entrypoint on port 4317

## Scripts

| Script | Purpose |
|--------|---------|
| `setup.sh` | Select VPS preset, generate `.env` from `.env.example` + preset |
| `start.sh` | Validate config, create network, start Traefik + OpenObserve |
| `stop.sh` | Graceful shutdown with `--with-traefik` and `--remove-volumes` options |
| `generate-password.sh` | Generate htpasswd hash for Traefik dashboard |

## Docker Volumes

| Volume | Purpose |
|--------|---------|
| `openobserve-data` | OpenObserve data (WAL, streams, metadata) |
| `traefik-certificates` | Let's Encrypt SSL certificates |

## Docker Networks

| Network | Type | Purpose |
|---------|------|---------|
| `traefik-network` | External | Connects Traefik ↔ OpenObserve |
