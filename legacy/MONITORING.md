# Worker Monitoring Guide

How to monitor and manage your 3-node relayq cluster.

## Quick Status Check

```python
from relayq import job, worker_status

# Get cluster overview
status = worker_status()
print(f"Workers online: {status['total_workers']}")
print(f"Active jobs: {status['total_active']}")
print(f"Queued jobs: {status['total_queued']}")

# Detailed worker info
for worker_name, info in status['workers'].items():
    print(f"{worker_name}: {info['type']} - {info['active_jobs']} jobs")
```

## Worker Types and Roles

### Mac Mini (mac-mini@macmini.local)
- **Purpose**: High-power processing
- **Best for**: Video transcoding, audio processing, CPU-intensive tasks
- **Concurrency**: 2 jobs max
- **Access**: `job.run_on_mac("command")`

### RPi4 (rpi4-worker@hostname)
- **Purpose**: Light processing and monitoring
- **Best for**: Scripts, monitoring, web scraping, background tasks
- **Concurrency**: 4 jobs max
- **Priority**: Low (nice -n 10)
- **Access**: `job.run_on_rpi("command")`

## Monitoring Commands

### Check Worker Health
```bash
# On OCI VM
python3 -c "
from relayq import worker_status
import json
print(json.dumps(worker_status(), indent=2))
"
```

### Check Worker Logs
```bash
# Mac Mini logs
ssh macmini "tail -f ~/.relayq/worker.log"

# RPi4 logs
ssh rpi4 "tail -f ~/.relayq/worker.log"

# Redis health logs (OCI VM)
tail -f ~/.relayq/redis-health.log
```

### Worker Process Status
```bash
# Mac Mini
ssh macmini "pgrep -f 'celery.*relayq' && echo 'Worker running' || echo 'Worker stopped'"

# RPi4
ssh rpi4 "pgrep -f 'celery.*relayq' && echo 'Worker running' || echo 'Worker stopped'"
```

## Restarting Workers

### Mac Mini Worker
```bash
ssh macmini
pkill -f "celery.*relayq"
nohup python3 -m celery -A relayq.tasks worker --loglevel=info --concurrency=2 --hostname=mac-mini@%h > ~/.relayq/worker.log 2>&1 &
```

### RPi4 Worker
```bash
ssh rpi4
pkill -f "celery.*relayq"
nohup nice -n 10 python3 -m celery -A relayq.tasks worker --loglevel=info --concurrency=4 --hostname=rpi4-worker@%h > ~/.relayq/worker.log 2>&1 &
```

### Redis (OCI VM)
```bash
# Redis auto-restarts every 30 seconds, but manual restart:
sudo redis-server /etc/redis/redis.conf --daemonize yes
```

## Load Balancing Strategy

### Automatic Distribution
Jobs submitted with `job.run()` automatically go to the first available worker:
```python
# Goes to whichever worker is free
job.run("echo 'Auto-distributed'")
```

### Worker-Specific Tasks
Route heavy tasks to Mac Mini, light tasks to RPi4:
```python
# Heavy processing → Mac Mini
job.run_on_mac("ffmpeg -i video.mp4 -c:v libx264 output.mp4")

# Light monitoring → RPi4
job.run_on_rpi("python3 /home/pi/monitor_pihole.py")
```

## Performance Monitoring

### Job Distribution Analysis
```python
from relayq import worker_status
import time

# Monitor for 60 seconds
for i in range(12):
    status = worker_status()
    for worker, info in status['workers'].items():
        print(f"{worker}: {info['active_jobs']} active, {info['total_jobs']} total")
    time.sleep(5)
```

### Worker Load Testing
```python
from relayq import job
import time

# Submit test jobs to each worker
jobs = []
for i in range(5):
    jobs.append(job.run_on_mac(f"sleep 10 && echo 'Mac job {i}'"))
    jobs.append(job.run_on_rpi(f"sleep 5 && echo 'RPi job {i}'"))

# Wait for completion
for j in jobs:
    print(j.get())
```

## Troubleshooting

### Worker Not Responding
1. Check if worker process is running
2. Check worker logs for errors
3. Restart worker if needed
4. Verify network connectivity

### Redis Connection Issues
1. Check Redis health logs: `tail ~/.relayq/redis-health.log`
2. Redis auto-restarts every 30 seconds
3. Manual restart: `sudo redis-server /etc/redis/redis.conf --daemonize yes`

### Unbalanced Load
- Mac Mini getting overwhelmed → Route video tasks specifically
- RPi4 idle → Route monitoring/script tasks specifically
- Use `worker_status()` to monitor distribution

## System Health Dashboard

Create a simple monitoring script:
```python
#!/usr/bin/env python3
"""relayq Cluster Health Dashboard"""

from relayq import worker_status
import time
import os

def show_dashboard():
    os.system('clear')
    status = worker_status()

    print("🖥️  relayq Cluster Dashboard")
    print("=" * 40)
    print(f"Status: {'🟢 ONLINE' if status['online'] else '🔴 OFFLINE'}")
    print(f"Workers: {status['total_workers']}")
    print(f"Active Jobs: {status['total_active']}")
    print(f"Queued Jobs: {status['total_queued']}")
    print()

    for worker, info in status['workers'].items():
        icon = "🖥️" if info['type'] == 'mac-mini' else "🍓"
        print(f"{icon} {worker}")
        print(f"   Type: {info['type']}")
        print(f"   Active: {info['active_jobs']} jobs")
        print(f"   Total: {info['total_jobs']} jobs")
        print()

if __name__ == "__main__":
    try:
        while True:
            show_dashboard()
            time.sleep(5)
    except KeyboardInterrupt:
        print("\nMonitoring stopped.")
```

Save as `monitor.py` and run with `python3 monitor.py` for live dashboard.