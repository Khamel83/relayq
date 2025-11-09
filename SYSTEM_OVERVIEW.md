# RelayQ Complete System Overview

**A comprehensive guide showing how all RelayQ components work together.**

## The Big Picture

RelayQ is a complete zero-cost infrastructure for personal-scale job orchestration:

```
┌─────────────────────────────────────────────────────────────────┐
│                      PUBLIC INTERNET                             │
│                                                                   │
│  Users access:                                                    │
│  https://oci-vm.ts.net:8000 (Dashboard)                         │
│  https://oci-vm.ts.net:8001 (API)                               │
│  https://oci-vm.ts.net:8002 (Artifacts)                         │
│                                                                   │
│          ▲                                                        │
│          │ Tailscale Funnel (automatic HTTPS)                   │
│          │                                                        │
└──────────┼──────────────────────────────────────────────────────┘
           │
           │
┌──────────┼──────────────────────────────────────────────────────┐
│  OCI VM (FREE, Always-On)                                        │
│          │                                                        │
│    ┌─────▼─────────┐                                            │
│    │  Dashboard    │ ◄── Reads from GitHub Actions API          │
│    │  (Flask)      │                                             │
│    └───────────────┘                                             │
│                                                                   │
│    Submits jobs via:                                             │
│    ./bin/dispatch.sh ──────►  GitHub Actions                    │
│                                    ▲                              │
└────────────────────────────────────┼──────────────────────────┘
                                      │
                                      │ Polls for jobs
                                      │
           ┌──────────────────────────┼──────────────────┐
           │                          │                   │
    ┌──────▼──────┐          ┌───────▼──────┐    ┌──────▼──────┐
    │  Mac Mini   │          │    RPi4      │    │    RPi3     │
    │  (Heavy)    │          │   (Light)    │    │  (Overflow) │
    │             │          │              │    │             │
    │ Self-hosted │          │ Self-hosted  │    │ Self-hosted │
    │   runner    │          │    runner    │    │   runner    │
    └─────────────┘          └──────────────┘    └─────────────┘
           │                          │                   │
           └──────────────────────────┴───────────────────┘
                                      │
                            All connected via
                             Tailscale mesh
```

## Core Components

### 1. RelayQ Core (Job Orchestration)
**Purpose:** GitHub-first job queue with self-hosted runners

**How it works:**
- GitHub Actions = free job queue (2,000 minutes/month)
- Self-hosted runners = your hardware (Mac Mini, RPi, etc.)
- Jobs submitted via `./bin/dispatch.sh` or GitHub UI
- Runners poll GitHub and execute jobs locally

**Configuration:** `~/.config/relayq/env`

### 2. Tailscale Funnel Module (Public Web Access)
**Purpose:** Make local services publicly accessible with automatic HTTPS

**How it works:**
- Runs local web server (dashboard, API, etc.)
- Tailscale Funnel creates HTTPS tunnel
- Public URL: `https://machine.ts.net:port`
- Zero hosting costs, automatic SSL

**Configuration:** Same file: `~/.config/relayq/env`

### 3. Unified Configuration
**Purpose:** ONE file for all settings

**Location:** `~/.config/relayq/env`

**Contains:**
- ASR backend settings (Whisper, OpenAI, etc.)
- API keys
- Tailscale Funnel URLs (auto-updated!)
- Dashboard ports
- All environment variables

**Philosophy:** No multiple config files, no confusion, just one source of truth.

## How Everything Works Together

### Job Flow Example

1. **Submit transcription job:**
   ```bash
   # From OCI VM or via public API
   ./bin/dispatch.sh .github/workflows/transcribe_audio.yml \
     url=https://example.com/podcast.mp3
   ```

2. **GitHub Actions queues job:**
   - Job appears in GitHub Actions queue
   - Waits for available runner

3. **Runner picks up job:**
   - Mac Mini (or RPi4) polls GitHub
   - Sees matching job (based on labels)
   - Starts execution

4. **Job executes:**
   - Loads config from `~/.config/relayq/env`
   - Uses `ASR_BACKEND` setting
   - Downloads audio with yt-dlp
   - Transcribes with Whisper (or OpenAI API)
   - Saves result

5. **Results available:**
   - GitHub Actions artifact uploaded
   - Optionally saved to public artifacts server
   - Dashboard shows completion

6. **Users can access:**
   - Dashboard: `https://oci-vm.ts.net:8000` (job status)
   - API: `https://oci-vm.ts.net:8001/api/submit` (submit new jobs)
   - Results: `https://oci-vm.ts.net:8002/artifacts/<job-id>` (download)

