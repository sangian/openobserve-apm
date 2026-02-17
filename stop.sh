#!/bin/bash

# OpenObserve APM Stop Script
# This script helps you stop the entire OpenObserve APM stack

set -e

# Detect Docker Compose command
if command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "ERROR: Docker Compose is not installed"
    exit 1
fi

echo "========================================"
echo "Stopping OpenObserve APM Services"
echo "========================================"
echo ""

# Parse arguments
REMOVE_VOLUMES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --remove-volumes)
            REMOVE_VOLUMES=true
            shift
            ;;
        --help)
            echo "Usage: ./stop.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --remove-volumes   Remove all volumes (WARNING: deletes data!)"
            echo "  --help             Show this help message"
            echo ""
            echo "Note: This script only stops OpenObserve."
            echo "      Traefik is managed externally."
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Stop OpenObserve
echo "Stopping OpenObserve..."
if [ "$REMOVE_VOLUMES" = true ]; then
    $COMPOSE_CMD down -v
    echo "✓ OpenObserve stopped and volumes removed"
else
    $COMPOSE_CMD down
    echo "✓ OpenObserve stopped"
fi
echo ""

echo "========================================"
echo "Shutdown Complete!"
echo "========================================"

if [ "$REMOVE_VOLUMES" = true ]; then
    echo ""
    echo "WARNING: All data volumes have been removed!"
    echo "Your data has been permanently deleted."
fi

echo ""
echo "To start services again, run:"
echo "  ./start.sh"
echo "========================================"
