#!/bin/bash
# relayq-specific Redis server wrapper for dada protection
# This ensures the Redis process is protected by dada's resource watchdog

# Kill any existing Redis
redis-cli shutdown 2>/dev/null || true
sleep 1

# Start Redis with relayq context
exec redis-server --daemonize no --loglevel notice