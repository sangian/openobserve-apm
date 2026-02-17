#!/bin/bash

# Helper script to generate htpasswd hash for Traefik dashboard
# This creates the authentication credentials for the Traefik dashboard

set -e

echo "=================================="
echo "Traefik Dashboard Password Generator"
echo "=================================="
echo ""

# Check if htpasswd is installed
if ! command -v htpasswd &> /dev/null; then
    echo "ERROR: htpasswd is not installed"
    echo ""
    echo "Install it with:"
    echo "  Ubuntu/Debian: sudo apt-get install apache2-utils"
    echo "  CentOS/RHEL:   sudo yum install httpd-tools"
    echo "  macOS:         brew install httpd"
    exit 1
fi

# Get username
read -p "Enter username [admin]: " USERNAME
USERNAME=${USERNAME:-admin}

# Get password
echo ""
echo "Enter password for user '$USERNAME':"
read -s PASSWORD

if [ -z "$PASSWORD" ]; then
    echo ""
    echo "ERROR: Password cannot be empty"
    exit 1
fi

echo ""
echo "Generating hash..."
echo ""

# Generate the hash
HASH=$(htpasswd -nb "$USERNAME" "$PASSWORD")

# Escape $ for docker-compose
ESCAPED_HASH=$(echo "$HASH" | sed 's/\$/\$\$/g')

echo "=================================="
echo "Generated Hash (for docker-compose):"
echo "=================================="
echo ""
echo "$ESCAPED_HASH"
echo ""
echo "=================================="
echo "Add this line to your .env file:"
echo "=================================="
echo ""
echo "TRAEFIK_DASHBOARD_USERS=$ESCAPED_HASH"
echo ""
echo "=================================="
echo "Note: The double \$\$ is correct for docker-compose!"
echo "=================================="
