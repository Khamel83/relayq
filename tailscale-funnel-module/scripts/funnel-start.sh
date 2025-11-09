#!/bin/bash
# Tailscale Funnel Start Script
# Starts Tailscale Funnel for your application

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/tailscale-config.json"

# Use unified RelayQ env file
ENV_FILE="$HOME/.config/relayq/env"

echo "=== Starting Tailscale Funnel ==="
echo ""

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    echo "Run ./scripts/funnel-setup.sh first!"
    exit 1
fi

# Parse config
PORT=$(grep -o '"port":\s*[0-9]*' "$CONFIG_FILE" | grep -o '[0-9]*')
PROJECT_NAME=$(grep -o '"project_name":\s*"[^"]*' "$CONFIG_FILE" | cut -d'"' -f4)

if [ -z "$PORT" ]; then
    echo "❌ Port not configured in $CONFIG_FILE"
    exit 1
fi

echo "Project: $PROJECT_NAME"
echo "Port: $PORT"
echo ""

# Check if Tailscale is running
if ! tailscale status &> /dev/null; then
    echo "❌ Tailscale is not running!"
    echo "Start Tailscale first: sudo tailscale up"
    exit 1
fi

# Get machine info
MACHINE_NAME=$(tailscale status --json | grep -o '"HostName":"[^"]*' | cut -d'"' -f4)
TAILNET=$(tailscale status --json | grep -o '"MagicDNSSuffix":"[^"]*' | cut -d'"' -f4)

echo "Enabling Tailscale Funnel on port $PORT..."

# Enable Funnel
tailscale funnel --bg --https=443 $PORT

if [ $? -eq 0 ]; then
    echo "✓ Tailscale Funnel enabled"
else
    echo "❌ Failed to enable Tailscale Funnel"
    exit 1
fi

# Update unified env file with public URL
PUBLIC_URL="https://$MACHINE_NAME$TAILNET"
if [ -f "$ENV_FILE" ]; then
    # Update TAILSCALE_FUNNEL_BASE_URL if it exists, otherwise append
    if grep -q "^TAILSCALE_FUNNEL_BASE_URL=" "$ENV_FILE"; then
        # Use portable sed syntax (works on macOS and Linux)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^TAILSCALE_FUNNEL_BASE_URL=.*|TAILSCALE_FUNNEL_BASE_URL=$PUBLIC_URL:$PORT|" "$ENV_FILE"
        else
            sed -i "s|^TAILSCALE_FUNNEL_BASE_URL=.*|TAILSCALE_FUNNEL_BASE_URL=$PUBLIC_URL:$PORT|" "$ENV_FILE"
        fi
    else
        echo "TAILSCALE_FUNNEL_BASE_URL=$PUBLIC_URL:$PORT" >> "$ENV_FILE"
    fi
    echo "✓ Updated $ENV_FILE with TAILSCALE_FUNNEL_BASE_URL=$PUBLIC_URL:$PORT"
fi

echo ""
echo "=== Funnel Started Successfully! ==="
echo ""
echo "Your app is now publicly accessible at:"
echo "  $PUBLIC_URL:$PORT"
echo ""
echo "Make sure your app is:"
echo "  ✓ Running on port $PORT"
echo "  ✓ Listening on 0.0.0.0 (not just localhost)"
echo ""
echo "Configuration is in: $ENV_FILE"
echo ""
echo "Check status: ./scripts/funnel-status.sh"
echo "Stop Funnel: ./scripts/funnel-stop.sh"
echo ""
