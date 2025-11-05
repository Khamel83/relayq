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

# Download as regular user to temp directory first
curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz

# Move to runner directory and extract
sudo mv actions-runner-osx-x64-2.311.0.tar.gz /opt/actions-runner/
cd /opt/actions-runner
sudo tar xzf ./actions-runner-osx-x64-2.311.0.tar.gz

# Clean up
sudo rm actions-runner-osx-x64-2.311.0.tar.gz
```

### 2. Configure Runner

```bash
# First, get the runner token:
# 1. Go to: https://github.com/Khamel83/relayq/settings/actions/runners
# 2. Click "New self-hosted runner"
# 3. Select macOS
# 4. Click "Generate runner token" (copy this token - it expires quickly!)

# Install and configure with your actual token
sudo ./config.sh --url https://github.com/Khamel83/relayq --token PASTE_YOUR_TOKEN_HERE

# Add labels during configuration or later in GitHub UI
# Recommended labels: macmini, audio, ffmpeg, heavy
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
# Create config directory
mkdir -p ~/.config/relayq

# Create environment file - ONLY OpenRouter for LLM, everything else local
cat > ~/.config/relayq/env << 'EOF'
# LLM Configuration (OpenRouter only - everything else is local)
OPENAI_API_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_KEYS="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,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"
DEFAULT_MODEL=google/gemini-2.5-flash-lite
MAX_CONTENT_LENGTH=500000

# ASR - Local only
ASR_BACKEND=local
WHISPER_MODEL=base
WHISPER_MODEL_PATH=/opt/models/

# Mac Mini Hardware Acceleration
ENABLE_METAL_ACCELERATION=true
MPS_DEVICE=mps
PYTORCH_ENABLE_MPS_FALLBACK=1
FFMPEG_HWACCEL=videotoolbox
FFMPEG_DEVICE=0
WHISPER_DEVICE=mps
WHISPER_COMPUTE_TYPE=float16
WHISPER_NUM_WORKERS=4

# Processing Configuration
VISION_MODEL_DEVICE=mps
COREML_ENABLED=true
IMAGE_PROCESSING_BACKEND=coreimage
AUDIO_BACKEND=coreaudio
AUDIO_SAMPLE_RATE=16000
AUDIO_CHANNELS=1
VIDEO_CODEC=h264_videotoolbox
VIDEO_PRESET=fast
VIDEO_CRF=23

# Mac-specific paths
HOMEBREW_PREFIX=/opt/homebrew
MODELS_DIR=/opt/models
CACHE_DIR=~/.cache/relayq
TEMP_DIR=/tmp/relayq

# Resource limits
MAX_CPU_PERCENT=80
MAX_MEMORY_GB=8
PROCESS_PRIORITY=low
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