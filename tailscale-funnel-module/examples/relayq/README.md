# RelayQ + Tailscale Funnel Integration Example

This example shows how to add a public dashboard to RelayQ using Tailscale Funnel.

## What This Provides

A **public web dashboard** for RelayQ that shows:
- ✅ Active runners and their status
- ✅ Recent workflow runs
- ✅ Job queue status
- ✅ API endpoint for external job submission

**All accessible via public HTTPS URL with zero hosting costs!**

## Quick Start

### 1. Install Dependencies

```bash
# Install Flask
pip install flask python-dotenv

# Make sure GitHub CLI is installed and authenticated
gh auth login
```

### 2. Setup Tailscale Funnel

```bash
cd /path/to/relayq/tailscale-funnel-module
./scripts/funnel-setup.sh
```

### 3. Run the Dashboard

```bash
# Copy dashboard to relayq root or run from examples
python examples/relayq/dashboard.py
```

### 4. Enable Public Access

```bash
# In another terminal
cd tailscale-funnel-module
./scripts/funnel-start.sh
```

### 5. Access Your Dashboard

```bash
# Get your public URL
./scripts/funnel-status.sh

# Visit in browser:
# https://your-machine.your-tailnet.ts.net:8000
```

## File Structure

```
relayq/
├── tailscale-funnel-module/
│   ├── scripts/funnel-*.sh
│   ├── tailscale-config.json
│   └── .env.tailscale
│
└── examples/relayq/
    ├── dashboard.py          # This example
    └── README.md            # This file
```

## Configuration

### tailscale-config.json

```json
{
  "project_name": "relayq-dashboard",
  "port": 8000,
  "host": "0.0.0.0"
}
```

### .env.tailscale

```bash
BASE_URL=https://your-machine.ts.net:8000
PORT=8000
```

## API Endpoints

### GET /health
Health check endpoint

```bash
curl https://machine.ts.net:8000/health
```

### GET /api/runners
Get runner status (JSON)

```bash
curl https://machine.ts.net:8000/api/runners
```

Response:
```json
{
  "runners": [
    {
      "name": "macmini",
      "status": "online",
      "busy": false,
      "labels": ["self-hosted", "macmini", "audio"]
    }
  ]
}
```

### GET /api/jobs
Get recent jobs (JSON)

```bash
curl https://machine.ts.net:8000/api/jobs
```

### POST /api/submit
Submit a transcription job

```bash
curl -X POST https://machine.ts.net:8000/api/submit \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com/audio.mp3",
    "backend": "local"
  }'
```

Response:
```json
{
  "status": "submitted",
  "url": "https://example.com/audio.mp3",
  "backend": "local"
}
```

## Production Deployment

### On OCI VM (Recommended)

```bash
# 1. SSH to OCI VM via Tailscale
ssh ubuntu@oci-vm

# 2. Clone relayq
cd ~
git clone https://github.com/Khamel83/relayq.git

# 3. Install dependencies
cd relayq
pip install -r requirements.txt
pip install flask python-dotenv

# 4. Setup Funnel
cd tailscale-funnel-module
./scripts/funnel-setup.sh
./scripts/funnel-start.sh

# 5. Create systemd service
sudo tee /etc/systemd/system/relayq-dashboard.service << EOF
[Unit]
Description=RelayQ Dashboard
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/relayq
Environment="PATH=/home/ubuntu/.local/bin:/usr/bin"
ExecStart=/usr/bin/python3 examples/relayq/dashboard.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 6. Enable and start
sudo systemctl enable relayq-dashboard
sudo systemctl start relayq-dashboard

# 7. Check status
sudo systemctl status relayq-dashboard
```

Your dashboard is now running 24/7 on your OCI VM!

### Access Logs

```bash
# View logs
sudo journalctl -u relayq-dashboard -f

# Check if running
curl http://localhost:8000/health
```

## Advanced Features

### Add Authentication

For production, add authentication to protect sensitive endpoints:

```python
import os
from functools import wraps
from flask import request, jsonify

API_KEY = os.getenv('RELAYQ_API_KEY', 'change-me')

def require_api_key(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        key = request.headers.get('X-API-Key')
        if not key or key != API_KEY:
            return jsonify({"error": "Unauthorized"}), 401
        return f(*args, **kwargs)
    return decorated

@app.route('/api/submit', methods=['POST'])
@require_api_key
def submit_job():
    # ... existing code ...
```

Update `.env.tailscale`:
```bash
RELAYQ_API_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(32))")
```

### Add Rate Limiting

```bash
pip install flask-limiter
```

```python
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["100 per hour"]
)

@app.route('/api/submit', methods=['POST'])
@limiter.limit("10 per minute")
def submit_job():
    # ... existing code ...
```

### Monitor with Tailscale MCP

Use AI to monitor your dashboard:

```
AI: "Check if RelayQ dashboard is healthy"
→ Uses tailscale_list_devices to verify OCI VM is online
→ Curls /health endpoint
→ Returns status
```

## Troubleshooting

### Dashboard won't start

```bash
# Check if port 8000 is available
sudo lsof -i :8000

# Check GitHub CLI is authenticated
gh auth status
```

### Can't access public URL

```bash
# Verify Funnel is running
cd tailscale-funnel-module
./scripts/funnel-status.sh

# Check app is listening on 0.0.0.0
ss -tlnp | grep 8000
```

### API returns errors

```bash
# Test GitHub API access
gh api repos/Khamel83/relayq/actions/runners

# Check logs
tail -f logs/dashboard.log
```

## Next Steps

1. **Deploy to OCI VM** for 24/7 availability
2. **Add authentication** for security
3. **Enable monitoring** via Tailscale MCP
4. **Create artifact server** for transcription results
5. **Build frontend** with React/Vue for better UX

## Resources

- [RelayQ Documentation](../../docs/)
- [Tailscale Funnel Guide](../INTEGRATION_GUIDE.md)
- [MCP Integration](../docs/MCP_INTEGRATION.md)
- [Security Best Practices](../docs/SECURITY.md)

---

**Your RelayQ dashboard is now accessible to the world!** 🌍