### Configuration Flow

1. **Setup once:**
   ```bash
   # Create unified config
   cp jobs/env.example ~/.config/relayq/env
   nano ~/.config/relayq/env
   ```

2. **Used everywhere:**
   - ✅ GitHub Actions workflows: `source ~/.config/relayq/env`
   - ✅ Dashboard: `load_dotenv('~/.config/relayq/env')`
   - ✅ Tailscale scripts: Auto-update `TAILSCALE_FUNNEL_BASE_URL`

3. **Auto-updated:**
   - When you run `funnel-start.sh`, it updates the BASE_URL
   - No manual URL management needed

## Complete Setup Guide

### Prerequisites
- Tailscale installed on all machines
- GitHub CLI (`gh`) authenticated
- Self-hosted runners registered

### Step 1: Configure Unified Environment

```bash
# Copy template
cp jobs/env.example ~/.config/relayq/env

# Edit with your settings
nano ~/.config/relayq/env
```

Set:
- `ASR_BACKEND=local` (or `openai`)
- `WHISPER_MODEL=base` (or `small`, `large-v3`)
- `AI_API_KEY=sk-...` (if using OpenAI)

### Step 2: Setup Runners (One-time)

**On each machine (Mac Mini, RPi4, etc.):**
```bash
# Register runner
cd /opt/actions-runner
./config.sh --url https://github.com/YOUR_USER/relayq --token YOUR_TOKEN

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start
```

### Step 3: Setup Public Access (Optional)

**On OCI VM (or any always-on machine):**
```bash
cd ~/relayq/tailscale-funnel-module

# One-time setup
./scripts/funnel-setup.sh

# Start dashboard
cd ~/relayq
python examples/relayq/dashboard.py &

# Enable public access
cd tailscale-funnel-module
./scripts/funnel-start.sh
```

### Step 4: Submit Jobs

**Via CLI:**
```bash
./bin/dispatch.sh .github/workflows/transcribe_audio.yml \
  url=https://example.com/audio.mp3
```

**Via Public API:**
```bash
curl -X POST https://oci-vm.ts.net:8001/api/submit \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/audio.mp3"}'
```

**Via GitHub UI:**
1. Go to Actions tab
2. Select workflow
3. Click "Run workflow"

## File Structure

```
relayq/
├── README.md                          # Main overview (start here)
├── SYSTEM_OVERVIEW.md                 # This file (complete picture)
│
├── ~/.config/relayq/env              # UNIFIED CONFIG (everything in ONE file)
│
├── bin/
│   └── dispatch.sh                    # Submit jobs to GitHub Actions
│
├── .github/workflows/
│   ├── transcribe_audio.yml          # Pooled execution
│   ├── transcribe_mac.yml            # Mac Mini only
│   ├── transcribe_rpi.yml            # RPi4 only
│   └── push_transcribe.yml           # Auto-run on push
│
├── jobs/
│   └── env.example                    # Template for ~/.config/relayq/env
│
├── docs/                              # Core RelayQ documentation
│   ├── OVERVIEW.md
│   ├── SETUP_RUNNERS_mac.md
│   └── ...
│
└── tailscale-funnel-module/          # Public web access
    ├── QUICKSTART.md                  # Start here for Funnel
    ├── README.md                      # Funnel overview
    ├── TAILSCALE_COMPLETE_STACK.md   # Complete infrastructure guide
    │
    ├── scripts/
    │   ├── funnel-setup.sh           # One-time setup
    │   ├── funnel-start.sh           # Enable public access
    │   ├── funnel-stop.sh            # Disable public access
    │   └── funnel-status.sh          # Check status
    │
    ├── examples/relayq/
    │   ├── dashboard.py              # Public dashboard
    │   └── README.md                 # Dashboard guide
    │
    └── docs/
        ├── ARCHITECTURE.md           # How Funnel works
        ├── SECURITY.md               # Security best practices
        ├── MCP_INTEGRATION.md        # AI-driven management
        └── TROUBLESHOOTING.md        # Common issues
```

## Key Concepts

### 1. Zero Infrastructure Costs
- ✅ GitHub Actions: Free (2,000 minutes/month)
- ✅ Self-hosted runners: Your hardware (one-time cost)
- ✅ Tailscale: Free tier (generous limits)
- ✅ OCI VM: Free tier (4 ARM cores, 24GB RAM)

