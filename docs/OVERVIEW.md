# Hybrid Runner Overview

## Architecture

```
OCI VM  ───▶  GitHub (queue)  ◀── polling ──  Mac mini / RPi4 / RPi3
   │             ▲  ▲                                │
   └─ gh/api ────┘  └── logs/secrets                 └─(optional) Tailscale to private data
```

## What Changed

**Old Architecture:**
- Redis-based job queue hosted on OCI VM
- Python client library for job submission
- Manual worker management

**New Architecture:**
- GitHub's native job queue (free)
- Self-hosted runners poll GitHub for jobs
- OCI VM triggers jobs via GitHub CLI or API
- No inbound ports required

## Security Posture

- **Outbound-only connections**: Runners connect to GitHub, never the reverse
- **Zero network exposure**: No open ports on any machines
- **Secrets management**: GitHub encrypted secrets or node-local environment files
- **Isolation**: Jobs run in isolated environments per runner

## Failover and Load Balancing

- **Pooled labels**: Multiple runners can share the same job type
- **Automatic failover**: If one runner goes down, others with matching labels pick up jobs
- **Resource guarding**: Concurrency limits prevent resource conflicts

## Tailscale Usage (Optional)

Tailscale is used **only** for accessing private resources like NAS or internal services:
- Not required for GitHub connectivity
- Provides secure access to private data stores
- Minimal ACLs, least-privilege access

## Labels as Look-Up Tables

Labels define what jobs runners can execute:
- `self-hosted`: Base label for all self-hosted runners
- `macmini`: macOS runner with heavy processing capabilities
- `rpi4`: Raspberry Pi 4 for light tasks
- `audio`: Runner capable of audio processing
- `ffmpeg`: Runner with FFmpeg installed
- `heavy`: High-memory, high-CPU capability

## Migration Benefits

- **Zero maintenance**: No Redis infrastructure to manage
- **Free tier**: 2,000 minutes/month of free runner time
- **Better UI**: GitHub's native interface for monitoring jobs
- **API integration**: Easy integration with other GitHub workflows
- **Scalability**: Add/remove runners without reconfiguration