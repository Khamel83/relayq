#!/bin/bash
# Install relayq worker on Raspberry Pi 4

set -e

echo "=== Installing relayq Worker on Raspberry Pi 4 ==="
echo ""

# Check if running on ARM architecture (RPi)
if [[ "$(uname -m)" != "aarch64" ]] && [[ "$(uname -m)" != "arm"* ]]; then
    echo "Warning: This script is designed for Raspberry Pi (ARM architecture)"
    echo "Current architecture: $(uname -m)"
    echo "Consider using install-worker.sh for other systems"
    echo ""
fi

# Update package list
echo "→ Updating package list..."
sudo apt update -qq

# Install Python dependencies for RPi
echo "→ Installing Python packages..."
pip3 install --user --break-system-packages celery[redis] redis

# Install relayq directly from GitHub
echo "→ Installing relayq..."
pip3 install --user --break-system-packages git+https://github.com/Khamel83/relayq.git

# Create config directory
mkdir -p ~/.relayq

# Auto-detect Tailscale IP
TAILSCALE_IP=$(ip addr show tailscale0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
if [[ -z "$TAILSCALE_IP" ]]; then
    echo "Warning: Could not detect Tailscale IP automatically"
    TAILSCALE_IP="AUTO_DETECT_FAILED"
fi

# Create config file optimized for RPi4
cat > ~/.relayq/config.yml << EOF
broker:
  host: 100.103.45.61  # OCI VM Tailscale IP
  port: 6379
  db: 0

worker:
  name: rpi4-worker
  priority: low          # Run at low CPU priority
  max_concurrent: 4      # Max 4 jobs at once (RPi4 has 4 cores)
  cpu_threshold: 85      # Pause if CPU > 85%
  tailscale_ip: $TAILSCALE_IP

logging:
  level: INFO
  file: ~/.relayq/worker.log
EOF

echo "✓ Configuration created at ~/.relayq/config.yml"

# Create log file
touch ~/.relayq/worker.log

# Start worker with RPi4-optimized settings
echo "→ Starting RPi4 worker..."

# Kill any existing worker
pkill -f "celery.*relayq.tasks" 2>/dev/null || true

# Start worker with low priority and RPi4-specific concurrency
nohup nice -n 10 python3 -m celery -A relayq.tasks worker \
    --loglevel=info \
    --concurrency=4 \
    --hostname=rpi4-worker@%h \
    > ~/.relayq/worker.log 2>&1 &

# Wait a moment for worker to start
sleep 3

# Check if running
if pgrep -f "celery.*relayq.tasks" > /dev/null; then
    echo "✓ RPi4 worker running in background"
else
    echo "✗ Worker failed to start"
    echo "Check logs: tail ~/.relayq/worker.log"
    exit 1
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "RPi4 worker installed and running"
echo "Worker name: rpi4-worker"
echo "Concurrency: 4 jobs max"
echo "Priority: Low (nice -n 10)"
echo "Logs: ~/.relayq/worker.log"
echo ""
echo "To restart after reboot:"
echo "nohup nice -n 10 python3 -m celery -A relayq.tasks worker --loglevel=info --concurrency=4 --hostname=rpi4-worker@%h > ~/.relayq/worker.log 2>&1 &"
echo ""
echo "Test from OCI VM with:"
echo "python3 -c \"from relayq import job; print('RPi4 test:', job.run('echo \"Hello from RPi4\"').get())\""