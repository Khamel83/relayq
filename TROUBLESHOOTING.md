# Troubleshooting

When something breaks.

## Problem: Jobs Not Running

**Check if worker is online:**

SSH to Mac Mini:
```bash
ssh macmini
launchctl list | grep relayq
```

Should show:
```
12345  0  com.user.relayq.worker
```

If not there:
```bash
launchctl load ~/Library/LaunchAgents/com.user.relayq.worker.plist
```

**Check worker logs:**
```bash
tail -50 ~/.relayq/worker.log
```

Look for errors. Common issues:
- "Connection refused" → Redis not running on OCI VM
- "Permission denied" → File permissions issue
- Python errors → Missing dependencies

**Restart worker:**
```bash
launchctl unload ~/Library/LaunchAgents/com.user.relayq.worker.plist
launchctl load ~/Library/LaunchAgents/com.user.relayq.worker.plist
```

## Problem: Redis Not Running

SSH to OCI VM:
```bash
ssh oci-dev
sudo systemctl status redis
```

If not running:
```bash
sudo systemctl start redis
sudo systemctl enable redis
```

Test Redis:
```bash
redis-cli ping
```

Should return: `PONG`

## Problem: Jobs Queue But Never Start

**Check network connectivity:**

From OCI VM:
```bash
ssh macmini@100.113.216.27 "echo connected"
```

Should print: `connected`

If fails → Tailscale issue. Restart Tailscale on Mac Mini:
```bash
ssh macmini
/Applications/Tailscale.app/Contents/MacOS/Tailscale up
```

## Problem: Jobs Fail Immediately

**Check the specific error:**

```python
from relayq import job

result = job.transcode("video.mp4")
result.wait()

if result.failed():
    print(result.traceback)  # Shows exact error
```

Common errors:
- "File not found" → File not on Mac Mini
- "ffmpeg: command not found" → ffmpeg not installed
- "Permission denied" → File permissions

## Problem: Mac Mini Is Slow

**Check if worker is using too many resources:**

SSH to Mac Mini:
```bash
top -l 1 | grep python
```

If CPU > 80%, adjust priority in config:

Edit `~/.relayq/config.yml`:
```yaml
worker:
  priority: low
  max_concurrent: 1  # Reduce from 2 to 1
```

Restart worker:
```bash
launchctl unload ~/Library/LaunchAgents/com.user.relayq.worker.plist
launchctl load ~/Library/LaunchAgents/com.user.relayq.worker.plist
```

## Problem: "ModuleNotFoundError: No module named 'relayq'"

Install relayq:
```bash
pip install git+https://github.com/Khamel83/relayq.git
```

Or add to your project's `requirements.txt`.

## Problem: Setup Script Failed

**Save the error log and re-run:**

On OCI VM:
```bash
./install-broker.sh 2>&1 | tee broker-install.log
```

On Mac Mini:
```bash
./install-worker.sh 2>&1 | tee worker-install.log
```

Check the log files for specific errors.

## Problem: Jobs Stay in "PENDING" Forever

**Check if worker can connect to Redis:**

SSH to Mac Mini:
```bash
python3 -c "from celery import Celery; app = Celery(broker='redis://100.103.45.61:6379/0'); print(app.control.inspect().active())"
```

If error → Network/firewall issue between Mac Mini and OCI VM.

**Allow Redis port on OCI VM:**
```bash
ssh oci-dev
sudo ufw allow from 100.113.216.27 to any port 6379
```

## Nuclear Option: Complete Reset

**On OCI VM:**
```bash
sudo systemctl stop redis
sudo systemctl disable redis
sudo apt remove redis-server
rm -rf ~/.relayq
```

Then re-run `install-broker.sh`.

**On Mac Mini:**
```bash
launchctl unload ~/Library/LaunchAgents/com.user.relayq.worker.plist
rm ~/Library/LaunchAgents/com.user.relayq.worker.plist
rm -rf ~/.relayq
pip uninstall relayq celery redis
```

Then re-run `install-worker.sh`.

## Still Broken?

Copy the output of these commands and paste to Claude:

**On OCI VM:**
```bash
sudo systemctl status redis
redis-cli ping
tail -50 ~/.relayq/broker.log
```

**On Mac Mini:**
```bash
launchctl list | grep relayq
tail -50 ~/.relayq/worker.log
python3 -c "import celery; print(celery.__version__)"
```