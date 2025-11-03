# OCI VM Trigger Setup

## Prerequisites

- OCI VM instance (always-free tier sufficient)
- GitHub account with repo access
- GitHub CLI installed

## Installation

### 1. Install GitHub CLI

```bash
# Update package list
sudo apt update

# Install GitHub CLI
sudo apt install gh

# Authenticate with GitHub
gh auth login

# Follow prompts:
# - Choose "GitHub.com"
# - Choose "HTTPS" protocol
# - Authenticate with browser (recommended) or token
# - Verify authentication
gh auth status
```

### 2. Verify Repository Access

```bash
# Clone repository (if not already done)
git clone https://github.com/Khamel83/relayq.git
cd relayq

# Verify workflow access
gh workflow list
```

### 3. Test Dispatch Script

```bash
# Make dispatch script executable
chmod +x bin/dispatch.sh

# Test with sample workflow
./bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://example.com/test.mp3
```

## Usage Examples

### Basic Audio Transcription

```bash
# Pooled execution (Mac or RPi4)
./bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://example.com/episode.mp3

# Force Mac mini execution
./bin/dispatch.sh .github/workflows/transcribe_mac.yml url=https://example.com/episode.mp3

# Force RPi4 execution
./bin/dispatch.sh .github/workflows/transcribe_rpi.yml url=https://example.com/episode.mp3
```

### Additional Parameters

```bash
# Pass additional parameters
./bin/dispatch.sh .github/workflows/transcribe_audio.yml \
  url=https://example.com/episode.mp3 \
  backend=local \
  model=base
```

## Scheduled Triggers

### Cron Examples

```bash
# Edit crontab
crontab -e

# Daily transcription at 2 AM
0 2 * * * /home/ubuntu/relayq/bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://podcast.example.com/latest.mp3

# Weekly batch processing every Sunday at 3 AM
0 3 * * 0 /home/ubuntu/relayq/bin/dispatch.sh .github/workflows/transcribe_mac.yml url=https://archive.example.com/weekly-batch.zip
```

### Systemd Timer Example

```bash
# Create timer service
sudo tee /etc/systemd/system/relayq-daily.service > /dev/null << 'EOF'
[Unit]
Description=Daily RelayQ Job
After=network.target

[Service]
Type=oneshot
User=ubuntu
WorkingDirectory=/home/ubuntu/relayq
ExecStart=/home/ubuntu/relayq/bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://example.com/daily.mp3
EOF

# Create timer
sudo tee /etc/systemd/system/relayq-daily.timer > /dev/null << 'EOF'
[Unit]
Description=Run RelayQ job daily at 2 AM
Requires=relayq-daily.service

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start timer
sudo systemctl daemon-reload
sudo systemctl enable relayq-daily.timer
sudo systemctl start relayq-daily.timer
```

## API Integration

### Repository Dispatch (Webhook)

```bash
# Create webhook trigger script
cat > bin/webhook_trigger.py << 'EOF'
#!/usr/bin/env python3
import json
import sys
import subprocess

def trigger_repository_dispatch(event_type, payload):
    cmd = [
        'gh', 'api',
        'repos/Khamel83/relayq/dispatches',
        '--method', 'POST',
        '--field', f'event_type={event_type}',
        '--field', f'client_payload={json.dumps(payload)}'
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        sys.exit(1)

    print("Repository dispatch triggered successfully")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: webhook_trigger.py <event_type> [payload_json]")
        sys.exit(1)

    event_type = sys.argv[1]
    payload = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}

    trigger_repository_dispatch(event_type, payload)
EOF

chmod +x bin/webhook_trigger.py

# Example usage
./bin/webhook_trigger.py audio_ready '{"url": "https://example.com/new_episode.mp3"}'
```

### External Application Integration

```python
# Python example for external apps
import subprocess
import json

def submit_transcription_job(audio_url, backend="local", target_workflow="transcribe_audio.yml"):
    """Submit a transcription job from external application"""

    cmd = [
        '/home/ubuntu/relayq/bin/dispatch.sh',
        f'.github/workflows/{target_workflow}',
        f'url={audio_url}',
        f'backend={backend}'
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise Exception(f"Job submission failed: {result.stderr}")

    # Extract run URL from output
    output_lines = result.stdout.strip().split('\n')
    run_url = output_lines[-1] if output_lines else None

    return {
        'success': True,
        'run_url': run_url,
        'output': result.stdout
    }

# Usage example
result = submit_transcription_job(
    "https://example.com/podcast.mp3",
    backend="local"
)
print(f"Job submitted: {result['run_url']}")
```

## Monitoring and Troubleshooting

### Check Job Status

```bash
# List recent workflow runs
gh run list --repo Khamel83/relayq

# Get specific run details
gh run view <run-id> --repo Khamel83/relayq

# Watch job progress in real-time
gh run watch <run-id> --repo Khamel83/relayq
```

### Debug Failed Jobs

```bash
# Get logs for failed run
gh run view <run-id> --repo Khamel83/relayq --log

# Check runner status
gh api repos/Khamel83/relayq/actions/runners

# Check workflow files
gh workflow view .github/workflows/transcribe_audio.yml --repo Khamel83/relayq
```

### Common Issues

**Authentication failures:**
```bash
# Re-authenticate
gh auth login
gh auth status
```

**Missing permissions:**
```bash
# Verify repo access
gh repo view Khamel83/relayq

# Check workflow permissions
gh api repos/Khamel83/relayq/actions/permissions/workflows
```

**Rate limiting:**
- GitHub API has rate limits
- Use GitHub token with appropriate permissions
- Consider using GitHub App for higher limits