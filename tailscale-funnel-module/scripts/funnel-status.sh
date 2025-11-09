#!/bin/bash
# Tailscale Funnel Status Script
# Shows current Funnel status and public URL

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/tailscale-config.json"

echo "=== Tailscale Funnel Status ==="
echo ""

# Check if Tailscale is running
if ! tailscale status &> /dev/null; then
    echo "❌ Tailscale is not running"
    echo ""
    echo "Start Tailscale: sudo tailscale up"
    exit 1
fi

# Get machine info
MACHINE_NAME=$(tailscale status --json | grep -o '"HostName":"[^"]*' | cut -d'"' -f4)
TAILNET=$(tailscale status --json | grep -o '"MagicDNSSuffix":"[^"]*' | cut -d'"' -f4)

echo "Machine: $MACHINE_NAME"
echo "Tailnet: $TAILNET"
echo ""

# Get Funnel status
echo "Funnel Status:"
FUNNEL_STATUS=$(tailscale funnel status 2>&1)

if echo "$FUNNEL_STATUS" | grep -q "Funnel is not running"; then
    echo "  Status: ❌ Not running"
    echo ""
    echo "To start Funnel: ./scripts/funnel-start.sh"
else
    echo "  Status: ✓ Running"
    echo ""

    # Extract port from config if available
    if [ -f "$CONFIG_FILE" ]; then
        PORT=$(grep -o '"port":\s*[0-9]*' "$CONFIG_FILE" | grep -o '[0-9]*')
        if [ -n "$PORT" ]; then
            PUBLIC_URL="https://$MACHINE_NAME$TAILNET"
            echo "Public URL:"
            echo "  $PUBLIC_URL"
            echo ""
        fi
    fi

    echo "Detailed status:"
    echo "$FUNNEL_STATUS"
fi

echo ""
