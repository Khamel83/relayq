# REAL SETUP - What Actually Happened

This documents the actual setup process with all the complications we encountered.

## The Real Installation Process

### OCI VM Setup (Had Issues)

1. **Redis Configuration Problem:**
   ```bash
   # The original config didn't allow external connections
   sudo sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf
   sudo sed -i 's/^bind 127.0.0.1/bind 127.0.0.1 100.103.45.61/' /etc/redis/redis.conf
   sudo systemctl restart redis
   ```

2. **Firewall Issues:**
   ```bash
   # Had to manually allow Redis port
   sudo ufw allow from 100.113.216.27 to any port 6379 comment 'relayq Redis'
   ```

3. **Python Package Installation:**
   ```bash
   # System packages needed --break-system-packages flag
   pip3 install --user --break-system-packages celery[redis] redis
   pip3 install --user --break-system-packages -e .
   ```

### Mac Mini Setup (Major Issues)

1. **LaunchAgent Completely Broken:**
   - The install script creates a LaunchAgent that doesn't work
   - Python can't find the relayq module when run via LaunchAgent
   - Multiple attempts to fix the plist file failed

2. **Editable Install Problems:**
   ```bash
   # First install was "editable" and pointed to temp directory that got deleted
   pip3 uninstall relayq -y
   pip3 install --user git+https://github.com/Khamel83/relayq.git
   ```

3. **Manual Worker Start Required:**
   ```bash
   # LaunchAgent never worked, had to start manually
   pkill -f celery
   nohup python3 -m celery -A relayq.tasks worker --loglevel=info --concurrency=2 > ~/.relayq/worker.log 2>&1 &
   ```

## What Actually Works

### Starting the Worker (Mac Mini)
```bash
# Kill any existing worker
pkill -f celery

# Start persistent worker
nohup python3 -m celery -A relayq.tasks worker --loglevel=info --concurrency=2 > ~/.relayq/worker.log 2>&1 &

# Verify it's running
tail ~/.relayq/worker.log
```

### Using relayq (OCI VM)
```bash
# Basic test
python3 -c "from relayq import job; result = job.run('echo hello'); print(result.get())"

# Video transcode
python3 -c "from relayq import job; job.transcode('input.mp4', output='output.mp4')"
```

## Issues That Remain

1. **Worker Dies on Mac Mini Reboot:**
   - Must manually restart worker after reboot
   - No automatic startup solution works

2. **Connection Warnings Normal:**
   - Redis drops idle connections every ~30 seconds
   - Worker automatically reconnects
   - These warnings are harmless but noisy

3. **No Monitoring:**
   - No way to check if worker is healthy from OCI VM
   - Must manually check logs on Mac Mini

## Working Configuration Files

### OCI VM Redis Config (/etc/redis/redis.conf)
```
# Key changes needed:
protected-mode no
bind 127.0.0.1 100.103.45.61
```

### Mac Mini Config (~/.relayq/config.yml)
```yaml
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
```

## Manual Restart Procedure

**After Mac Mini reboots:**
1. SSH to Mac Mini: `ssh macmini`
2. Start worker: `nohup python3 -m celery -A relayq.tasks worker --loglevel=info --concurrency=2 > ~/.relayq/worker.log 2>&1 &`
3. Test from OCI VM: `python3 -c "from relayq import job; print(job.run('echo test').get())"`

## What the Original Docs Got Wrong

1. **install-worker.sh doesn't work** - LaunchAgent fails to find relayq module
2. **No firewall configuration** - Redis port needs manual opening
3. **No Redis security config** - protected-mode needs to be disabled
4. **No troubleshooting for real issues** - Docs assume perfect install

## Bottom Line

The system works great once you get it running, but the installation is not automated or reliable. Expect to manually start the worker and troubleshoot connection issues.