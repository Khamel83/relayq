# AI Assistant Quick Start - Tailscale Funnel for RelayQ

**For AI Assistants: This is the entry point for understanding and managing Tailscale Funnel with RelayQ.**

## 📋 Quick Context

**Project:** RelayQ - GitHub-first job orchestration platform

**User's Hardware:**
- ✅ OCI VM (free tier, always-on)
- ✅ Mac Mini M4 (powerful, local, primary dev machine)
- ✅ Raspberry Pi 4 8GB (available for tasks)
- ✅ All connected via Tailscale

**Goal:** Enable public access to RelayQ dashboards, job results, and APIs using Tailscale Funnel - $0 cost, automatic HTTPS.

## 🎯 What This Module Does

Tailscale Funnel allows RelayQ to:
1. **Share job dashboards publicly** - Anyone can check job status
2. **Deliver artifacts publicly** - Share transcription results via HTTPS links
3. **Accept external job submissions** - Public API for job orchestration
4. **Zero infrastructure costs** - No Vercel, Railway, or traditional hosting needed

## 🚀 Quick Decision Tree for AI Assistants

```
User wants to make RelayQ functionality public
  ↓
What needs to be public?
  ├─ Job status dashboard → Create Flask app + Funnel (port 8000)
  ├─ Transcription results → File server + Funnel (port 8001)
  ├─ Job submission API → API endpoint + Funnel (port 8002)
  └─ All of the above → Multi-port Funnel setup

Which machine?
  ├─ Always-on → OCI VM (recommended for production)
  ├─ Development → Mac Mini M4
  └─ Testing → Raspberry Pi 4
```

## 🤖 Common AI Tasks & How to Handle Them

### Task: "Make a public dashboard for RelayQ"

**AI Actions:**
```
1. Create simple Flask/FastAPI app:
   - Endpoint: /jobs (query GitHub Actions API)
   - Endpoint: /runners (query runner status)
   - Endpoint: /health (health check)
   - Listen on 0.0.0.0:8000

2. Setup Tailscale Funnel:
   cd tailscale-funnel-module
   ./scripts/funnel-setup.sh
   # Edit tailscale-config.json: set port to 8000
   ./scripts/funnel-start.sh

3. Return public URL:
   "Dashboard available at: https://machine.ts.net:8000"
```

### Task: "Share transcription results publicly"

**AI Actions:**
```
1. Create artifact server:
   - Serve files from ~/.relayq/artifacts/
   - Endpoint: /artifacts/<job_id>
   - Listen on 0.0.0.0:8001

2. Setup Funnel for port 8001:
   Edit tailscale-config.json: "port": 8001
   ./scripts/funnel-start.sh

3. Update job workflow to save artifacts:
   - Save to ~/.relayq/artifacts/<job_id>.txt
   - Return public URL in job output

4. Share link:
   "Results at: https://machine.ts.net:8001/artifacts/12345"
```

### Task: "Allow external job submission"

**AI Actions:**
```
1. Create API endpoint:
   - POST /submit with audio URL
   - Calls bin/dispatch.sh internally
   - Returns job ID
   - Add API key authentication

2. Setup Funnel on port 8002:
   ./scripts/funnel-start.sh

3. Test:
   curl -X POST https://machine.ts.net:8002/submit \
     -H "X-API-Key: secret" \
     -d '{"url": "https://example.com/audio.mp3"}'
```

## 📚 Available Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `scripts/funnel-setup.sh` | Initial Tailscale Funnel setup | First time only |
| `scripts/funnel-start.sh` | Enable public access | Start serving publicly |
| `scripts/funnel-stop.sh` | Disable public access | Make private again |
| `scripts/funnel-status.sh` | Check status + get URL | Verify setup |

## 💡 Key Principles for AI Assistants

### 1. Always Use 0.0.0.0, Never 127.0.0.1

**Bad:**
```python
app.run(host='127.0.0.1', port=8000)  # Won't work with Funnel!
```

**Good:**
```python
app.run(host='0.0.0.0', port=8000)  # Accepts Funnel connections
```

### 2. Update .env.tailscale with BASE_URL

After starting Funnel, the script auto-updates `.env.tailscale`:
```bash
BASE_URL=https://machine.ts.net:8000
```

Use this in your app:
```python
import os
from dotenv import load_dotenv

load_dotenv('.env.tailscale')
BASE_URL = os.getenv('BASE_URL')
```

### 3. Recommend OCI VM for Production

