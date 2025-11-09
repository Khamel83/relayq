#!/bin/bash
# Tailscale Funnel Stop Script
# Stops Tailscale Funnel and makes your app private

set -e

echo "=== Stopping Tailscale Funnel ==="
echo ""

# Check if Tailscale is running
if ! tailscale status &> /dev/null; then
    echo "⚠️  Tailscale is not running"
    exit 0
fi

# Get current Funnel status
FUNNEL_STATUS=$(tailscale funnel status 2>&1)

if echo "$FUNNEL_STATUS" | grep -q "Funnel is not running"; then
    echo "⚠️  Funnel is not currently running"
    exit 0
fi

echo "Disabling Funnel..."

# Disable Funnel
tailscale funnel --bg off

if [ $? -eq 0 ]; then
    echo "✓ Tailscale Funnel disabled"
else
    echo "❌ Failed to disable Funnel"
    exit 1
fi

echo ""
echo "=== Funnel Stopped ==="
echo ""
echo "Your app is now private (only accessible via Tailscale network)"
echo ""
echo "To make it public again: ./scripts/funnel-start.sh"
echo ""
