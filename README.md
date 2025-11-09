# RelayQ: Zero-Cost Infrastructure Toolkit

**A reusable deployment framework for running ANY application with zero hosting costs.**

RelayQ provides two main tools:

1. **Tailscale Funnel Module** - Deploy any web app publicly with automatic HTTPS ($0/month)
2. **GitHub Actions Job Orchestration** - Use GitHub as a free job queue (example implementation)

## What You Can Do

### 🌐 Deploy Any Web App Publicly (Zero Cost)

Use the **Tailscale Funnel module** to deploy ANY project:
- Flask/Django apps
- Next.js/React frontends
- REST APIs
- Dashboards
- Static sites
- **Anything that runs on a port**

**Cost:** $0/month (vs $20-100/month for Vercel/Railway/Heroku)

**Quick example:**
```bash
# Copy module to YOUR project
cp -r relayq/tailscale-funnel-module my-project/

# Setup once
cd my-project/tailscale-funnel-module
./scripts/funnel-setup.sh

# Deploy
./scripts/funnel-start.sh
```

Your app is now public at `https://your-machine.ts.net:8000` with automatic HTTPS!

➡️ **[See Tailscale Funnel Quick Start](tailscale-funnel-module/QUICKSTART.md)**

### 🔧 Job Orchestration (Example Implementation)

RelayQ also includes a reference implementation: GitHub-first job orchestration for audio/video processing using self-hosted runners.

**This shows you how to:**
- Use GitHub Actions as a free queue
- Run jobs on your hardware (Mac Mini, RPi, etc.)
- Process tasks locally with full privacy

**Perfect for:**
- Audio/video processing
- File transcoding
- Data processing workflows
- Background task automation

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  PUBLIC INTERNET (via Tailscale Funnel)                     │
│  https://your-machine.ts.net                                 │
└─────────────────────────────────────────────────────────────┘
                         ▲
                         │ Automatic HTTPS
                         │
┌─────────────────────────────────────────────────────────────┐
│  YOUR PROJECT (any web app, API, dashboard)                 │
│  Runs locally on your machine                                │
└─────────────────────────────────────────────────────────────┘

Optional: GitHub Actions for job queue
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions (free queue)                                 │
│       ▲                                                       │
│       │ polling                                               │
│  Self-hosted runners (your hardware)                         │
└─────────────────────────────────────────────────────────────┘
```

## Using RelayQ as a Deployment Framework

### For ANY Web Application

**RelayQ's Tailscale Funnel module is a standalone tool** - copy it to any project!

```bash
# 1. Copy module to your project
cp -r /path/to/relayq/tailscale-funnel-module your-project/

# 2. In your project
cd your-project/tailscale-funnel-module
./scripts/funnel-setup.sh

# 3. Start your app (Flask, Next.js, whatever)
python app.py &
# or: npm start &
# or: rails server &

# 4. Make it public
./scripts/funnel-start.sh
```

**That's it!** Your app is now at `https://your-machine.ts.net:8000`

**Works with:**
- Python (Flask, Django, FastAPI)
- Node.js (Express, Next.js, React)
- Ruby (Rails, Sinatra)
- Go (Gin, Echo)
- Rust (Actix, Rocket)
- PHP (Laravel, Symfony)
- **Any web framework**

➡️ **[Complete Guide: tailscale-funnel-module/QUICKSTART.md](tailscale-funnel-module/QUICKSTART.md)**

### Example: Deploy a Flask App

```python
# app.py
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello World!"

if __name__ == '__main__':
    # IMPORTANT: Listen on 0.0.0.0, not localhost!
    app.run(host='0.0.0.0', port=8000)
```

```bash
# Deploy it
cp -r relayq/tailscale-funnel-module my-flask-app/
cd my-flask-app/tailscale-funnel-module
./scripts/funnel-setup.sh
cd ..
python app.py &
cd tailscale-funnel-module
./scripts/funnel-start.sh

# Done! Public at: https://your-machine.ts.net:8000
```

### Example: Deploy a Next.js App

```bash
# In your Next.js project
cp -r relayq/tailscale-funnel-module .
cd tailscale-funnel-module

# Edit port in tailscale-config.json
nano tailscale-config.json  # Set port to 3000

# Setup and deploy
./scripts/funnel-setup.sh
cd ..
npm run build
npm start &
cd tailscale-funnel-module
./scripts/funnel-start.sh

# Done! Public at: https://your-machine.ts.net:3000
```

---

## RelayQ Job Orchestration (Optional)

If you also want to use GitHub Actions as a free job queue, RelayQ includes a complete reference implementation for audio/video processing:

### 1. Install Runners

