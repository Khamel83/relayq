#!/bin/bash
# FIXED: relayq worker installation with bulletproof auto-restart

set -e

echo "=== Installing relayq Worker (Fixed Auto-Start) ==="

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: This script should run on macOS (Mac Mini)"
    exit 1
fi

# Install dependencies
echo "→ Installing Python packages..."
pip3 install --user celery[redis] redis

# Install relayq
echo "→ Installing relayq..."
pip3 install --user git+https://github.com/Khamel83/relayq.git

# Create config directory
mkdir -p ~/.relayq

# Create config file
cat > ~/.relayq/config.yml << 'EOF'
broker:
  host: 100.103.45.61
  port: 6379
  db: 0

worker:
  priority: low
  max_concurrent: 2
  cpu_threshold: 80

logging:
  level: INFO
  file: ~/.relayq/worker.log
EOF

# Create bulletproof worker script
cat > ~/.relayq/worker-bulletproof.sh << 'EOF'
#!/bin/bash
# Bulletproof worker with connection retry

while true; do
    echo "$(date): Starting relayq worker..."

    # Kill any existing workers first
    pkill -f "celery.*relayq" 2>/dev/null || true
    sleep 2

    # Start worker with connection retry
    python3 -m celery -A relayq.tasks worker \
        --loglevel=info \
        --concurrency=2 \
        --hostname=macmini-bulletproof \
        --without-gossip \
        --without-mingle \
        --without-heartbeat

    echo "$(date): Worker stopped, restarting in 10 seconds..."
    sleep 10
done
EOF

chmod +x ~/.relayq/worker-bulletproof.sh

# Create LaunchAgent with better configuration
cat > ~/Library/LaunchAgents/com.relayq.worker.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.relayq.worker</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/macmini/.relayq/worker-bulletproof.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    <key>ThrottleInterval</key>
    <integer>10</integer>
    <key>StandardOutPath</key>
    <string>/Users/macmini/.relayq/service.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/macmini/.relayq/service.log</string>
    <key>WorkingDirectory</key>
    <string>/Users/macmini</string>
</dict>
</plist>
EOF

# Clean up any existing service
launchctl unload ~/Library/LaunchAgents/com.relayq.worker.plist 2>/dev/null || true

# Load and start the service
launchctl load ~/Library/LaunchAgents/com.relayq.worker.plist
launchctl start com.relayq.worker

echo "✓ Configuration created at ~/.relayq/config.yml"
echo "✓ Bulletproof worker script created"
echo "✓ LaunchAgent service installed and started"
echo "✓ Worker running with auto-restart on crash/reboot"

echo ""
echo "=== Installation Complete ==="
echo "Worker will automatically:"
echo "- Start on system boot"
echo "- Restart if crashed"
echo "- Retry connections if Redis is down"
echo "- Run in background (survives terminal close)"

echo ""
echo "Check status with:"
echo "launchctl list | grep relayq"
echo "tail -f ~/.relayq/service.log"