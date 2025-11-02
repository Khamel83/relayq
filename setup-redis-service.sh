#!/bin/bash
# Setup reliable Redis service for relayq

set -e

echo "Setting up Redis auto-restart service..."

# Create systemd service for Redis health monitoring
sudo tee /etc/systemd/system/relayq-redis-monitor.service > /dev/null << 'EOF'
[Unit]
Description=relayq Redis Health Monitor
After=network.target

[Service]
Type=oneshot
User=ubuntu
ExecStart=/home/ubuntu/dev/relayq/redis-healthcheck.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create systemd timer for regular health checks
sudo tee /etc/systemd/system/relayq-redis-monitor.timer > /dev/null << 'EOF'
[Unit]
Description=Run relayq Redis health check every 30 seconds
Requires=relayq-redis-monitor.service

[Timer]
OnBootSec=30sec
OnUnitActiveSec=30sec
AccuracySec=1sec

[Install]
WantedBy=timers.target
EOF

# Enable and start the health monitoring
sudo systemctl daemon-reload
sudo systemctl enable relayq-redis-monitor.timer
sudo systemctl start relayq-redis-monitor.timer

echo "✓ Redis health monitoring enabled"
echo "Logs: tail -f ~/.relayq/redis-health.log"
echo "Status: sudo systemctl status relayq-redis-monitor.timer"