**Mac mini (heavy processing):**
```bash
# See docs/SETUP_RUNNERS_mac.md
curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz
tar xzf actions-runner-osx-x64-2.311.0.tar.gz
sudo ./config.sh --url https://github.com/Khamel83/relayq --token YOUR_TOKEN
sudo ./svc.sh install && sudo ./svc.sh start
```

**Raspberry Pi 4 (light processing):**
```bash
# See docs/SETUP_RUNNERS_rpi.md
sudo useradd -m runner
sudo -u runner bash -c 'cd /opt/actions-runner && ./config.sh --url https://github.com/Khamel83/relayq --token YOUR_TOKEN'
```

### 2. Configure OCI VM Trigger

```bash
# Install GitHub CLI
sudo apt install gh
gh auth login

# Test job submission
./bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://example.com/audio.mp3
```

### 3. Submit Jobs

**From OCI VM:**
```bash
# Pooled execution (Mac mini or RPi4)
./bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://example.com/episode.mp3

# Force Mac mini execution
./bin/dispatch.sh .github/workflows/transcribe_mac.yml url=https://example.com/large.mp3

# Force RPi4 execution
./bin/dispatch.sh .github/workflows/transcribe_rpi.yml url=https://example.com/small.mp3
```

**From GitHub UI:**
1. Go to Actions tab
2. Select workflow
3. Click "Run workflow"
4. Enter URL and parameters

## Runner Labels

| Runner | Labels | Use Case |
|--------|--------|----------|
| **Mac mini** | `self-hosted, macmini, audio, ffmpeg, heavy` | Video/audio transcoding, heavy processing |
| **RPi4** | `self-hosted, rpi4, audio, light` | Text processing, small audio files |
| **RPi3** | `self-hosted, rpi3, overflow, verylight` | Background tasks, overflow |

## Workflows

- **`transcribe_audio.yml`** - Pooled execution across available runners
- **`transcribe_mac.yml`** - Mac mini only (heavy tasks)
- **`transcribe_rpi.yml`** - RPi4 only (light tasks)

## Backends

### Local Whisper
- **Cost**: Free (electricity only)
- **Privacy**: Complete
- **Performance**: Good (depends on hardware)
- **Setup**: Install whisper/whisper.cpp

### OpenAI API
- **Cost**: ~$0.006/minute
- **Privacy**: None
- **Performance**: Excellent
- **Setup**: API key required

### Router APIs (OpenRouter)
- **Cost**: Variable
- **Privacy**: Limited
- **Performance**: Excellent
- **Setup**: API key required

## Configuration

### Unified Configuration File

**All RelayQ configuration is in ONE file:** `~/.config/relayq/env`

```bash
# Create ~/.config/relayq/env
mkdir -p ~/.config/relayq
cp jobs/env.example ~/.config/relayq/env

# Edit with your settings
nano ~/.config/relayq/env
```

This file contains:
- ASR backend settings (local, OpenAI, router)
- API keys
- Tailscale Funnel configuration (if using public web access)
- All environment variables

**Example configuration:**
```bash
# ASR Backend
ASR_BACKEND=local
WHISPER_MODEL=base
AI_API_KEY=sk-your-api-key-here

# Tailscale Funnel (for public dashboards/APIs)
TAILSCALE_FUNNEL_BASE_URL=https://oci-vm.ts.net:8000
RELAYQ_DASHBOARD_PORT=8000
```

See `jobs/env.example` for all available options.

### Job Routing Policy
```yaml
# policy/policy.yaml
routes:
  transcribe:
    prefer: [macmini]
    fallback: [rpi4]
    constraints:
      needs_ffmpeg: true
      max_size_mb: 1000
```

## Public Web Access (Optional)

Want to make RelayQ publicly accessible? Use the **Tailscale Funnel module** for:
- 🌐 Public dashboard showing job status and runner health
- 🔌 Public API for external job submission
- 📤 Share transcription results via HTTPS links
- 💰 **$0 hosting costs** - runs on your infrastructure with automatic HTTPS

**Quick start:**
```bash
cd tailscale-funnel-module
./scripts/funnel-setup.sh    # One-time setup
python examples/relayq/dashboard.py &  # Start dashboard
./scripts/funnel-start.sh    # Make public
```

Your dashboard is now at: `https://your-machine.ts.net:8000`

**Documentation:**
- **[tailscale-funnel-module/QUICKSTART.md](tailscale-funnel-module/QUICKSTART.md)** ⭐ Start here!
- **[tailscale-funnel-module/README.md](tailscale-funnel-module/README.md)** - Full overview
- **[tailscale-funnel-module/TAILSCALE_COMPLETE_STACK.md](tailscale-funnel-module/TAILSCALE_COMPLETE_STACK.md)** - Complete infrastructure replacement

## Documentation

