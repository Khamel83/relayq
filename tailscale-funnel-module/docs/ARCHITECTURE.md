# Tailscale Funnel Architecture

## Overview

Tailscale Funnel enables you to share local services on the public internet with automatic HTTPS, without requiring port forwarding, DNS configuration, or SSL certificate management.

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                     Public Internet                          │
│                                                               │
│  User's Browser                                               │
│       │                                                       │
│       │ HTTPS Request                                        │
│       │ https://machine.tailnet.ts.net:8000                  │
│       ▼                                                       │
│  ┌─────────────────────────────────────┐                    │
│  │   Tailscale Infrastructure          │                    │
│  │   - DNS Resolution (.ts.net)        │                    │
│  │   - TLS Termination (automatic)     │                    │
│  │   - Routing to your machine         │                    │
│  └─────────────────────────────────────┘                    │
│       │                                                       │
└───────┼───────────────────────────────────────────────────────┘
        │
        │ Encrypted Tunnel (WireGuard)
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│                    Your Local Machine                        │
│                                                               │
│  ┌─────────────────────────────┐                            │
│  │   Tailscale Daemon          │                            │
│  │   - Funnel listener         │                            │
│  │   - Routes to localhost     │                            │
│  └─────────────────────────────┘                            │
│       │                                                       │
│       │ HTTP Request (local)                                 │
│       │ http://0.0.0.0:8000                                  │
│       ▼                                                       │
│  ┌─────────────────────────────┐                            │
│  │   Your Application          │                            │
│  │   - Flask/FastAPI/etc       │                            │
│  │   - Listens on 0.0.0.0:8000 │                            │
│  └─────────────────────────────┘                            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. Tailscale Daemon
- Runs on your machine
- Creates WireGuard VPN tunnel
- Manages Funnel routing

### 2. Tailscale Infrastructure
- Provides DNS (*.ts.net)
- Handles TLS certificates (automatic)
- Routes traffic to your machine

### 3. Your Application
- Runs locally on your machine
- Listens on 0.0.0.0 (important!)
- Receives requests from Tailscale daemon

## Request Flow

1. **User accesses URL:** `https://machine.tailnet.ts.net:8000`
2. **DNS resolution:** Tailscale resolves `.ts.net` domain
3. **TLS handshake:** Tailscale terminates SSL (automatic certificate)
4. **Routing:** Request routed through WireGuard tunnel to your machine
5. **Local proxy:** Tailscale daemon forwards to `localhost:8000`
6. **App handles request:** Your app processes and responds
7. **Response flows back:** Through tunnel, encrypted, to user

## Security Model

### What Tailscale Handles
- ✅ TLS encryption (public internet → your machine)
- ✅ Certificate management (automatic)
- ✅ DDoS protection (basic)
- ✅ Transport security (WireGuard)

### What You Must Handle
- ⚠️ Application-level authentication
- ⚠️ Rate limiting
- ⚠️ Input validation
- ⚠️ Access control

**Important:** Anyone with your `.ts.net` URL can access your app. Add authentication!

## Comparison with Alternatives

### Tailscale Funnel vs. Traditional Hosting

| Aspect | Tailscale Funnel | Traditional VPS |
|--------|-----------------|----------------|
| **Infrastructure** | None (runs locally) | VPS required |
| **DNS** | Automatic (.ts.net) | Configure manually |
| **SSL** | Automatic | Let's Encrypt / manual |
| **Port forwarding** | Not needed | Often required |
| **Deployment** | Just run locally | Push/deploy/restart |
| **Updates** | Instant (restart) | Deploy pipeline |
| **Cost** | $0 | $5-100+/month |
| **Uptime** | Depends on machine | Depends on provider |
| **Custom domain** | Not by default | Yes |

### Tailscale Funnel vs. ngrok

| Aspect | Tailscale Funnel | ngrok |
|--------|-----------------|-------|
| **Free tier** | Generous | 2-hour sessions |
| **Persistent URLs** | Yes (.ts.net) | Paid only |
| **Custom domains** | Possible | Paid only |
| **Speed** | Fast (direct) | Fast (direct) |
| **Privacy** | High | Medium |
| **Setup** | Simple | Simpler |
| **Use case** | Long-term sharing | Quick demos |

### Tailscale Funnel vs. Cloudflare Tunnel

