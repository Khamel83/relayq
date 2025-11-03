#!/bin/bash
# Bulletproof Redis startup script for relayq

# Kill any existing Redis
redis-cli shutdown save 2>/dev/null || true
sleep 1

# Start Redis with proper configuration for relayq
redis-server \
    --daemonize yes \
    --protected-mode no \
    --bind "0.0.0.0" \
    --port 6379 \
    --save 900 1 \
    --save 300 10 \
    --save 60 10000 \
    --dir /home/ubuntu/dev/relayq \
    --dbfilename relayq-dump.rdb \
    --logfile /home/ubuntu/dev/relayq/redis.log \
    --loglevel notice

# Wait for startup
sleep 2

# Verify Redis is running
if redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis started successfully"
    echo "✅ Protected mode: $(redis-cli CONFIG GET protected-mode | tail -n1)"
    echo "✅ External connectivity test:"
    redis-cli -h 100.103.45.61 ping 2>/dev/null || echo "❌ External connectivity failed"
else
    echo "❌ Redis startup failed"
    exit 1
fi