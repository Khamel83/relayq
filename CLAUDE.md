# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## System Overview

relayq is a **3-node distributed job queue system** for personal compute orchestration:

- **OCI VM (100.103.45.61)**: Redis broker + job submission interface
- **Mac Mini (100.113.216.27)**: High-power worker (video transcoding, heavy processing)
- **RPi4**: Light worker (monitoring, background tasks)

Built on **Celery + Redis** with a clean Python client API for distributed shell command execution.

## Core Architecture

### Main Components

- **`relayq/client.py`**: Primary user interface - `Job` class with `run()`, `run_on_mac()`, `run_on_rpi()` methods
- **`relayq/tasks.py`**: Celery task definitions - `run_command`, `transcode_video`, `transcribe_audio`
- **`relayq/worker.py`**: Worker process entry point
- **`relayq/config.py`**: YAML-based configuration management
- **Installation scripts**: `install-broker.sh`, `install-worker.sh`, `install-worker-rpi.sh`

### Job Flow
```
User code → Job.run() → Redis queue → Available worker → Results back
```

Workers are auto-selected by availability or explicitly targeted by hostname.

## Development Commands

### Installation & Setup
```bash
# Install package for development
pip3 install --user git+https://github.com/Khamel83/relayq.git

# Fresh installation on nodes
curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-broker.sh | bash
curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-worker.sh | bash
curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-worker-rpi.sh | bash
```

### Testing & Debugging
```bash
# Basic system test
python3 -c "from relayq import job; print(job.run('echo test').get())"

# Check worker status
python3 -c "from relayq import worker_status; print(worker_status())"

# Verify Redis connectivity
redis-cli ping

# Run system verification
./test-relayq.sh

# Start worker manually (debugging)
python3 -m celery -A relayq.tasks worker --loglevel=info --concurrency=2
```

### Redis Management
```bash
# Start Redis (manual)
redis-server --daemonize yes --loglevel verbose --logfile /tmp/redis.log

# Monitor Redis logs
tail -f /tmp/redis.log

# Check Redis process
ps aux | grep redis
```

## Configuration

### Config Location: `~/.relayq/config.yml`
```yaml
broker:
  host: 127.0.0.1  # or 100.103.45.61 for workers
  port: 6379
  db: 0

worker:
  priority: low
  max_concurrent: 2  # Mac Mini: 2, RPi4: 4
  cpu_threshold: 80

logging:
  level: INFO
  file: ~/.relayq/worker.log
```

## Common API Patterns

### Basic Usage
```python
from relayq import job, worker_status

# Auto-distributed to any available worker
result = job.run("echo 'Hello cluster'")
print(result.get())

# Worker-specific targeting
job.run_on_mac("ffmpeg -i video.mp4 output.mp4")  # Heavy tasks
job.run_on_rpi("python monitor.py")               # Light tasks

# Check cluster status
print(worker_status())
```

### Advanced Features
```python
# Video transcoding with options
job.transcode("input.mp4", "output.mp4",
              options="-c:v libx264 -crf 23")

# Audio transcription
result = job.transcribe("audio.wav", model="base")
transcript = result.get()
```

## Critical System Status

**⚠️ Current Issues (see STATUS.md for details):**

1. **Redis dies during job execution** - Primary blocker preventing functionality
2. **RPi4 terminal stuck in Zellij loop** - Cannot access for debugging
3. **Service conflicts** - Multiple Redis managers interfering

**✅ Working Components:**
- Installation infrastructure complete
- Network connectivity established
- Mac Mini worker verified functional
- Job submission logic operational

## Key Files for Debugging

- **`STATUS.md`**: Complete system status and known issues
- **`REDIS-ISSUES.md`**: Detailed Redis connection problem analysis
- **`RPI4-TERMINAL-ISSUES.md`**: Terminal access issues and solutions
- **`TROUBLESHOOTING.md`**: General problem resolution guide

## Package Structure

```
relayq/
├── __init__.py          # Package exports
├── client.py            # User interface (Job, JobResult classes)
├── tasks.py             # Celery task definitions
├── worker.py            # Worker entry point
├── config.py            # Configuration management
└── celeryconfig.py      # Celery-specific config

install-*.sh             # Node setup scripts
examples/                # Working code samples
```

## Testing Strategy

**System verification flow:**
1. Redis connectivity (`redis-cli ping`)
2. Basic job submission (`job.run('echo test')`)
3. Worker status verification (`worker_status()`)
4. End-to-end workflow testing

Use `examples/` directory for integration testing patterns.

## Important Notes

- **All timeouts are 5 hours** for long-running tasks
- **Workers run at low priority** to avoid interfering with primary system use
- **Job distribution is automatic** unless explicitly targeted
- **Configuration is YAML-based** in user home directory
- **Installation is single-command** from GitHub for each node type