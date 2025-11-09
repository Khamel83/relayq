#!/bin/bash
# Tailscale Funnel Setup Script
# One-time setup for Tailscale Funnel on this machine

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/tailscale-config.json"

echo "=== Tailscale Funnel Setup ==="
echo ""

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    echo "❌ Tailscale is not installed!"
    echo ""
    echo "Install Tailscale first:"
    echo "  Visit: https://tailscale.com/download"
    echo "  Or run: curl -fsSL https://tailscale.com/install.sh | sh"
    exit 1
fi

echo "✓ Tailscale is installed"

# Check if Tailscale is running
if ! tailscale status &> /dev/null; then
    echo "❌ Tailscale is not running!"
    echo ""
    echo "Start Tailscale first:"
    echo "  sudo tailscale up"
    exit 1
fi

echo "✓ Tailscale is running"

# Get machine name
MACHINE_NAME=$(tailscale status --json | grep -o '"HostName":"[^"]*' | cut -d'"' -f4)
TAILNET=$(tailscale status --json | grep -o '"MagicDNSSuffix":"[^"]*' | cut -d'"' -f4)

echo "✓ Machine: $MACHINE_NAME"
echo "✓ Tailnet: $TAILNET"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    echo "Creating default configuration..."
    cat > "$CONFIG_FILE" << 'EOF'
{
  "project_name": "relayq",
  "port": 8000,
  "host": "0.0.0.0",
  "protocol": "https",
  "health_check_path": "/health",
  "health_check_timeout": 30,
  "restart_on_failure": true,
  "max_restarts": 3,
  "process_manager": "manual"
}
EOF
    echo "✓ Created default config: $CONFIG_FILE"
    echo ""
    echo "⚠️  Edit $CONFIG_FILE to configure your port and settings"
else
    echo "✓ Config file exists: $CONFIG_FILE"
fi

# Check if .env.tailscale exists
ENV_FILE="$PROJECT_ROOT/.env.tailscale"
if [ ! -f "$ENV_FILE" ]; then
    echo ""
    echo "Creating .env.tailscale template..."
    cat > "$ENV_FILE" << EOF
# Tailscale Environment Variables
# This file is auto-generated and updated by funnel scripts

# Base URL for this app (auto-updated when Funnel starts)
BASE_URL=https://$MACHINE_NAME$TAILNET:8000

# Project configuration
PROJECT_NAME=relayq
MACHINE_NAME=$MACHINE_NAME
TAILNET=$TAILNET

# Add your app-specific environment variables below
# Example:
# DATABASE_URL=postgresql://user:pass@localhost/dbname
# API_KEY=your-api-key-here
EOF
    echo "✓ Created .env.tailscale: $ENV_FILE"
else
    echo "✓ .env.tailscale exists: $ENV_FILE"
fi

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Next steps:"
echo "  1. Edit $CONFIG_FILE to set your port"
echo "  2. Run: ./scripts/funnel-start.sh to start Funnel"
echo "  3. Run: ./scripts/funnel-status.sh to get your public URL"
echo ""
