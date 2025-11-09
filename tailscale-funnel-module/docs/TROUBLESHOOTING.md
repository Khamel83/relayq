# Troubleshooting Guide

## Common Issues and Solutions

### Tailscale Issues

#### Funnel Won't Start

**Symptoms:**
```
❌ Failed to enable Tailscale Funnel
```

**Solutions:**

1. **Check Tailscale is running:**
   ```bash
   tailscale status
   ```
   If not running:
   ```bash
   sudo tailscale up
   ```

2. **Verify Tailscale version (Funnel requires v1.38+):**
   ```bash
   tailscale version
   ```
   Update if needed:
   ```bash
   # Linux
   sudo apt update && sudo apt upgrade tailscale

   # macOS
   brew upgrade tailscale
   ```

3. **Check Funnel is enabled on your account:**
   Visit https://login.tailscale.com/admin/settings/features
   Ensure "Funnel" is enabled

#### Public URL Not Accessible

**Symptoms:**
- Funnel status shows "running" but URL returns 404 or connection refused

**Solutions:**

1. **Verify app listens on 0.0.0.0:**
   ```bash
   # Check what your app is listening on
   netstat -an | grep LISTEN | grep <PORT>
   # or
   ss -tlnp | grep <PORT>
   ```

   Fix in your code:
   ```python
   # ❌ Wrong
   app.run(host='127.0.0.1', port=5000)

   # ✅ Correct
   app.run(host='0.0.0.0', port=5000)
   ```

2. **Test locally first:**
   ```bash
   curl http://localhost:8000
   ```
   If this fails, your app isn't running correctly

3. **Check Funnel configuration:**
   ```bash
   tailscale funnel status
   ```
   Verify port matches your app

### Application Issues

#### Port Already in Use

**Symptoms:**
```
Error: Address already in use
```

**Solutions:**

1. **Find what's using the port:**
   ```bash
   sudo lsof -i :8000
   ```

2. **Kill the process:**
   ```bash
   kill -9 <PID>
   ```

3. **Or use a different port:**
   Edit `tailscale-config.json` to use a different port

#### Environment Variables Not Loading

**Symptoms:**
- App can't find configuration
- `BASE_URL` not set

**Solutions:**

1. **Verify .env.tailscale exists:**
   ```bash
   ls -la .env.tailscale
   ```

2. **Check file permissions:**
   ```bash
   chmod 600 .env.tailscale
   ```

3. **Manually source and test:**
   ```bash
   source .env.tailscale
   echo $BASE_URL
   ```

4. **Use python-dotenv or similar:**
   ```python
   from dotenv import load_dotenv
   load_dotenv('.env.tailscale')
   ```

#### Health Check Fails

**Symptoms:**
```
⚠️ Health check failed after 30s
```

**Solutions:**

1. **Verify health endpoint exists:**
   ```bash
   curl http://localhost:8000/health
   ```

2. **Increase timeout in tailscale-config.json:**
   ```json
   {
     "health_check_timeout": 60
   }
   ```

3. **Disable health check temporarily:**
   ```json
   {
     "health_check": {
       "enabled": false
     }
   }
   ```

### Network Issues

#### Connection Timeout

**Symptoms:**
- Requests to public URL timeout
- Works locally but not via Funnel

**Solutions:**

1. **Check Tailscale connectivity:**
   ```bash
   tailscale ping <machine-name>
   ```

2. **Restart Tailscale daemon:**
   ```bash
   sudo systemctl restart tailscaled
   ```

3. **Check firewall (if any):**
   ```bash
   # Linux - check firewall status
   sudo ufw status

   # macOS - check firewall
   /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
   ```

#### Slow Response Times

**Symptoms:**
- App is slow via public URL
- Fast on localhost

**Solutions:**

1. **Check your upload bandwidth** - Funnel uses your upload speed
   ```bash
   # Run speed test
   speedtest-cli
   ```

2. **Optimize app performance:**
   - Enable caching
   - Reduce payload sizes
   - Use async operations

3. **Consider deploying to always-on machine** (OCI VM) instead of laptop

