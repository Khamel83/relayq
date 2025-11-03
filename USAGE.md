# Usage Guide

## 🚀 ZERO CONFIGURATION ON THIS OCI VM

**relayq is pre-installed on this machine. In any Python project, anywhere on this OCI VM, just use:**

```python
from relayq import job
result = job.run("your command here")
print(result.get())
```

**That's it. No setup, no config, no connection strings needed.**

### Why this works:
- relayq package is installed system-wide on this OCI VM
- Redis broker is running and pre-configured
- Mac Mini worker is connected and ready
- All configuration is handled automatically

### Test it right now:
```python
from relayq import job
result = job.run("echo 'Hello from Mac Mini'")
print(result.get())  # Output: Hello from Mac Mini
```

## For Other Machines

If you want to use relayq from a different machine:
```bash
pip3 install --user git+https://github.com/Khamel83/relayq.git
```
Then configure it to point to your OCI VM's Redis broker.

## Core Operations

### Basic Command Execution
```python
from relayq import job

# Simple command
result = job.run("ls -la")
output = result.get()

# Command with working directory
result = job.run("make build", cwd="/path/to/project")
```

## Common Operations

### Video Transcoding

```python
from relayq import job

# Basic transcode
job.transcode("video.mp4", output="compressed.mp4")

# With custom ffmpeg options
job.transcode(
    "video.mp4",
    output="output.mp4",
    options="-c:v libx264 -crf 23"
)
```

### Audio Transcription

```python
from relayq import job

# Transcribe with Whisper
result = job.transcribe("podcast.mp3")
transcript = result.get()  # Returns text
```

### Batch Processing

```python
from relayq import job
import glob

# Submit all videos
videos = glob.glob("*.mp4")
jobs = [job.transcode(v) for v in videos]

# Wait for all to complete
for j in jobs:
    j.wait()
```

### Custom Commands

```python
from relayq import job

# Run any shell command on Mac Mini
job.run("your-script.sh --arg value")

# With working directory
job.run("make build", cwd="/path/to/project")
```

## Checking Status

```python
result = job.transcode("video.mp4")

# Non-blocking status check
if result.ready():
    print("Job finished")
elif result.failed():
    print("Job failed:", result.traceback)
else:
    print("Still running...")

# Get progress (if task reports it)
print(f"Progress: {result.info}")
```

## Configuration

relayq auto-configures using your Tailscale network. No manual config needed.

If you need to customize, edit `~/.relayq/config.yml` on OCI VM:

```yaml
broker:
  host: 127.0.0.1
  port: 6379

worker:
  priority: low           # Process priority
  max_concurrent: 2       # Max simultaneous jobs
  cpu_threshold: 80       # Pause if CPU > 80%
```

## Error Handling

```python
from relayq import job

try:
    result = job.transcode("video.mp4")
    result.wait(timeout=3600)  # 1 hour timeout
except TimeoutError:
    print("Job took too long")
except Exception as e:
    print(f"Job failed: {e}")
```

## Logging

View logs:

**On Mac Mini:**
```bash
tail -f ~/.relayq/worker.log
```

**On OCI VM:**
```bash
tail -f ~/.relayq/broker.log
```

## That's It

For complete working examples, see [EXAMPLES.md](EXAMPLES.md).

For troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).