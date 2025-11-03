# Runner Management Guide

## 🖥️ Mac Mini Runner Management

### Install GitHub Runner (if not already installed)

```bash
# On Mac mini, download runner binary
curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz
tar xzf actions-runner-osx-x64-2.311.0.tar.gz

# Configure runner
sudo ./config.sh --url https://github.com/Khamel83/relayq --token YOUR_TOKEN

# Install as system service
sudo ./svc.sh install
sudo ./svc.sh start
```

### Stop GitHub Runner

```bash
# Stop the runner service
sudo ./svc.sh stop

# Verify it's stopped
sudo ./svc.sh status
```

### Start GitHub Runner

```bash
# Start the runner service
sudo ./svc.sh start

# Verify it's running
sudo ./svc.sh status
```

### Remove Runner (if needed)

```bash
# Stop runner first
sudo ./svc.sh stop

# Remove configuration
sudo ./config.sh remove --token YOUR_TOKEN

# Remove service
sudo ./svc.sh uninstall
```

### Check Runner Status

```bash
# Local check
sudo ./svc.sh status

# GitHub check (from any machine with gh CLI)
gh api repos/Khamel83/relayq/actions/runners
```

### Update Runner (to newer version)

```bash
# Stop current runner
sudo ./svc.sh stop

# Download new version
curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz
tar xzf actions-runner-osx-x64-2.311.0.tar.gz --overwrite

# Reconfigure with same token
sudo ./config.sh --url https://github.com/Khamel83/relayq --token YOUR_TOKEN --replace

# Restart
sudo ./svc.sh start
```

## 🔧 Runner Configuration

### Labels for Mac Mini

Your Mac mini should have these labels:
- `self-hosted` (automatic)
- `macmini` (Mac mini identification)
- `audio` (audio processing capability)
- `ffmpeg` (FFmpeg installed)
- `heavy` (high-power tasks)

### Verify Labels

```bash
# Check runner labels in GitHub UI
# Or via GitHub CLI
gh api repos/Khamel83/relayq/actions/runners | jq '.runners[] | {name, labels}'
```

### Runner Environment

```bash
# Create configuration directory
mkdir -p ~/.config/relayq

# Create environment file
cat > ~/.config/relayq/env << 'EOF'
ASR_BACKEND=local
WHISPER_MODEL=small
AI_API_KEY=sk-your-api-key-here
EOF

# Make sure it's readable
chmod 600 ~/.config/relayq/env
```

## 🚨 Troubleshooting

### Runner Not Picking Up Jobs

```bash
# Check runner status
sudo ./svc.sh status

# Check network connectivity
ping github.com

# Check if runner is registered
gh api repos/Khamel83/relayq/actions/runners
```

### Runner Not Starting

```bash
# Check for conflicts
sudo lsof -i :8080  # Check if port is in use

# Check permissions
ls -la /opt/actions-runner/

# Check logs
sudo ./svc.sh logs
```

### Re-register Runner

```bash
# Remove current configuration
sudo ./config.sh remove --token OLD_TOKEN

# Get new token from GitHub Settings → Actions → Runners → Add runner
# Re-register
sudo ./config.sh --url https://github.com/Khamel83/relayq --token NEW_TOKEN

# Restart
sudo ./svc.sh restart
```

## 📋 Runner Health Check

```bash
#!/bin/bash
# runner_health_check.sh

echo "=== Mac Mini Runner Health Check ==="

# Check service status
if sudo ./svc.sh status | grep -q "running"; then
    echo "✅ Runner service is running"
else
    echo "❌ Runner service is not running"
    exit 1
fi

# Check network connectivity
if ping -c 1 github.com &> /dev/null; then
    echo "✅ Network connectivity to GitHub"
else
    echo "❌ No network connectivity to GitHub"
    exit 1
fi

# Check GitHub registration
if gh api repos/Khamel83/relayq/actions/runners | grep -q "online.*true"; then
    echo "✅ Runner is registered and online"
else
    echo "❌ Runner is not registered with GitHub"
    exit 1
fi

# Check required tools
if command -v ffmpeg &> /dev/null; then
    echo "✅ FFmpeg is installed"
else
    echo "❌ FFmpeg is not installed"
    echo "Install with: brew install ffmpeg"
fi

if command -v python3 &> /dev/null; then
    echo "✅ Python 3 is available"
else
    echo "❌ Python 3 is not available"
    echo "Install with: brew install python3"
fi

echo "=== Health check complete ==="
```

## 🔒 Security Considerations

### Runner Permissions

- Run runner with dedicated user account
- Limit runner's system permissions
- Regularly update runner binary
- Monitor runner logs for unusual activity

### API Keys

- Store API keys in `~/.config/relayq/env` only
- Set file permissions to `600`
- Never commit API keys to repository
- Rotate keys regularly

### Network Security

- Runner only makes outbound connections to GitHub
- No inbound ports required
- Monitor GitHub Actions logs for security events

## 📊 Performance Monitoring

### Monitor Runner Resource Usage

```bash
# Check CPU usage
top -l 1 | head -10

# Check memory usage
top -l 1 | grep "PhysMem"

# Check disk space
df -h

# Monitor runner logs
tail -f /var/log/runner.log
```

### GitHub Actions Metrics

```bash
# Recent job history
gh run list --repo Khamel83/relayq --limit 10

# Runner statistics
gh api repos/Khamel83/relayq/actions/runners | jq '.runners[] | {name: .name, status: .status, labels: .labels}'
```

## 🔄 Maintenance

### Weekly Maintenance

1. **Update runner binary**
2. **Check GitHub Actions usage**
3. **Review security logs**
4. **Update dependencies** (FFmpeg, Python packages)

### Monthly Maintenance

1. **Rotate API keys**
2. **Review runner performance**
3. **Check disk space**
4. **Backup configuration files**

### Emergency Procedures

**Runner stops responding:**
1. Stop runner: `sudo ./svc.sh stop`
2. Check system resources: `top`, `df -h`
3. Restart runner: `sudo ./svc.sh start`
4. If still failing, re-register runner

**Network issues:**
1. Check network connectivity: `ping github.com`
2. Check DNS resolution: `nslookup github.com`
3. Check firewall settings
4. Restart network if needed

**Performance issues:**
1. Check system resources
2. Review job logs for errors
3. Consider reducing concurrent jobs
4. Upgrade hardware if needed