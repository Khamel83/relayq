#!/bin/bash
# Redis health check and auto-restart script for relayq

LOG_FILE="$HOME/.relayq/redis-health.log"
mkdir -p "$HOME/.relayq"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# Check if Redis is responding
if redis-cli ping &>/dev/null; then
    log "✓ Redis healthy"
    exit 0
fi

log "✗ Redis not responding - attempting restart"

# Try to restart Redis
if sudo redis-server /etc/redis/redis.conf --daemonize yes; then
    sleep 2
    if redis-cli ping &>/dev/null; then
        log "✓ Redis restarted successfully"
        exit 0
    fi
fi

log "✗ Redis restart failed"
exit 1