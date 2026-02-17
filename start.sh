#!/bin/bash

# OpenObserve APM Startup Script
# This script helps you start the entire OpenObserve APM stack

set -e

echo "========================================"
echo "OpenObserve APM - Production Setup"
echo "========================================"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "ERROR: .env file not found!"
    echo ""
    echo "Run the setup script first:"
    echo "  ./setup.sh"
    echo ""
    echo "Or create .env manually:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    echo ""
    exit 1
fi

# Source .env safely
set -a
. ./.env
set +a

# Validate required variables
REQUIRED_VARS=("OPENOBSERVE_DOMAIN" "TRAEFIK_DOMAIN" "LETSENCRYPT_EMAIL" "ZO_ROOT_USER_EMAIL" "ZO_ROOT_USER_PASSWORD" "TRAEFIK_DASHBOARD_USERS")
MISSING_VARS=()

for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        MISSING_VARS+=("$VAR")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "ERROR: Required environment variables are missing:"
    for VAR in "${MISSING_VARS[@]}"; do
        echo "  - $VAR"
    done
    echo ""
    echo "Please configure these in your .env file"
    exit 1
fi

# Warn about default password
if [ "$ZO_ROOT_USER_PASSWORD" = "ChangeMe_StrongPassword123!" ]; then
    echo "⚠️  WARNING: You are using the default OpenObserve password!"
    echo "   Please change ZO_ROOT_USER_PASSWORD in .env before production use."
    echo ""
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running"
    echo "Please start Docker and try again"
    exit 1
fi

# Check if Docker Compose is available
if command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "ERROR: Docker Compose is not installed"
    echo "Please install Docker Compose v2 (preferred, 'docker compose') or the legacy 'docker-compose' binary"
    exit 1
fi

echo "✓ Using: $COMPOSE_CMD"
echo "✓ Environment configuration validated"
echo ""

# Create Traefik network if it doesn't exist
if ! docker network inspect traefik-network > /dev/null 2>&1; then
    echo "Creating traefik-network..."
    docker network create traefik-network
    echo "✓ Network created"
else
    echo "✓ Network traefik-network already exists"
fi
echo ""

# Function to check if a service is running
is_running() {
    [ "$(docker ps -q -f name=$1)" ] && return 0 || return 1
}

# Start Traefik
echo "========================================"
echo "Starting Traefik..."
echo "========================================"
if is_running "traefik"; then
    echo "Traefik is already running"
else
    $COMPOSE_CMD -f docker-compose.traefik.yml up -d
    echo "✓ Traefik started"
fi
echo ""

# Wait for Traefik to be ready
echo "Waiting for Traefik to be healthy..."
sleep 5
echo ""

# Start OpenObserve
echo "========================================"
echo "Starting OpenObserve..."
echo "========================================"
$COMPOSE_CMD up -d
echo ""

# Wait for service to start
echo "Waiting for OpenObserve to initialize..."
sleep 10
echo ""

# Check service health
echo "========================================"
echo "Service Status:"
echo "========================================"
$COMPOSE_CMD ps
echo ""

echo "========================================"
echo "Startup Complete!"
echo "========================================"
echo ""
echo "Access your services at:"
echo "  - OpenObserve UI:     https://${OPENOBSERVE_DOMAIN}"
echo "  - Traefik Dashboard:  https://${TRAEFIK_DOMAIN}/dashboard/"
echo ""
echo "OpenTelemetry endpoints:"
echo "  - OTLP HTTP:  https://${OTEL_DOMAIN:-otel.${OPENOBSERVE_DOMAIN}}"
echo "  - OTLP gRPC:  https://${OTEL_GRPC_DOMAIN:-otel-grpc.${OPENOBSERVE_DOMAIN}}:4317"
echo ""
echo "Note: SSL certificates may take a few minutes to be issued"
echo "      by Let's Encrypt on first startup."
echo ""
echo "Check logs with:"
echo "  $COMPOSE_CMD logs -f"
echo "========================================"
