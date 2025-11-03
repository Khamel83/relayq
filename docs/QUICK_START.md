# Quick Start Guide

Get your GitHub-first hybrid runner system running in 15 minutes.

## 🚀 3-Step Setup

### Step 1: Install GitHub CLI (OCI VM)

```bash
sudo apt update && sudo apt install gh
gh auth login
```

### Step 2: Setup One Runner

#### Mac mini (Recommended)
```bash
# Download and install
curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz
tar xzf actions-runner-osx-x64-2.311.0.tar.gz

# Configure with GitHub token
sudo ./config.sh --url https://github.com/Khamel83/relayq --token YOUR_TOKEN

# Start as service
sudo ./svc.sh install && sudo ./svc.sh start
```

#### Raspberry Pi 4
```bash
# Download ARM version
curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-arm64-2.311.0.tar.gz
tar xzf actions-runner-linux-arm64-2.311.0.tar.gz

# Configure (as runner user)
sudo ./config.sh --url https://github.com/Khamel83/relayq --token YOUR_TOKEN

# Start as service
sudo systemctl enable actions-runner
sudo systemctl start actions-runner
```

### Step 3: Configure API Key

```bash
# Create config directory
mkdir -p ~/.config/relayq

# Create environment file
cat > ~/.config/relayq/env << 'EOF'
ASR_BACKEND=local
WHISPER_MODEL=base

# Paste your API key here (works with OpenAI, OpenRouter, etc.)
AI_API_KEY=sk-your-api-key-here
EOF
```

## 🧪 Test It

```bash
# Test with sample audio
./bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://example.com/test.mp3

# Check status
make status
```

## 📱 What You Can Do Now

### Voice Memos
```bash
# Transcribe voice memo
./bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://your-voice-memo.mp3
```

### Grocery Lists
```bash
# Quick voice-to-text
./bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://voice.example.com/grocery.mp3
```

### Home Assistant Integration
```python
# Trigger from Home Assistant
import subprocess
subprocess.run(["./bin/dispatch.sh", ".github/workflows/transcribe_audio.yml",
                "url=https://your-home-assistant/voice.mp3"])
```

## 🔧 Where Everything Is

```
relayq/
├── bin/dispatch.sh           # Job submission script
├── jobs/transcribe.sh        # Audio processing script
├── policy/policy.yaml        # Job routing rules
├── docs/                     # All documentation
├── .github/workflows/        # GitHub workflow definitions
└── legacy/                   # Old Redis system (archived)
```

## 🎯 Next Steps

1. **Set up additional runners** (RPi4 for light tasks)
2. **Try different backends** (OpenAI for better quality)
3. **Add scheduled jobs** (daily transcription)
4. **Integrate with your apps** (use the API)

## 📞 Need Help?

- **docs/**: Complete documentation
- **Makefile**: `make help` for commands
- **GitHub Issues**: Report problems
- **README.md**: Full feature list

## 🏁 You're Done!

You now have:
- ✅ Free job orchestration (GitHub)
- ✅ Unlimited local processing (your hardware)
- ✅ Professional monitoring and UI
- ✅ Zero maintenance overhead

**Cost:** ~$5/month (electricity only)
**Setup time:** 15 minutes
**Maintenance:** Minimal

Your personal job processing cloud is ready! 🚀