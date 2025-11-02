# Usage Guide

How to use relayq in your projects.

## Install in Project

Add to your `requirements.txt`:
```
relayq
```

Or install directly:
```bash
pip install git+https://github.com/Khamel83/relayq.git
```

## Basic Usage

```python
from relayq import job

# Transcode video (runs on Mac Mini)
result = job.transcode("input.mp4", output="output.mp4")

# Wait for completion
result.wait()

# Or check status
if result.ready():
    print("Done!")
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