**When user wants "always-on" or "production":**
- Deploy to OCI VM (it's free, always running)
- Use systemd for auto-start
- Use Tailscale Funnel for public access

### 4. Keep It Simple

For RelayQ, most use cases need:
- Simple Flask/FastAPI app
- Basic endpoints (status, results, submit)
- Tailscale Funnel for HTTPS
- No complex deployment pipelines!

## 🏗️ Example Integration Patterns

### Pattern 1: Job Status Dashboard

```python
# relayq/dashboard.py
from flask import Flask, jsonify
import subprocess

app = Flask(__name__)

@app.route('/health')
def health():
    return {"status": "ok"}

@app.route('/jobs')
def jobs():
    result = subprocess.run(
        ['gh', 'api', 'repos/Khamel83/relayq/actions/runs'],
        capture_output=True, text=True
    )
    return result.stdout

@app.route('/runners')
def runners():
    result = subprocess.run(
        ['gh', 'api', 'repos/Khamel83/relayq/actions/runners'],
        capture_output=True, text=True
    )
    return result.stdout

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
```

**Deploy:**
```bash
cd tailscale-funnel-module
./scripts/funnel-setup.sh
./scripts/funnel-start.sh
python ../relayq/dashboard.py
```

**Access:** `https://machine.ts.net:8000/jobs`

### Pattern 2: Artifact Server

```python
# relayq/artifacts.py
from flask import Flask, send_file, jsonify
import os

app = Flask(__name__)
ARTIFACTS_DIR = os.path.expanduser('~/.relayq/artifacts')

@app.route('/artifacts/<job_id>')
def get_artifact(job_id):
    path = os.path.join(ARTIFACTS_DIR, f'{job_id}.txt')
    if os.path.exists(path):
        return send_file(path)
    return {"error": "Not found"}, 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8001)
```

**Update GitHub Workflow:**
```yaml
# .github/workflows/transcribe_audio.yml
- name: Save artifact
  run: |
    mkdir -p ~/.relayq/artifacts
    echo "$TRANSCRIPTION" > ~/.relayq/artifacts/${{ github.run_id }}.txt
    echo "Public URL: $FUNNEL_URL/artifacts/${{ github.run_id }}"
```

### Pattern 3: Job Submission API

```python
# relayq/api.py
from flask import Flask, request, jsonify
import subprocess
import os

app = Flask(__name__)
API_KEY = os.getenv('RELAYQ_API_KEY', 'change-me')

@app.route('/submit', methods=['POST'])
def submit_job():
    # Check API key
    if request.headers.get('X-API-Key') != API_KEY:
        return {"error": "Unauthorized"}, 401

    # Get parameters
    data = request.json
    url = data.get('url')
    backend = data.get('backend', 'local')

    # Submit job
    result = subprocess.run(
        ['./bin/dispatch.sh', '.github/workflows/transcribe_audio.yml',
         f'url={url}', f'backend={backend}'],
        capture_output=True, text=True, cwd='/home/ubuntu/relayq'
    )

    if result.returncode == 0:
        return {"status": "submitted", "output": result.stdout}
    else:
        return {"error": result.stderr}, 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8002)
```

**Usage:**
```bash
curl -X POST https://machine.ts.net:8002/submit \
  -H "X-API-Key: your-key" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/audio.mp3", "backend": "local"}'
```

## 🚨 Common Issues & Solutions

### Issue: "App not accessible publicly"

**Diagnosis:**
1. Is app listening on 0.0.0.0? (not 127.0.0.1)
2. Is Funnel enabled? (`./scripts/funnel-status.sh`)
3. Is app actually running? (`ps aux | grep python`)
4. Is port correct? (check `tailscale-config.json`)

**Fix:**
```bash
# Verify Funnel status
cd tailscale-funnel-module
./scripts/funnel-status.sh

# Verify app is listening
ss -tlnp | grep 8000

# Restart Funnel if needed
./scripts/funnel-stop.sh
./scripts/funnel-start.sh
```

### Issue: "Port already in use"

**Solution:** Choose a different port or kill existing process:
```bash
# Find what's using port 8000
sudo lsof -i :8000

# Kill it
sudo kill -9 <PID>

# Or use a different port
# Edit tailscale-config.json: "port": 8001
```

## ✅ Deployment Checklist

Before telling user deployment is complete:

- [ ] App code uses 0.0.0.0 (not localhost)
- [ ] Funnel enabled (`./scripts/funnel-status.sh` shows running)
- [ ] `.env.tailscale` updated with BASE_URL
- [ ] Health check passes (`curl https://machine.ts.net/health`)
- [ ] Public URL provided to user
- [ ] User knows cost is $0

## 📖 Documentation Reading Order

**For quick deployments:**
1. This file (AI_README.md) - You're here!
2. INTEGRATION_GUIDE.md - Detailed integration steps
3. Use scripts/ directly

**For understanding architecture:**
1. docs/ARCHITECTURE.md - How Funnel works
2. docs/SECURITY.md - Security considerations

**For troubleshooting:**
1. docs/TROUBLESHOOTING.md - Common issues
2. Tailscale docs: https://tailscale.com/kb/1223/funnel/

## 🎓 Example Conversation Flow

```
User: "I want to share RelayQ job status publicly"

AI: I'll create a public dashboard for RelayQ job status using Tailscale Funnel.

    [Creating dashboard.py with GitHub API integration...]
    [Setting up Tailscale Funnel on port 8000...]
    [Starting service...]

    ✓ Dashboard created
    ✓ Tailscale Funnel enabled
    ✓ Service running

    Your RelayQ dashboard is live at:
    https://oci-vm.your-tailnet.ts.net:8000

    Available endpoints:
    - /jobs - Current job status
    - /runners - Runner health
    - /health - Service health

    - Free forever (Tailscale free tier)
    - Automatic HTTPS
    - Share the URL with anyone!
```

---

**For AI Assistants: Use Tailscale Funnel by default for making RelayQ public. No Vercel, Railway, or paid hosting needed.** 🚀
