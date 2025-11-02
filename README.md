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
   # On OCI VM (broker):
   curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-broker.sh | bash

   # On Mac Mini (high-power worker):
   curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-worker.sh | bash

   # On RPi4 (light worker):
   curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-worker-rpi.sh | bash
   ```

2. **In any project on OCI VM:**
   ```python
   from relayq import job, worker_status

   # Auto-distributed (any available worker)
   result = job.run("echo 'Hello from cluster'")
   print(result.get())

   # Worker-specific routing
   job.run_on_mac("ffmpeg -i video.mp4 output.mp4")  # Heavy tasks
   job.run_on_rpi("python monitor.py")               # Light tasks

   # Check cluster status
   print(worker_status())
   ```

3. **That's it.** Jobs distribute across your 3-node cluster automatically.

## ✅ System Status: **3-NODE CLUSTER READY**

- Single-command installation from GitHub ✅
- OCI VM → Mac Mini job execution ✅
- OCI VM → RPi4 job execution ✅
- Auto-load balancing across workers ✅
- Redis auto-restart reliability ✅
- Worker-specific job routing ✅
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
OCI VM (100.103.45.61)
├── Your Python code
├── Redis (message broker + auto-restart)
└── Job distribution

Mac Mini (100.113.216.27)           RPi4 (Tailscale IP)
├── High-power worker                ├── Light worker
├── Video transcoding                ├── Monitoring scripts
├── Heavy processing                 ├── Background tasks
├── 2 concurrent jobs max            ├── 4 concurrent jobs max
└── hostname: mac-mini               └── hostname: rpi4-worker
```

Jobs flow: Your code → Redis → Available worker → Results back
- **Auto-load balancing**: Jobs go to first available worker
- **Worker-specific**: Force jobs to specific worker types
- **Fault tolerance**: System continues if one worker is down