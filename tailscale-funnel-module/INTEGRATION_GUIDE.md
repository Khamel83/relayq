# Tailscale Funnel Integration Guide

This guide shows how to integrate Tailscale Funnel into your project, with specific examples for RelayQ.

## Quick Integration

### 1. Initial Setup

```bash
# Run the setup script
cd tailscale-funnel-module
./scripts/funnel-setup.sh
```

This creates:
- `tailscale-config.json` - Project configuration
- `.env.tailscale` - Environment variables with your public URL

### 2. Configure Your Port

Edit `tailscale-config.json`:

```json
{
  "project_name": "relayq",
  "port": 8000,
  "host": "0.0.0.0"
}
```

**Important:** Make sure your app listens on `0.0.0.0`, not `127.0.0.1`!

### 3. Start Funnel

```bash
./scripts/funnel-start.sh
```

Your app is now public at `https://your-machine.your-tailnet.ts.net`

## RelayQ-Specific Integration

### Use Case: Public Job Dashboard

If you want to add a web dashboard to RelayQ for viewing job status:

1. **Create a simple Flask/FastAPI server:**

```python
# relayq/dashboard.py
from flask import Flask, jsonify
import subprocess

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "ok"})

@app.route('/jobs')
def jobs():
    # Query GitHub Actions API for job status
    result = subprocess.run(
        ['gh', 'api', 'repos/Khamel83/relayq/actions/runs'],
        capture_output=True,
        text=True
    )
    return result.stdout

@app.route('/runners')
def runners():
    # Get runner status
    result = subprocess.run(
        ['gh', 'api', 'repos/Khamel83/relayq/actions/runners'],
        capture_output=True,
        text=True
    )
    return result.stdout

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
```

2. **Configure Tailscale:**

```bash
cd tailscale-funnel-module
./scripts/funnel-setup.sh
# Edit tailscale-config.json to set port 8000
./scripts/funnel-start.sh
```

3. **Run your dashboard:**

```bash
python relayq/dashboard.py
```

Now anyone can view job status at your public URL!

### Use Case: Public Artifact Sharing

Share transcription results publicly:

```python
# relayq/artifacts.py
from flask import Flask, send_file, jsonify
import os

app = Flask(__name__)

ARTIFACTS_DIR = os.path.expanduser('~/.relayq/artifacts')

@app.route('/artifacts/<job_id>')
def get_artifact(job_id):
    """Serve transcription artifacts publicly"""
    artifact_path = os.path.join(ARTIFACTS_DIR, f'{job_id}.txt')
    if os.path.exists(artifact_path):
        return send_file(artifact_path)
    return jsonify({"error": "Not found"}), 404

@app.route('/artifacts')
def list_artifacts():
    """List all available artifacts"""
    artifacts = os.listdir(ARTIFACTS_DIR)
    return jsonify({"artifacts": artifacts})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8001)
```

## Environment Variables

The `.env.tailscale` file contains your public URL:

```bash
BASE_URL=https://your-machine.your-tailnet.ts.net:8000
```

Use this in your app:

```python
import os
from dotenv import load_dotenv

load_dotenv('.env.tailscale')

BASE_URL = os.getenv('BASE_URL')
print(f"Share this URL: {BASE_URL}")
```

## Multi-Machine Setup

If you're running RelayQ across multiple machines (OCI VM, Mac Mini, RPi):

### OCI VM (Always-On)
```bash
# On OCI VM
cd relayq/tailscale-funnel-module
./scripts/funnel-setup.sh
./scripts/funnel-start.sh
# Public URL: https://oci-vm.your-tailnet.ts.net
```

### Mac Mini (Development)
```bash
# On Mac Mini
cd relayq/tailscale-funnel-module
./scripts/funnel-setup.sh
./scripts/funnel-start.sh
# Public URL: https://macmini.your-tailnet.ts.net
```

Each machine gets its own public URL!

## Integration with GitHub Actions

You can have GitHub Actions jobs post results to your public dashboard:

```yaml
# .github/workflows/transcribe_audio.yml
jobs:
  transcribe:
    runs-on: self-hosted
    steps:
      - name: Transcribe audio
        run: |
          # ... transcription logic ...

      - name: Post result to dashboard
        env:
          DASHBOARD_URL: ${{ secrets.TAILSCALE_DASHBOARD_URL }}
        run: |
          curl -X POST "$DASHBOARD_URL/results" \
            -H "Content-Type: application/json" \
            -d '{"job_id": "${{ github.run_id }}", "status": "complete"}'
```

## Common Patterns

### Pattern 1: Status Dashboard

**Goal:** Public dashboard showing runner status and job queue

**Setup:**
1. Create Flask/FastAPI app on port 8000
2. Query GitHub API for runner/job status
3. Enable Funnel for public access

**Access:** Anyone can check status at `https://machine.ts.net:8000`

### Pattern 2: Artifact Delivery

**Goal:** Share transcription results via public links

**Setup:**
1. Create simple file server on port 8001
2. Save artifacts to known directory
3. Enable Funnel for public download

**Access:** Share `https://machine.ts.net:8001/artifacts/job-123`

### Pattern 3: Job Submission API

**Goal:** Allow external systems to submit jobs

**Setup:**
1. Create API endpoint that calls `bin/dispatch.sh`
2. Add authentication (API keys)
3. Enable Funnel for public access

**Access:** External apps POST to `https://machine.ts.net:8000/submit`

## Troubleshooting

### App Not Accessible

**Problem:** Funnel is running but app not reachable

**Solutions:**
1. Check app listens on `0.0.0.0`:
   ```python
   app.run(host='0.0.0.0', port=8000)  # Good
   app.run(host='127.0.0.1', port=8000)  # Bad!
   ```

2. Verify port matches config:
   ```bash
   # Check tailscale-config.json
   cat tailscale-config.json

   # Check Funnel status
   ./scripts/funnel-status.sh
   ```

3. Test locally first:
   ```bash
   curl http://localhost:8000/health
   ```

### Funnel Won't Start

**Problem:** `funnel-start.sh` fails

**Solutions:**
1. Check Tailscale is running:
   ```bash
   tailscale status
   ```

2. Verify you're logged in:
   ```bash
   sudo tailscale up
   ```

3. Check Tailscale version (Funnel requires recent version):
   ```bash
   tailscale version
   ```

## Next Steps

- Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for design details
- Read [docs/SECURITY.md](docs/SECURITY.md) for security best practices
- Check [examples/relayq/](examples/relayq/) for complete examples

## Questions?

- Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- Review Tailscale Funnel docs: https://tailscale.com/kb/1223/funnel/
