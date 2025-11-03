# Final Setup Checklist

## 🎯 **Complete Setup Guide**

This checklist walks you through setting up the complete GitHub-first hybrid runner system from scratch.

---

## 📋 **Phase 1: Preparation**

### Prerequisites
- [ ] Have GitHub account with `Khamel83/relayq` repository access
- [ ] Have Mac mini available for runner
- [ ] Have RPi4 available for secondary runner (optional)
- [ ] Have OCI VM (current machine) for job submission
- [ ] Have audio file for testing (any MP3 file)

### System Requirements
- [ ] Mac mini with macOS 11+ (Big Sur or later)
- [ ] RPi4 with Raspberry Pi OS (64-bit recommended)
- [ ] Internet connectivity for all machines
- [ ] Admin access on Mac mini and RPi4

---

## 📋 **Phase 2: Repository Setup**

### Clone Repository
```bash
# On OCI VM
git clone https://github.com/Khamel83/relayq.git
cd relayq
git checkout hybrid-runner-migration
```

### Verify Files
- [ ] `bin/dispatch.sh` exists and is executable
- [ ] `jobs/transcribe.sh` exists and is executable
- [ ] `policy/policy.yaml` exists
- [ ] `docs/` directory has documentation
- [ ] `.github/workflows/` has 3 workflow files

### Verify Current Status
```bash
# Run system checks
make check

# Should show all green checks
```

---

## 📋 **Phase 3: OCI VM Setup (Current Machine)**

### GitHub CLI
- [ ] Install GitHub CLI: `sudo apt install gh`
- [ ] Authenticate: `gh auth login`
- [ ] Verify: `gh auth status`

### Verify System Status
```bash
# Test dispatch script
./bin/dispatch.sh --help

# Should show help message without errors
```

---

## 📋 **Phase 4: Mac Mini Runner Setup**

### Install GitHub Runner
```bash
# On Mac mini (copy these commands)
curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz
tar xzf actions-runner-osx-x64-2.311.0.tar.gz

# Get GitHub token:
# Go to GitHub → Khamel83/relayq → Settings → Actions → Runners → "Add new runner"
# Copy the token that starts with "AQUA..."

# Configure runner
sudo ./config.sh --url https://github.com/Khamel83/relayq --token YOUR_TOKEN

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start

# Verify it's running
sudo ./svc.sh status
```

### Install Dependencies
```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install FFmpeg
brew install ffmpeg

# Install Python
brew install python3
```

### Configure Environment
```bash
# Create configuration directory
mkdir -p ~/.config/relayq

# Create environment file
cat > ~/.config/relayq/env << 'EOF'
ASR_BACKEND=local
WHISPER_MODEL=small

# Add your API key here
AI_API_KEY=sk-your-api-key-here
EOF

# Set permissions
chmod 600 ~/.config/relayq/env
```

### Verify Runner Registration
- [ ] Go to GitHub → Khamel83/relayq → Settings → Actions → Runners
- [ ] Verify Mac mini runner appears as "online"
- [ ] Check runner has labels: `self-hosted, macmini, audio, ffmpeg, heavy`

---

## 📋 **Phase 5: RPi4 Runner Setup (Optional)**

### Fix Terminal Issues (if needed)
- [ ] Follow `docs/RPI4_TERMINAL_FIX.md` if terminal shows infinite loop
- [ ] Remove Zellij completely or fix configuration
- [ ] Verify SSH access works normally

### Install GitHub Runner
```bash
# On RPi4 (copy these commands)
sudo useradd -m runner
sudo usermod -aG sudo runner

# Download ARM version
curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-arm64-2.311.0.tar.gz
tar xzf actions-runner-linux-arm64-2.311.0.tar.gz

# Configure as runner user
sudo -u runner bash -c 'cd /opt/actions-runner && ./config.sh --url https://github.com/Khamel83/relayq --token YOUR_TOKEN'

# Create systemd service
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

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable actions-runner
sudo systemctl start actions-runner
```

### Install Dependencies
```bash
# Update system
sudo apt update

# Install FFmpeg
sudo apt install ffmpeg

# Install Python
sudo apt install python3 python3-pip
```

### Configure Environment
```bash
# As runner user
sudo -u runner bash -c '
mkdir -p ~/.config/relayq
cat > ~/.config/relayq/env << "EOF"
ASR_BACKEND=local
WHISPER_MODEL=base
AI_API_KEY=sk-your-api-key-here
EOF
chmod 600 ~/.config/relayq/env
'
```

### Verify Runner Registration
- [ ] Check runner status: `sudo systemctl status actions-runner`
- [ ] Verify in GitHub Actions → Runners (should show as online)
- [ ] Check runner labels: `self-hosted, rpi4, audio, light`

