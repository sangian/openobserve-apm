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
├── setup.sh                     # Interactive preset selector
├── start.sh                     # Startup script
├── stop.sh                      # Shutdown script
├── generate-password.sh         # Password generator utility
└── presets/                     # VPS resource presets
    ├── 4gb.env                  # 4GB RAM preset
    ├── 8gb.env                  # 8GB RAM preset
    ├── 12gb.env                 # 12GB RAM preset
    └── 24gb.env                 # 24GB RAM preset
```

## Docker Compose Files

### `docker-compose.yml`
OpenObserve service with:
### `docker-compose.yml`
OpenObserve service with:
- Resource limits from presets
- Health checks
- Traefik labels for routing (UI, OTLP HTTP, OTLP gRPC)
- Storage configuration (local or S3)
- Log rotation
- External traefik-network integration

## Scripts

| Script | Purpose |
|--------|---------|
| `setup.sh` | Select VPS preset, generate `.env` from `.env.example` + preset |
| `start.sh` | Validate config, check network exists, start OpenObserve |
| `stop.sh` | Graceful shutdown with `--remove-volumes` option |
| `generate-password.sh` | Generate htpasswd hash for Basic Auth |

## Docker Volumes

| Volume | Purpose |
|--------|---------|
| `openobserve-data` | OpenObserve data (WAL, streams, metadata) |

## Docker Networks

| Network | Type | Purpose |
|---------|------|---------|
| `traefik-network` | External | Connects external Traefik ↔ OpenObserve |
