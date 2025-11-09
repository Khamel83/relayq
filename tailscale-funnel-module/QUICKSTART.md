# Quick Start - Tailscale Funnel for RelayQ

**TL;DR: One config file (`~/.config/relayq/env`) for everything. Three commands to go public.**

## The Unified Config Approach

**Everything is in ONE file:** `~/.config/relayq/env`

This file contains:
- ✅ ASR backend settings (Whisper, OpenAI, etc.)
- ✅ API keys
- ✅ Tailscale Funnel configuration
- ✅ RelayQ dashboard settings
- ✅ All environment variables

**No more multiple .env files!**

## First Time Setup (5 minutes)

### 1. Run Setup Script

```bash
cd relayq/tailscale-funnel-module
./scripts/funnel-setup.sh
```

This will:
- Check Tailscale is installed and running
- Create `~/.config/relayq/env` (if needed)
- Add Tailscale configuration to it
- Auto-populate your machine name and tailnet

### 2. Edit Your Unified Config

```bash
nano ~/.config/relayq/env
```

The file now has everything:

```bash
# Your existing RelayQ settings
ASR_BACKEND=local
WHISPER_MODEL=base
AI_API_KEY=sk-your-api-key-here

# NEW: Tailscale settings (auto-added by funnel-setup.sh)
TAILSCALE_FUNNEL_BASE_URL=https://oci-vm.your-tailnet.ts.net:8000
TAILSCALE_MACHINE_NAME=oci-vm
TAILSCALE_TAILNET=.your-tailnet.ts.net

# Optional: For AI-driven management
# TAILSCALE_API_KEY=tskey-api-your-key-here

# Dashboard ports
RELAYQ_DASHBOARD_PORT=8000
RELAYQ_API_PORT=8001
RELAYQ_ARTIFACTS_PORT=8002

# Optional: API authentication
# RELAYQ_API_KEY=your-secret-key
```

**That's it!** One file, everything in one place.

### 3. Deploy Dashboard (Optional)

```bash
# Install Flask if needed
pip install flask python-dotenv

# Run the dashboard
python examples/relayq/dashboard.py
```

The dashboard automatically reads from `~/.config/relayq/env`!

### 4. Make It Public

```bash
# In another terminal
cd relayq/tailscale-funnel-module
./scripts/funnel-start.sh
```

**Done!** Your dashboard is now public at `https://your-machine.ts.net:8000`

The script automatically updates `TAILSCALE_FUNNEL_BASE_URL` in `~/.config/relayq/env`.

## Daily Usage

### Check Status
```bash
cd relayq/tailscale-funnel-module
./scripts/funnel-status.sh
```

### Start Funnel
```bash
./scripts/funnel-start.sh
```

### Stop Funnel (Make Private Again)
```bash
./scripts/funnel-stop.sh
```

## How the Unified Config Works

### Before (Multiple Files - Confusing!)
```
❌ ~/.config/relayq/env         # RelayQ settings
❌ .env.tailscale                # Tailscale settings
❌ .env.local                    # Local overrides
❌ config.json                   # More config?
```

### After (One File - Simple!)
```
✅ ~/.config/relayq/env          # EVERYTHING HERE
```

### Auto-Updates

When you run `funnel-start.sh`, it automatically updates this line:
```bash
TAILSCALE_FUNNEL_BASE_URL=https://your-machine.ts.net:8000
```

So your apps always know their public URL!

## Example: Dashboard Setup

The dashboard `examples/relayq/dashboard.py` uses the unified config:

```python
# Load from unified config
ENV_FILE = os.path.expanduser('~/.config/relayq/env')
load_dotenv(ENV_FILE)

# Get values
BASE_URL = os.getenv('TAILSCALE_FUNNEL_BASE_URL')
PORT = int(os.getenv('RELAYQ_DASHBOARD_PORT', 8000))
```

**No separate .env file needed!**

## Real-World Workflow

### On Your OCI VM (Production)