**Total monthly cost: $0**

### 2. Unified Configuration
- ✅ ONE file: `~/.config/relayq/env`
- ✅ Used by: Workflows, dashboard, scripts
- ✅ Auto-updated: Funnel scripts update BASE_URL
- ✅ No sync issues: Single source of truth

### 3. GitHub-First Queue
- ✅ No Redis, no message brokers
- ✅ GitHub Actions = free queue
- ✅ Built-in retries, logs, artifacts
- ✅ Familiar UI for non-technical users

### 4. Tailscale Mesh Network
- ✅ All machines connected securely
- ✅ No port forwarding needed
- ✅ Automatic encryption (WireGuard)
- ✅ MagicDNS for easy addressing

### 5. Local-First Processing
- ✅ Jobs run on your hardware
- ✅ Complete privacy
- ✅ No data sent to cloud (unless using OpenAI API)
- ✅ Full control

## Common Workflows

### Add New Runner

```bash
# 1. Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# 2. Copy unified config
scp ~/.config/relayq/env new-machine:~/.config/relayq/env

# 3. Register GitHub runner
# (Follow GitHub instructions)

# 4. Done! Machine will pick up jobs
```

### Deploy Dashboard Update

```bash
# 1. Update code
git pull

# 2. Restart dashboard
pkill -f dashboard.py
python examples/relayq/dashboard.py &

# 3. Verify
curl http://localhost:8000/health

# Public URL still works (Funnel stays active)
```

### Change ASR Backend

```bash
# 1. Edit unified config
nano ~/.config/relayq/env

# Change: ASR_BACKEND=local to ASR_BACKEND=openai
# Add: AI_API_KEY=sk-...

# 2. No restart needed! Next job will use new settings
```

### Add API Authentication

```bash
# 1. Generate key
python -c "import secrets; print(secrets.token_urlsafe(32))"

# 2. Add to unified config
nano ~/.config/relayq/env
# Add: RELAYQ_API_KEY=<generated-key>

# 3. Restart dashboard
pkill -f dashboard.py
python examples/relayq/dashboard.py &

# 4. Use in requests
curl -X POST https://oci-vm.ts.net:8001/api/submit \
  -H "X-API-Key: <your-key>" \
  -d '...'
```

## Documentation Roadmap

**New to RelayQ? Start here:**
1. Read main [README.md](README.md)
2. Check [docs/OVERVIEW.md](docs/OVERVIEW.md)
3. Follow setup guides for your machines

**Want public web access?**
1. Read [tailscale-funnel-module/QUICKSTART.md](tailscale-funnel-module/QUICKSTART.md) ⭐
2. Follow the 3 simple steps
3. Your dashboard is public!

**Want AI-driven management?**
1. Read [tailscale-funnel-module/docs/MCP_INTEGRATION.md](tailscale-funnel-module/docs/MCP_INTEGRATION.md)
2. Setup Tailscale MCP server
3. Let AI manage your infrastructure

**Need help?**
1. Check [tailscale-funnel-module/docs/TROUBLESHOOTING.md](tailscale-funnel-module/docs/TROUBLESHOOTING.md)
2. Read relevant docs/ files
3. Open GitHub issue

## Why This Architecture?

### Problem: Traditional Hosting is Expensive
- Vercel: $20/month
- Railway: $5-25/month
- Databases: $10-50/month
- Domain: $10-50/year
- SSL: Time/money

**Total: $100-500/month**

### Solution: Use What You Have
- GitHub Actions: Free queue
- Your hardware: One-time cost
- Tailscale: Free tier
- OCI VM: Free tier

**Total: $0/month**

### Benefits
- ✅ Zero ongoing costs
- ✅ Complete privacy
- ✅ Full control
- ✅ Instant updates (local restart)
- ✅ No vendor lock-in
- ✅ AI-manageable via MCP

### Tradeoffs
- ⚠️ Limited to personal-scale (<1000 users)
- ⚠️ Machine must stay running
- ⚠️ No global CDN
- ⚠️ Limited by home internet bandwidth

**Perfect for: Personal projects, side businesses, internal tools**

## Summary

RelayQ provides:
1. **Free job orchestration** via GitHub Actions
2. **Local processing** on your hardware
3. **Public web access** via Tailscale Funnel (optional)
4. **Unified configuration** in one file
5. **AI management** via Tailscale MCP (optional)

**All for $0/month.**

Read the QUICKSTART for Tailscale Funnel to get your dashboard online in 3 commands!