### Core RelayQ
- **[docs/OVERVIEW.md](docs/OVERVIEW.md)** - Architecture and motivation
- **[docs/SETUP_RUNNERS_mac.md](docs/SETUP_RUNNERS_mac.md)** - macOS runner setup
- **[docs/SETUP_RUNNERS_rpi.md](docs/SETUP_RUNNERS_rpi.md)** - Raspberry Pi setup
- **[docs/SETUP_OCI_TRIGGER.md](docs/SETUP_OCI_TRIGGER.md)** - OCI VM trigger setup
- **[docs/RUNBOOK.md](docs/RUNBOOK.md)** - Operations procedures
- **[docs/RELIABILITY.md](docs/RELIABILITY.md)** - Reliability patterns
- **[docs/ROUTING_POLICY.md](docs/ROUTING_POLICY.md)** - Policy engine
- **[docs/LLM_ROUTING.md](docs/LLM_ROUTING.md)** - Backend routing
- **[docs/OPSEC.md](docs/OPSEC.md)** - Security practices
- **[docs/DECISIONS.md](docs/DECISIONS.md)** - Migration decisions
- **[docs/TASKS.md](docs/TASKS.md)** - Implementation checklist

### Tailscale Funnel (Public Web Access)
- **[tailscale-funnel-module/QUICKSTART.md](tailscale-funnel-module/QUICKSTART.md)** - Quick start guide
- **[tailscale-funnel-module/docs/MCP_INTEGRATION.md](tailscale-funnel-module/docs/MCP_INTEGRATION.md)** - AI-driven management
- **[tailscale-funnel-module/docs/SECURITY.md](tailscale-funnel-module/docs/SECURITY.md)** - Security best practices
- **[tailscale-funnel-module/docs/ARCHITECTURE.md](tailscale-funnel-module/docs/ARCHITECTURE.md)** - How it works

## Examples

### Audio Transcription
```bash
# Basic transcription
./bin/dispatch.sh .github/workflows/transcribe_audio.yml \
  url=https://example.com/podcast.mp3

# With specific backend
./bin/dispatch.sh .github/workflows/transcribe_audio.yml \
  url=https://example.com/interview.mp3 \
  backend=openai

# Large file on Mac mini
./bin/dispatch.sh .github/workflows/transcribe_mac.yml \
  url=https://example.com/lecture.mp3 \
  backend=local \
  model=small
```

### API Integration
```python
import subprocess

def submit_transcription(audio_url, backend="local"):
    """Submit transcription job from external application"""
    cmd = [
        '/home/ubuntu/relayq/bin/dispatch.sh',
        '.github/workflows/transcribe_audio.yml',
        f'url={audio_url}',
        f'backend={backend}'
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise Exception(f"Job submission failed: {result.stderr}")

    return result.stdout.strip()

# Usage
result = submit_transcription(
    "https://example.com/episode.mp3",
    backend="local"
)
print(f"Job submitted: {result}")
```

## Migration from Redis

The original Redis-based implementation is preserved in `legacy/`. See `legacy/ARCHIVE.md` for re-enabling instructions.

## Security

- **Outbound-only connections** - No inbound ports required
- **Secret management** - GitHub encrypted secrets + node-local env files
- **Isolated execution** - Jobs run in isolated environments
- **No data exposure** - Everything processes locally

## Troubleshooting

### Jobs Stay Queued
1. Check runner status: `gh api repos/Khamel83/relayq/actions/runners`
2. Verify labels match workflow requirements
3. Restart runner service if needed

### Jobs Fail
1. Check workflow logs in GitHub UI
2. Verify dependencies installed on runner
3. Check environment variables and API keys

### Runner Offline
1. Check network connectivity: `ping github.com`
2. Restart runner service
3. Re-register runner if needed

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

## License

Original project license preserved. See LICENSE file for details.

## Support

- **Documentation**: See `docs/` directory
- **Issues**: Open GitHub issue
- **Community**: Discussions tab

---

## Summary: Two Tools, Infinite Possibilities

### 1. Tailscale Funnel Module (Standalone)
**Copy to ANY project** - Works with any web framework
- **Cost**: $0/month
- **Setup**: 3 commands
- **Result**: Public HTTPS URL

➡️ [Get Started: tailscale-funnel-module/QUICKSTART.md](tailscale-funnel-module/QUICKSTART.md)

### 2. GitHub Actions Job Queue (Optional)
**Example implementation** - Shows how to use GitHub as infrastructure
- **Cost**: Free (2,000 minutes/month)
- **Use Case**: Background jobs, transcoding, processing
- **Result**: Free job orchestration

➡️ [Learn More: docs/OVERVIEW.md](docs/OVERVIEW.md)

---

**RelayQ = Reusable infrastructure toolkit for zero-cost deployments**

Replace Vercel, Railway, Heroku, and all hosting services with your own hardware + Tailscale.