| Aspect | Tailscale Funnel | Cloudflare Tunnel |
|--------|-----------------|-------------------|
| **Setup complexity** | Low | Medium |
| **Custom domains** | Possible | Easy |
| **Network** | Tailscale mesh | Cloudflare CDN |
| **Privacy** | High | Medium |
| **Features** | Basic | Advanced |
| **Best for** | Personal projects | Production sites |

## Limitations

### Performance
- **Bandwidth:** Limited by your internet connection
- **Latency:** Depends on your location
- **Concurrent connections:** Limited by your hardware

### Reliability
- **Uptime:** Machine must stay running
- **Power:** Loss = downtime
- **Network:** Internet outage = unavailable

### Scale
- **Users:** Good for < 100 concurrent users
- **Traffic:** Limited by home internet (typically 100-1000 Mbps)
- **Geography:** Single location (your machine)

## Best Practices

### 1. Always Listen on 0.0.0.0

```python
# ❌ Bad - won't work with Funnel
app.run(host='127.0.0.1', port=8000)

# ✅ Good - accepts connections from Tailscale
app.run(host='0.0.0.0', port=8000)
```

### 2. Use Environment Variables

```python
import os
from dotenv import load_dotenv

load_dotenv('.env.tailscale')

BASE_URL = os.getenv('BASE_URL')  # Auto-updated by funnel-start.sh
```

### 3. Add Health Checks

```python
@app.route('/health')
def health():
    return {"status": "ok", "timestamp": time.time()}
```

### 4. Implement Authentication

```python
from functools import wraps

def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        if token != f"Bearer {API_KEY}":
            return {"error": "Unauthorized"}, 401
        return f(*args, **kwargs)
    return decorated

@app.route('/api/data')
@require_auth
def get_data():
    return {"data": "secret"}
```

### 5. Use Process Managers

For production use:

```bash
# systemd (Linux)
sudo systemctl enable myapp

# PM2 (Node.js)
pm2 start app.js
pm2 startup
pm2 save

# supervisord (Python)
supervisorctl start myapp
```

## Advanced Configuration

### Multiple Ports

You can expose multiple services:

```bash
# Port 8000 for API
tailscale funnel --bg --https=443 8000

# Port 8001 for dashboard
tailscale funnel --bg --https=443 8001
```

Access:
- API: `https://machine.ts.net:8000`
- Dashboard: `https://machine.ts.net:8001`

### Custom Domains

You can use custom domains with Tailscale Funnel:

1. Add CNAME record:
   ```
   api.yourdomain.com CNAME machine.tailnet.ts.net
   ```

2. Tailscale automatically handles SSL for the custom domain

### High Availability

For better reliability:

1. **Use always-on machine:** OCI VM, dedicated server, etc.
2. **Auto-restart:** Use systemd, PM2, or supervisor
3. **Monitoring:** Set up health check alerts
4. **Backup machine:** Run same service on multiple machines

## Monitoring & Debugging

### Check Funnel Status

```bash
tailscale funnel status
```

### Check Application

```bash
# Is app listening?
ss -tlnp | grep 8000

# Test locally
curl http://localhost:8000/health

# Test via Funnel
curl https://machine.ts.net:8000/health
```

### View Logs

```bash
# Tailscale logs
sudo journalctl -u tailscaled -f

# Application logs (depends on your setup)
tail -f /var/log/myapp.log
pm2 logs
sudo journalctl -u myapp -f
```

## Performance Optimization

### 1. Use Caching

```python
from functools import lru_cache

@lru_cache(maxsize=128)
def expensive_operation(param):
    # ... expensive computation ...
    return result
```

### 2. Async Processing

```python
from flask import Flask
import asyncio

app = Flask(__name__)

@app.route('/process')
async def process():
    result = await async_heavy_task()
    return result
```

### 3. Load Balancing

Run same service on multiple machines:

```bash
# Machine 1
tailscale serve --name myservice --bg 8000

# Machine 2
tailscale serve --name myservice --bg 8000

# Access: https://myservice.ts.net (auto-balanced)
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

## Further Reading

- [Tailscale Funnel Documentation](https://tailscale.com/kb/1223/funnel/)
- [WireGuard Protocol](https://www.wireguard.com/)
- [Zero Trust Networking](https://www.cloudflare.com/learning/security/glossary/what-is-zero-trust/)