```bash
# 1. Setup once
cd ~/relayq/tailscale-funnel-module
./scripts/funnel-setup.sh

# 2. Edit config
nano ~/.config/relayq/env
# Set: ASR_BACKEND=openai (or local)
# Set: AI_API_KEY=sk-...

# 3. Start dashboard
cd ~/relayq
python examples/relayq/dashboard.py &

# 4. Make public
cd tailscale-funnel-module
./scripts/funnel-start.sh

# 5. Setup systemd (optional, for auto-start)
# See examples/relayq/README.md
```

### On Your Mac Mini (Development)

```bash
# 1. Setup once
cd ~/relayq/tailscale-funnel-module
./scripts/funnel-setup.sh

# 2. Edit config
nano ~/.config/relayq/env
# Set: ASR_BACKEND=local
# Set: WHISPER_MODEL=small

# 3. Test locally first
python examples/relayq/dashboard.py
# Visit: http://localhost:8000

# 4. Share publicly for demo
cd tailscale-funnel-module
./scripts/funnel-start.sh
# Share: https://macmini.ts.net:8000
```

## Configuration Reference

### Environment Variables

| Variable | Auto-Updated? | Purpose |
|----------|---------------|---------|
| `TAILSCALE_FUNNEL_BASE_URL` | ✅ Yes | Public URL, updated by funnel-start.sh |
| `TAILSCALE_MACHINE_NAME` | ✅ Yes | Your machine name, set by funnel-setup.sh |
| `TAILSCALE_TAILNET` | ✅ Yes | Your tailnet, set by funnel-setup.sh |
| `TAILSCALE_API_KEY` | ❌ Manual | For MCP/AI management (optional) |
| `RELAYQ_DASHBOARD_PORT` | ❌ Manual | Dashboard port (default: 8000) |
| `RELAYQ_API_PORT` | ❌ Manual | API port (default: 8001) |
| `RELAYQ_ARTIFACTS_PORT` | ❌ Manual | Artifacts port (default: 8002) |
| `RELAYQ_API_KEY` | ❌ Manual | API authentication (optional) |

### Files

| File | Purpose | Edit? |
|------|---------|-------|
| `~/.config/relayq/env` | **ALL configuration** | ✅ Yes - your main config |
| `jobs/env.example` | Template/reference | ❌ No - just a template |
| `tailscale-config.json` | Port settings | ⚠️ Rarely - only if changing ports |

## Troubleshooting

### "Dashboard can't find config"
```bash
# Check file exists
ls -la ~/.config/relayq/env

# If missing, run setup
cd relayq/tailscale-funnel-module
./scripts/funnel-setup.sh
```

### "Public URL not working"
```bash
# 1. Check Funnel status
cd relayq/tailscale-funnel-module
./scripts/funnel-status.sh

# 2. Verify app listens on 0.0.0.0
# In your code: app.run(host='0.0.0.0', port=8000)

# 3. Test locally first
curl http://localhost:8000/health
```

### "Variables not loading"
```bash
# Test loading
source ~/.config/relayq/env
echo $TAILSCALE_FUNNEL_BASE_URL

# Should show your URL
# If empty, run funnel-setup.sh again
```

## What's Different from Traditional Setup?

### Traditional Approach
1. Create `.env` in project directory
2. Copy settings for each project
3. Keep files in sync manually
4. Remember which file has what

### Unified Approach (This Module)
1. **One file:** `~/.config/relayq/env`
2. **All projects read from it**
3. **Auto-updated** by scripts
4. **Never out of sync**

## Next Steps

- **Production deployment:** See `examples/relayq/README.md`
- **Security:** See `docs/SECURITY.md`
- **MCP/AI management:** See `docs/MCP_INTEGRATION.md`
- **Complete stack:** See `TAILSCALE_COMPLETE_STACK.md`

## Summary

**Three commands:**
```bash
# 1. Setup (once)
./scripts/funnel-setup.sh

# 2. Edit config (once)
nano ~/.config/relayq/env

# 3. Go public (anytime)
./scripts/funnel-start.sh
```

**One file for everything:**
```
~/.config/relayq/env
```

**Zero hosting costs:**
```
$0/month 🎉
```

That's it! You're using Tailscale for everything.