### Script Issues

#### funnel-setup.sh Fails

**Symptoms:**
```
./scripts/funnel-setup.sh: Permission denied
```

**Solutions:**

1. **Make scripts executable:**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Check bash is available:**
   ```bash
   which bash
   ```

#### funnel-start.sh Doesn't Start App

**Symptoms:**
- Funnel starts but app doesn't

**Solutions:**

1. **Test start command manually:**
   ```bash
   # Run command from tailscale-config.json directly
   python app.py
   # or
   npm start
   ```

2. **Check for errors in logs**

3. **Verify working directory is correct**

### SSL/Certificate Issues

#### Browser Shows Certificate Error

**Symptoms:**
- Browser warns about invalid certificate

**Solutions:**

1. **Verify you're using .ts.net URL** (not IP address)

2. **Wait a few minutes** - Certificates can take time to propagate

3. **Clear browser cache/data**

4. **Check Tailscale Funnel status:**
   ```bash
   tailscale funnel status
   ```

### Performance Issues

#### High CPU/Memory Usage

**Symptoms:**
- Machine becomes slow when Funnel is active

**Solutions:**

1. **Monitor resource usage:**
   ```bash
   htop  # or top
   ```

2. **Limit concurrent connections** in your app

3. **Add rate limiting** (see docs/SECURITY.md)

4. **Deploy to more powerful machine** (e.g., OCI VM instead of RPi)

### Debugging Strategies

#### Enable Verbose Logging

**Tailscale logs:**
```bash
# Linux
sudo journalctl -u tailscaled -f

# macOS
tail -f /var/log/tailscaled.log
```

**Application logs:**
```python
# Python/Flask
import logging
logging.basicConfig(level=logging.DEBUG)
```

```javascript
// Node.js
process.env.DEBUG = '*'
```

#### Test Step by Step

1. **Test app locally:**
   ```bash
   curl http://localhost:8000
   ```

2. **Test with Tailscale (private):**
   ```bash
   tailscale ip -4  # Get your Tailscale IP
   curl http://<tailscale-ip>:8000
   ```

3. **Test with Funnel (public):**
   ```bash
   curl https://<machine>.ts.net:8000
   ```

#### Check All the Pieces

```bash
# 1. Is Tailscale running?
tailscale status

# 2. Is Funnel enabled?
tailscale funnel status

# 3. Is app running?
ps aux | grep python  # or node, etc.

# 4. Is app listening?
ss -tlnp | grep 8000

# 5. Can we connect locally?
curl http://localhost:8000

# 6. Environment variables loaded?
echo $BASE_URL
```

## Getting Help

If you're still stuck:

1. **Check Tailscale community:** https://forum.tailscale.com/
2. **Read Tailscale Funnel docs:** https://tailscale.com/kb/1223/funnel/
3. **Check your app's documentation**
4. **Open an issue** with:
   - Output of `tailscale version`
   - Output of `tailscale status`
   - Output of `tailscale funnel status`
   - Error messages
   - What you've tried

## Quick Reference

### Essential Commands

```bash
# Check Tailscale status
tailscale status

# Check Funnel status
tailscale funnel status

# Enable Funnel on port 8000
tailscale funnel --bg 8000

# Disable Funnel
tailscale funnel --bg off

# View Tailscale logs
sudo journalctl -u tailscaled -f

# Check what's listening on port 8000
ss -tlnp | grep 8000

# Test local connection
curl http://localhost:8000

# Test public connection
curl https://$(tailscale status --json | jq -r '.Self.DNSName'):8000
```

### File Locations

```
tailscale-funnel-module/
├── scripts/funnel-*.sh           # Scripts
├── tailscale-config.json          # Configuration
├── .env.tailscale                 # Environment variables
└── logs/                          # Logs (if enabled)
```

### Log Locations

```bash
# Tailscale logs
# Linux: journalctl -u tailscaled
# macOS: /var/log/tailscaled.log

# Application logs (depends on your setup)
/var/log/myapp.log
~/.relayq/logs/
./logs/
```
