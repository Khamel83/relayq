# Usage Guide

How to use relayq in your projects on the OCI VM.

## ✅ Tested Basic Usage

relayq is already installed on your OCI VM. Just import and use:

```python
from relayq import job

# Test connectivity (verified working)
result = job.run("echo 'Hello from Mac Mini'")
print(result.get())  # Output: Hello from Mac Mini

# Run any command on Mac Mini
result = job.run("uname -a")
output = result.get()
print(output)  # Shows Mac Mini system info
```

## Install in New Projects

If you're working on a different machine or need to install elsewhere:
```bash
pip3 install --user git+https://github.com/Khamel83/relayq.git
```

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