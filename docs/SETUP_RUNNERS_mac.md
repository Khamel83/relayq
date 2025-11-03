# macOS Runner Setup (Mac mini)

## Prerequisites

- macOS 11+ (Big Sur or later)
- Administrative access
- GitHub account with repo access

## Installation

### 1. Download Runner Binary

```bash
# Create runner directory
sudo mkdir -p /opt/actions-runner
cd /opt/actions-runner

# Download latest runner
curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz

# Extract
tar xzf ./actions-runner-osx-x64-2.311.0.tar.gz
```

### 2. Configure Runner

```bash
# Install and configure
sudo ./config.sh --url https://github.com/Khamel83/relayq --token YOUR_TOKEN

# Use the "Generate runner token" button in GitHub Settings → Actions → Runners
```

### 3. Install as Service

```bash
# Install as service
sudo ./svc.sh install

# Start the service
sudo ./svc.sh start

# Enable auto-start on boot
sudo ./svc.sh enable
```

### 4. Add Labels

During configuration or later in GitHub UI, add these labels:
- `self-hosted` (automatic)
- `macmini`
- `audio`
- `ffmpeg`
- `heavy`

### 5. Verify Installation

```bash
# Check service status
sudo ./svc.sh status

# Check logs
sudo ./svc.sh logs

# Should see runner online in GitHub Settings → Actions → Runners
```

## Dependencies for Audio Jobs

Install required tools for audio transcription:

```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install FFmpeg
brew install ffmpeg

# Install Python for local ASR
brew install python

# Install local ASR models (optional)
pip3 install openai-whisper faster-whisper
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

# Local model path (if using local backend)
WHISPER_MODEL=base
WHISPER_MODEL_PATH=/opt/models/

# NAS mount point (optional via Tailscale)
# NAS_MOUNT=/mnt/nas
EOF
```

## Service Management

```bash
# Restart runner
sudo ./svc.sh restart

# Stop runner
sudo ./svc.sh stop

# Update runner (download new version)
sudo ./svc.sh stop
# Download new runner binary
sudo ./svc.sh start
```

## Troubleshooting

**Runner not appearing in GitHub:**
- Check `./svc.sh status`
- Verify network connectivity
- Check GitHub token validity

**Jobs not executing:**
- Verify labels match workflow requirements
- Check job logs in GitHub Actions UI
- Ensure dependencies installed (FFmpeg, Python)

**Permission issues:**
- Ensure runner service has proper permissions
- Check file system access for job directories