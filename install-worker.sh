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

# Install relayq directly from GitHub
echo "→ Installing relayq..."
pip3 install --user git+https://github.com/Khamel83/relayq.git

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

# Start worker directly (LaunchAgent approach has issues)
echo "→ Starting worker..."

# Kill any existing worker
pkill -f "celery.*relayq.tasks" 2>/dev/null || true

# Start worker with nohup (survives terminal close)
nohup python3 -m celery -A relayq.tasks worker --loglevel=info --concurrency=2 --hostname=mac-mini@%h > ~/.relayq/worker.log 2>&1 &

# Wait a moment for worker to start
sleep 3

# Check if running
if pgrep -f "celery.*relayq.tasks" > /dev/null; then
    echo "✓ Worker running in background"
else
    echo "✗ Worker failed to start"
    echo "Check logs: tail ~/.relayq/worker.log"
    exit 1
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Worker installed on Mac Mini"
echo "Running in background (survives terminal close)"
echo "Logs: ~/.relayq/worker.log"
echo ""
echo "To restart after reboot:"
echo "nohup python3 -m celery -A relayq.tasks worker --loglevel=info --concurrency=2 --hostname=mac-mini@%h > ~/.relayq/worker.log 2>&1 &"
echo ""
echo "Next: Test from OCI VM with:"
echo "python3 -c \"from relayq import job; print(job.run('echo test').get())\""