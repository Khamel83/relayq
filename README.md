# relayq

**Your personal compute orchestrator for OCI VM + Mac Mini M4**

relayq lets you write code on your always-on OCI VM and automatically offload heavy processing (video transcoding, audio transcription, etc.) to your Mac Mini when it's available.

## What It Does

- Submit jobs from OCI VM with a single Python function call
- Mac Mini processes jobs in the background (low priority, won't affect Plex)
- Automatic retries if jobs fail
- Full logging and status tracking
- Zero ongoing management

## Quick Start

1. **One-time setup** (single commands):
   ```bash
   # On OCI VM:
   curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-broker.sh | bash

   # On Mac Mini:
   curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-worker.sh | bash
   ```

2. **In any project on OCI VM:**
   ```python
   from relayq import job

   # Run any command on Mac Mini
   result = job.run("echo 'Hello from Mac Mini'")
   print(result.get())  # Prints: Hello from Mac Mini

   # Transcode video
   job.transcode("input.mp4", output="output.mp4")

   # Transcribe audio
   job.transcribe("podcast.mp3")
   ```

3. **That's it.** Jobs run on Mac Mini automatically.

## ✅ System Status: **WORKING**

- Single-command installation from GitHub ✅
- OCI VM → Mac Mini job execution ✅
- Background worker on Mac Mini ✅
- All examples tested and functional ✅

## Documentation

- [SETUP.md](SETUP.md) - Initial installation (run once)
- [USAGE.md](USAGE.md) - How to use in your projects
- [EXAMPLES.md](EXAMPLES.md) - Copy-paste examples
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - When something breaks

## Future Omar

You set this up once. Now just copy examples from EXAMPLES.md.

If something breaks, check TROUBLESHOOTING.md.

If you're starting a new project, tell Claude: "Add relayq to this project" and paste USAGE.md.

## Architecture

```
OCI VM (10.0.0.45 / 100.103.45.61)
├── Your Python code
├── Redis (message broker)
└── Celery client

Mac Mini (192.168.7.165 / 100.113.216.27)
└── Celery worker (low priority, always running)
```

Jobs flow: Your code → Redis → Mac Mini → Results back