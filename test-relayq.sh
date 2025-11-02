#!/bin/bash
# Test relayq installation

set -e

echo "=== Testing relayq ==="
echo ""

# Check Redis
echo "→ Testing Redis connection..."
if redis-cli ping | grep -q "PONG"; then
    echo "✓ Redis responding"
else
    echo "✗ Redis not responding"
    exit 1
fi

# Create test Python script
cat > /tmp/test_relayq.py << 'EOF'
from relayq import job
import time

print("Submitting test job...")
result = job.run("echo 'Hello from Mac Mini'")

print("Waiting for result...")
try:
    output = result.get(timeout=30)
    print(f"✓ Job completed: {output}")
    print("\n=== relayq is working! ===")
except Exception as e:
    print(f"✗ Job failed: {e}")
    exit(1)
EOF

# Run test
python3 /tmp/test_relayq.py

# Cleanup
rm /tmp/test_relayq.py

echo ""
echo "All tests passed! relayq is ready to use."
echo ""
echo "See USAGE.md for how to use in your projects."