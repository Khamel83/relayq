# RPi4 Terminal Fix Guide

## 🚨 Problem: RPi4 Stuck in Zellij Loop

RPi4 terminal shows infinite `[default] 0:ssh*` pattern and becomes completely unresponsive. This is caused by Zellij terminal multiplexer configuration from the legacy installation.

## 🔧 **SOLUTION: Remove Zellij from Boot Process**

### Option 1: Emergency Fix (Fastest)

```bash
# SSH into RPi4 (might take multiple attempts due to loop)
ssh pi@rpi4-ip

# Kill all zellij processes
pkill -f zellij

# Clear screen and break out of loop
clear

# If still in loop, try Ctrl+\ (Ctrl+backslash)
```

### Option 2: Complete Clean (Recommended)

```bash
# SSH into RPi4
ssh pi@rpi4-ip

# Kill all zellij processes
pkill -f zellij

# Remove zellij completely
sudo apt remove zellij -y

# Clean shell configuration files
nano ~/.bashrc     # Remove any zellij lines
nano ~/.zshrc      # Remove any zellij lines
nano ~/.profile     # Remove any zellij lines

# Remove zellij config directory
rm -rf ~/.config/zellij 2>/dev/null || true

# Exit and re-login
exit
```

### Option 3: Targeted Fix (If you want to keep Zellij)

```bash
# SSH into RPi4
ssh pi@rpi4-ip

# Edit shell configuration
nano ~/.bashrc

# Look for lines like these and REMOVE them:
if command -v zellij &> /dev/null; then
    exec zellij attach -c "$@"
fi

# Or lines that start zellij automatically
zellij attach -c "$@"

# Save and exit (Ctrl+X, Y, Enter)

# Kill running zellij processes
pkill -f zellij

# Clear screen and continue
clear
```

## 🔍 **Check for Zellij References**

### Search All Configuration Files

```bash
# Search for zellij in shell configs
grep -r "zellij" ~/.bashrc ~/.zshrc ~/.profile 2>/dev/null || echo "No zellij references found"

# Check for zellij in startup scripts
grep -r "zellij" /etc/profile.d/ 2>/dev/null || echo "No system-wide zellij references"

# Check running processes
ps aux | grep zellij || echo "No zellij processes running"
```

### Clean System-wide References

```bash
# Check system-wide startup files
sudo find /etc -name "*.sh" -exec grep -l "zellij" {} \; 2>/dev/null

# Remove any system-wide zellij references found
sudo nano /etc/profile.d/zellij.sh  # Edit or delete if exists
```

## ✅ **Verification Steps**

### Test Terminal Access

```bash
# SSH back into RPi4
ssh pi@rpi4-ip

# Should see normal shell prompt like:
pi@rpi4:~$

# Try basic commands
pwd
ls -la
echo "Terminal is working"
```

### Verify No Zellij Running

```bash
# Check for zellij processes
ps aux | grep zellij

# Should return nothing or just the grep process itself
```

### Test GitHub Actions Runner (when ready)

```bash
# From OCI VM, test connection
./bin/dispatch.sh .github/workflows/transcribe_rpi.yml url=https://example.com/test.mp3

# Should pick up job and process normally
```

## 📋 **Step-by-Step Fix Checklist**

### Step 1: Emergency Access
- [ ] SSH into RPi4 (may take multiple attempts)
- [ ] Kill zellij processes: `pkill -f zellij`
- [ ] Break out of loop: `clear` or Ctrl+\

### Step 2: Complete Clean
- [ ] Remove zellij: `sudo apt remove zellij -y`
- [ ] Edit `~/.bashrc` and remove zellij lines
- [ ] Edit `~/.zshrc` if it exists
- [ ] Remove config directory: `rm -rf ~/.config/zellij`
- [ ] Exit SSH session: `exit`

### Step 3: Verification
- [ ] SSH back into RPi4
- [ ] Confirm normal shell prompt
- [ ] Test basic commands
- [ ] Verify no zellij processes
- [ ] Clean any remaining references

### Step 4: GitHub Actions Setup
- [ ] Install GitHub Actions runner
- [ ] Configure runner labels (rpi4, audio, light)
- [ ] Test job submission from OCI VM
- [ ] Verify job execution works

## 🛠️ **Alternative: Use SSH Keys Without Zellij**

If you want to avoid terminal multiplexers entirely:

```bash
# On RPi4, ensure SSH key access is working
ssh-keygen -t rsa -b 4096 -C "pi@rpi4"  # Generate SSH key
ssh-copy-id pi@rpi4-ip

# Now you can SSH directly without any multiplexer
ssh pi@rpi4-ip
```

## 🎯 **Prevent Future Issues**

### Clean Installation

When installing GitHub Actions runner on RPi4:

```bash
# After installation, verify no terminal multiplexers are installed
dpkg -l | grep -E "(zellij|tmux|screen)" || echo "No terminal multiplexers installed"

# If any are found, remove them
sudo apt remove zellij tmux screen -y
```

### Minimal Runner Installation

```bash
# Install only what's needed
sudo apt update
sudo apt install -y curl git python3 python3-pip

# Install GitHub runner without extras
curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-arm64-2.311.0.tar.gz
tar xzf actions-runner-linux-arm64-2.311.0.tar.gz

# Configure without automatic shell modification
sudo ./config.sh --url https://github.com/Khamel83/relayq --token YOUR_TOKEN
```

### Monitor Startup Scripts

```bash
# Check what runs at login
cat ~/.bashrc | grep -v "^#" | grep -v "^$"

# Check systemd services
systemctl --user list-units --type=service | grep -E "(zellij|tmux)"

# Remove any auto-start services found
systemctl --user disable zellij 2>/dev/null || echo "No user zellij service"
```

## 🔧 **SSH Configuration Issues**

If you're still having trouble with SSH access:

```bash
# Test basic connectivity
ping rpi4-ip

# Check SSH service on RPi4
ssh pi@rpi4-ip "systemctl status ssh"

# Try different SSH client options
ssh -o ConnectTimeout=10 pi@rpi4-ip

# Force protocol version if needed
ssh -1 pi@rpi4-ip
```

## 📞 **Alternative Access Methods**

If SSH is still problematic:

### Serial Connection
```bash
# Use serial adapter and screen
sudo apt install screen
sudo screen /dev/ttyUSB0 115200
```

### HDMI Display + Keyboard
- Connect RPi4 to monitor
- Connect USB keyboard
- Should get normal terminal without SSH

### Network Boot Configuration
- Edit `/boot/config.txt` on SD card
- Add: `enable_uart=1`
- Set `console=serial0,115200`

## 📋 **Final Verification**

After following these steps, your RPi4 should:

1. ✅ Accept SSH connections normally
2. ✅ Show clean terminal prompt
3. ✅ Run commands without interruption
4. ✅ Work with GitHub Actions runner
5. ✅ Process transcription jobs correctly

The infinite `[default] 0:ssh*` loop should be completely eliminated.