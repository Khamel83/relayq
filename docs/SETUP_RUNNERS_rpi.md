# Raspberry Pi Runner Setup

## Prerequisites

- Raspberry Pi 3B+ or newer (Pi 4 recommended)
- Raspberry Pi OS (64-bit recommended)
- GitHub account with repo access

## Installation

### 1. Download Runner Binary

```bash
# Create runner directory
sudo mkdir -p /opt/actions-runner
cd /opt/actions-runner

# Determine architecture
ARCH=$(uname -m)
case $ARCH in
  aarch64) RUNNER_ARCH=arm64 ;;
  armv7l) RUNNER_ARCH=arm ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Download latest runner
curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-${RUNNER_ARCH}-2.311.0.tar.gz

# Extract
tar xzf ./actions-runner-linux-${RUNNER_ARCH}-2.311.0.tar.gz
```

### 2. Create Runner User

```bash
# Create dedicated user for runner
sudo useradd -m -s /bin/bash runner
sudo usermod -aG sudo runner
```

### 3. Configure Runner

```bash
# Set ownership
sudo chown -R runner:runner /opt/actions-runner

# Switch to runner user
sudo -u runner bash

# Configure runner
cd /opt/actions-runner
./config.sh --url https://github.com/Khamel83/relayq --token YOUR_TOKEN

# Exit back to root
exit
```

### 4. Create Systemd Service

```bash
sudo tee /etc/systemd/system/actions-runner.service > /dev/null << 'EOF'
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
User=runner
WorkingDirectory=/opt/actions-runner
ExecStart=/opt/actions-runner/run.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable actions-runner
sudo systemctl start actions-runner
```

### 5. Add Labels

During configuration or later in GitHub UI, add these labels:

**For RPi4:**
- `self-hosted` (automatic)
- `rpi4`
- `audio`
- `light`

**For RPi3:**
- `self-hosted` (automatic)
- `rpi3`
- `overflow`
- `verylight`

### 6. Verify Installation

```bash
# Check service status
sudo systemctl status actions-runner

# Check logs
sudo journalctl -u actions-runner -f

# Should see runner online in GitHub Settings → Actions → Runners
```

## Dependencies for Audio Jobs

```bash
# Update system
sudo apt update

# Install FFmpeg (lightweight build)
sudo apt install ffmpeg

# Install Python for local ASR
sudo apt install python3 python3-pip

# Install Python packages
pip3 install --user openai-whisper

# For better performance on Pi 4, install faster-whisper
pip3 install --user faster-whisper
```

## Environment Configuration

Create node-local environment file:

```bash
mkdir -p ~/.config/relayq
cat > ~/.config/relayq/env << 'EOF'
# ASR backend selection: local, openai, router
ASR_BACKEND=local

# OpenAI API key (if using openai backend)
# OPENAI_API_KEY=your_key_here

# Local model path (use smaller models on Pi)
WHISPER_MODEL=tiny
WHISPER_MODEL_PATH=/home/pi/.cache/whisper/

# NAS mount point (optional via Tailscale)
# NAS_MOUNT=/mnt/nas
EOF
```

## Performance Optimization

### For Pi 4

```bash
# Enable 64-bit kernel if not already
# Edit /boot/config.txt and add:
# arm_64bit=1

# Overclock for better performance (optional)
# Edit /boot/config.txt and add:
# arm_freq=2000
# over_voltage=6
```

### For Pi 3

```bash
# Use smallest models due to memory constraints
WHISPER_MODEL=tiny

# Consider cloud backend for better performance
ASR_BACKEND=openai
```

## Service Management

```bash
# Restart runner
sudo systemctl restart actions-runner

# Stop runner
sudo systemctl stop actions-runner

# Update runner
sudo systemctl stop actions-runner
# Download new version
sudo systemctl start actions-runner

# Check runner status
sudo systemctl is-active actions-runner
```

## Troubleshooting

**Runner not starting:**
- Check `sudo systemctl status actions-runner`
- Verify architecture compatibility
- Check disk space on `/opt/actions-runner`

**Out of memory errors:**
- Use smaller Whisper models (`tiny`, `base`)
- Increase swap space: `sudo dphys-swapfile swapoff && sudo dphys-swapfile setup && sudo dphys-swapfile swapon`

**Performance issues:**
- Monitor CPU temperature: `vcgencmd measure_temp`
- Use `openai` backend for better performance
- Consider upgrading to Pi 4 for better performance

**Network issues:**
- Check internet connectivity: `ping github.com`
- Verify DNS resolution
- Check firewall rules