#!/bin/bash
# Install relayq broker on OCI VM

set -e

echo "=== Installing relayq Broker on OCI VM ==="
echo ""

# Check if running on correct machine
if [[ ! -f /etc/os-release ]] || ! grep -q "Ubuntu" /etc/os-release; then
    echo "Error: This script should run on Ubuntu (OCI VM)"
    exit 1
fi

# Update package list
echo "→ Updating package list..."
sudo apt update -qq

# Install Redis
echo "→ Installing Redis..."
sudo apt install -y redis-server

# Configure Redis
echo "→ Configuring Redis..."
sudo sed -i 's/^supervised no/supervised systemd/' /etc/redis/redis.conf

# Allow external connections (disable protected mode)
sudo sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf

# Allow connections from Mac Mini (Tailscale IP) - avoid duplicates
if ! grep -q "100.103.45.61" /etc/redis/redis.conf; then
    sudo sed -i 's/^bind 127.0.0.1.*/bind 127.0.0.1 100.103.45.61 -::1/' /etc/redis/redis.conf
fi

# Start Redis manually (systemd service has issues)
echo "→ Starting Redis..."
sudo redis-server /etc/redis/redis.conf --daemonize yes

# Test Redis
if redis-cli ping | grep -q "PONG"; then
    echo "✓ Redis installed and running"
else
    echo "✗ Redis installation failed"
    exit 1
fi

# Install Python dependencies
echo "→ Installing Python packages..."
pip3 install --user --break-system-packages celery[redis] redis

# Install relayq directly from GitHub
echo "→ Installing relayq..."
pip3 install --user --break-system-packages git+https://github.com/Khamel83/relayq.git

# Create config directory
mkdir -p ~/.relayq

# Create config file
cat > ~/.relayq/config.yml << 'EOF'
broker:
  host: 127.0.0.1
  port: 6379
  db: 0

worker:
  mac_mini_ip: 100.113.216.27
  oci_vm_ip: 100.103.45.61

logging:
  level: INFO
  file: ~/.relayq/broker.log
EOF

echo "✓ Configuration created at ~/.relayq/config.yml"

# Create log file
touch ~/.relayq/broker.log

# Allow firewall rule for Redis (from Mac Mini)
echo "→ Configuring firewall..."
sudo ufw allow from 100.113.216.27 to any port 6379 comment 'relayq Redis'

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Broker installed on OCI VM"
echo "Redis running on 127.0.0.1:6379"
echo ""
echo "Next: Run install-worker.sh on Mac Mini"