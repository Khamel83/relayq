#!/bin/bash
# Tailscale Funnel Setup Script
# One-time setup for Tailscale Funnel on this machine

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/tailscale-config.json"

# Use unified RelayQ env file
ENV_FILE="$HOME/.config/relayq/env"

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

# Ensure RelayQ config directory exists
mkdir -p "$HOME/.config/relayq"

# Add Tailscale configuration to unified env file if not present
if [ ! -f "$ENV_FILE" ]; then
    echo ""
    echo "Creating $ENV_FILE with Tailscale configuration..."
    cp "$PROJECT_ROOT/../jobs/env.example" "$ENV_FILE" 2>/dev/null || cat > "$ENV_FILE" << 'ENVEOF'
# RelayQ Unified Configuration
# This file contains all configuration for RelayQ and Tailscale Funnel

ASR_BACKEND=local
WHISPER_MODEL=base
AI_API_KEY=sk-your-api-key-here
ENVEOF
fi

# Add or update Tailscale-specific variables
if ! grep -q "TAILSCALE_FUNNEL_BASE_URL" "$ENV_FILE" 2>/dev/null; then
    echo ""
    echo "Adding Tailscale configuration to $ENV_FILE..."
    cat >> "$ENV_FILE" << EOF

# =============================================================================
# TAILSCALE FUNNEL CONFIGURATION
# =============================================================================
# Automatically managed by tailscale-funnel-module scripts

# Public base URL when Funnel is enabled (auto-updated by funnel-start.sh)
TAILSCALE_FUNNEL_BASE_URL=https://$MACHINE_NAME$TAILNET:8000

# Machine information
TAILSCALE_MACHINE_NAME=$MACHINE_NAME
TAILSCALE_TAILNET=$TAILNET

# Tailscale MCP API Key (for AI-driven management)
# Get from: https://login.tailscale.com/admin/settings/keys
# TAILSCALE_API_KEY=tskey-api-your-key-here

# Public dashboard/API settings
RELAYQ_DASHBOARD_PORT=8000
RELAYQ_API_PORT=8001
RELAYQ_ARTIFACTS_PORT=8002

# API authentication (generate with: python -c "import secrets; print(secrets.token_urlsafe(32))")
# RELAYQ_API_KEY=change-me-in-production
EOF
    echo "✓ Added Tailscale configuration to $ENV_FILE"
else
    echo "✓ Tailscale configuration already in $ENV_FILE"
fi

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Configuration:"
echo "  Unified env file: $ENV_FILE"
echo "  Tailscale config: $CONFIG_FILE"
echo ""
echo "All RelayQ and Tailscale settings are in ONE file: $ENV_FILE"
echo ""
echo "Next steps:"
echo "  1. Edit $ENV_FILE to configure API keys and settings"
echo "  2. Edit $CONFIG_FILE to set your port (if needed)"
echo "  3. Run: ./scripts/funnel-start.sh to start Funnel"
echo "  4. Run: ./scripts/funnel-status.sh to get your public URL"
echo ""