---

## 📋 **Phase 6: Configuration**

### API Keys
- [ ] Get OpenAI API key from: https://platform.openai.com/api-keys
- [ ] Or get OpenRouter key from: https://openrouter.ai/keys
- [ ] Add key to both Mac mini and RPi4 `~/.config/relayq/env` files

### Test Configuration
```bash
# On each runner, test environment
source ~/.config/relayq/env
echo "AI_API_KEY: $AI_API_KEY"
echo "ASR_BACKEND: $ASR_BACKEND"
```

### Verify GitHub Integration
```bash
# From OCI VM, test GitHub connection
gh api repos/Khamel83/relayq/actions/runners

# Should show all runners online
```

---

## 📋 **Phase 7: Testing**

### Test Mac Mini Runner
```bash
# From OCI VM, submit Mac mini specific job
./bin/dispatch.sh .github/workflows/transcribe_mac.yml \
  url=https://example.com/test.mp3 \
  backend=local
```

**Expected Result:**
- Job should appear in GitHub Actions
- Mac mini should pick up job within 30 seconds
- Transcript should be uploaded as artifact
- Runner status shows "online" throughout

### Test RPi4 Runner (if set up)
```bash
# From OCI VM, submit RPi4 specific job
./bin/dispatch.sh .github/workflows/transcribe_rpi.yml \
  url=https://example.com/test.mp3 \
  backend=local
```

**Expected Result:**
- Job should be picked up by RPi4 runner
- Transcript should complete successfully
- Should use smaller model (base) due to RPi4 constraints

### Test API Integration
```bash
# Test with OpenAI backend
./bin/dispatch.sh .github/workflows/transcribe_audio.yml \
  url=https://example.com/test.mp3 \
  backend=openai
```

**Expected Result:**
- Job should route to OpenAI API
- Transcript should be higher quality
- Should cost ~$0.01-0.05 depending on audio length

### Test Policy Engine
```bash
# Test target selection
./bin/select_target.py transcribe '{"size_mb": 50}'

# Should return: .github/workflows/transcribe_audio.yml (pooled)
# Or: .github/workflows/transcribe_mac.yml (if Mac mini preferred)
```

---

## 📋 **Phase 8: Final Verification**

### System Health Check
```bash
# Check all runners
gh api repos/Khamel83/relayq/actions/runners | jq '.runners | {name: .name, status: .status}'

# Should show all runners as "online"
```

### Workflow Testing
```bash
# Test pooled execution
./bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://example.com/test.mp3

# Should work regardless of which runner picks it up
```

### End-to-End Validation
- [ ] Submit job from OCI VM ✅
- [ ] GitHub queues job ✅
- [ ] Runner picks up job ✅
- [] Audio file downloads to runner ✅
- [] Transcription processes ✅
- [] Transcript uploads to GitHub ✅
- [ ] Results accessible ✅

---

## 📋 **Phase 9: Operations**

### Monitoring
- [ ] Check runner status regularly: `make status`
- [ ] Monitor GitHub Actions usage: `gh run list --repo Khamel83/relayq`
- [ ] Review job success rates in GitHub UI
- [ ] Check system resources on runners

### Maintenance
- [ ] Update runners when new versions released
- [ ] Rotate API keys quarterly
- [ ] Clean up old artifacts in GitHub
- [ ] Backup configuration files

### Troubleshooting
- [ ] If runner offline: Check runner service status
- [ ] If job fails: Check workflow logs in GitHub
- [ ] If no jobs picked up: Verify labels and connectivity
- [ ] If API errors: Check API key configuration

---

## ✅ **Completion Criteria**

### System is Ready When:
- [ ] OCI VM can submit jobs via dispatch script
- [ ] At least one runner (Mac mini) is online and working
- [ ] Jobs execute successfully and return results
- [ ] All documentation is clear and accessible
- [ ] No legacy components running (Redis stopped)
- [ ] System is fully documented and maintainable

### Success Indicators:
- ✅ Voice memo can be transcribed from any device
- ✅ Grocery lists can be processed automatically
- ✅ System works without manual intervention
- ✅ Cost is minimal (~$5/month electricity)
- ✅ Security is maintained (no inbound ports)

## 🚀 **You're Ready to Go!**

Once all checklist items are complete, you have:
- A fully functional personal job orchestration system
- Free GitHub-based queue management
- Local processing on your own hardware
- Enterprise-level reliability at minimal cost

**Total setup time:** 30-45 minutes
**Total monthly cost:** $0-5 (electricity only)
**Maintenance required:** Minimal