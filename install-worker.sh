#!/bin/bash
# Install relayq worker on Mac Mini

set -e

echo "=== Installing relayq Worker on Mac Mini ==="
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: This script should run on macOS (Mac Mini)"
    exit 1
fi

# Install Python dependencies
echo "→ Installing Python packages..."
pip3 install --user celery[redis] redis

# Clone relayq repo
echo "→ Installing relayq..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
git clone https://github.com/Khamel83/relayq.git
cd relayq
pip3 install --user -e .
cd ~
rm -rf "$TEMP_DIR"

# Create config directory
mkdir -p ~/.relayq

# Create config file
cat > ~/.relayq/config.yml << 'EOF'
broker:
  host: 100.103.45.61  # OCI VM Tailscale IP
  port: 6379
  db: 0

worker:
  priority: low          # Run at low CPU priority
  max_concurrent: 2      # Max 2 jobs at once
  cpu_threshold: 80      # Pause if CPU > 80%

logging:
  level: INFO
  file: ~/.relayq/worker.log
EOF

echo "✓ Configuration created at ~/.relayq/config.yml"

# Create log file
touch ~/.relayq/worker.log

# Create LaunchAgent
echo "→ Creating worker service..."
mkdir -p ~/Library/LaunchAgents

cat > ~/Library/LaunchAgents/com.user.relayq.worker.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.relayq.worker</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/nice</string>
        <string>-n</string>
        <string>19</string>
        <string>$(which python3)</string>
        <string>-m</string>
        <string>celery</string>
        <string>-A</string>
        <string>relayq.tasks</string>
        <string>worker</string>
        <string>--loglevel=info</string>
        <string>--concurrency=2</string>
        <string>--hostname=macmini@%h</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>$HOME/.relayq/worker.log</string>

    <key>StandardErrorPath</key>
    <string>$HOME/.relayq/worker.error.log</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin</string>
    </dict>
</dict>
</plist>
EOF

echo "✓ LaunchAgent created"

# Load the worker service
echo "→ Starting worker..."
launchctl load ~/Library/LaunchAgents/com.user.relayq.worker.plist

# Wait a moment for worker to start
sleep 3

# Check if running
if launchctl list | grep -q "com.user.relayq.worker"; then
    echo "✓ Worker service running"
else
    echo "✗ Worker failed to start"
    echo "Check logs: tail ~/.relayq/worker.log"
    exit 1
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Worker installed on Mac Mini"
echo "Running at low priority (won't affect Plex)"
echo "Logs: ~/.relayq/worker.log"
echo ""
echo "Next: Run test-relayq.sh on OCI VM to verify"