# Reliability Patterns

## Runner as a Service

### Auto-restart Configuration

**macOS (launchd):**
```bash
# Runner automatically restarts on system boot
sudo ./svc.sh enable

# Manual restart if needed
sudo ./svc.sh restart
```

**Linux (systemd):**
```bash
# Enable auto-start on boot
sudo systemctl enable actions-runner

# Configure restart policy
sudo systemctl daemon-reload
sudo systemctl restart actions-runner
```

### Health Monitoring

```bash
# Check runner status
gh api repos/Khamel83/relayq/actions/runners

# Monitor runner heartbeat
watch -n 30 'gh api repos/Khamel83/relayq/actions/runners | jq ".runners[] | {name: .name, status: .status}"'
```

### Automatic Recovery

```bash
#!/bin/bash
# runner_health_check.sh - Ensure runners stay healthy

check_runner() {
    local runner_name=$1
    local runner_status=$(gh api repos/Khamel83/relayq/actions/runners | \
        jq -r ".runners[] | select(.name == \"$runner_name\") | .status")

    if [ "$runner_status" != "online" ]; then
        echo "Runner $runner_name is offline, attempting restart"
        # Trigger restart based on runner type
        case $runner_name in
            *mac*) sudo ./svc.sh restart ;;
            *pi*) sudo systemctl restart actions-runner ;;
        esac
    fi
}

check_runner "mac-mini-runner"
check_runner "rpi4-runner"
```

## Pooled Labels for Failover

### Label Strategy

**Primary + Fallback:**
- `macmini, audio, heavy` - Primary for heavy tasks
- `rpi4, audio, light` - Fallback for audio tasks
- `rpi3, overflow, verylight` - Last resort

### Workflow Configuration

```yaml
# Pooled workflow - any runner with matching label can pick up
runs-on: [self-hosted, audio]

# Concurrency prevents resource conflicts
concurrency: audio-processing
```

### Failover Behavior

1. **Job submitted** with label `audio`
2. **Both runners** have `audio` label
3. **First available** runner picks up job
4. **If one fails**, other continues processing
5. **Load distribution** happens automatically

## Concurrency Guards

### Resource-Specific Limits

```yaml
# Prevent multiple transcriptions on same runner (resource intensive)
concurrency:
  group: macmini-transcribe
  cancel-in-progress: false

# Allow multiple light tasks simultaneously
concurrency:
  group: rpi4-light
  cancel-in-progress: false
```

### Global Concurrency Management

```yaml
# Resource pool management
concurrency:
  group: audio-processing
  cancel-in-progress: false  # Don't cancel running jobs
```

### Concurrency Group Strategy

| Group | Purpose | Max Concurrent | Runners |
|-------|---------|----------------|---------|
| `audio-processing` | Audio tasks | 2 | Mac mini, RPi4 |
| `macmini-transcribe` | Heavy tasks | 1 | Mac mini only |
| `rpi4-summarize` | Text tasks | 3 | RPi4 only |
| `overflow` | Background tasks | 1 | RPi3 only |

## Timeout Management

### Job Timeout Configuration

```yaml
jobs:
  transcribe:
    runs-on: [self-hosted, audio]
    timeout-minutes: 240  # 4 hours for large files

  summarize:
    runs-on: [self-hosted, light]
    timeout-minutes: 30   # 30 minutes for text processing
```

### Timeout Strategy

- **Short tasks**: 15-30 minutes
- **Medium tasks**: 1-2 hours
- **Heavy tasks**: 4-6 hours
- **Batch processing**: 8-12 hours

### Timeout Handling

```yaml
# Graceful timeout handling
- name: Process with timeout
  run: |
    timeout 4h jobs/transcribe.sh "${{ inputs.url }}" || {
      echo "Job timed out after 4 hours"
      exit 1
    }
```

## Idempotent Scripts

### Safe Execution Patterns

```bash
#!/bin/bash
# jobs/transcribe.sh - Idempotent transcription script

set -euo pipefail

# Idempotent directory creation
TEMP_DIR=$(mktemp -d -t transcribe-XXXXXX)
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Check if already processed
OUTPUT_FILE="/tmp/$(basename "${1%.*}").txt"
if [ -f "$OUTPUT_FILE" ]; then
    echo "Already processed: $OUTPUT_FILE"
    echo "$OUTPUT_FILE"
    exit 0
fi

# Idempotent download
cd "$TEMP_DIR"
if [ ! -f "$(basename "$1")" ]; then
    curl -L -o "$(basename "$1")" "$1"
fi

# Process with error handling
if ! ./process_audio.sh "$(basename "$1")" "$OUTPUT_FILE"; then
    echo "Processing failed"
    exit 1
fi

# Atomic move to final location
mv "$OUTPUT_FILE" "/tmp/$(basename "${1%.*}").txt"
echo "/tmp/$(basename "${1%.*}").txt"
```

### Idempotency Checklist

- [ ] Temporary directories use unique names
- [ ] Cleanup on exit (trap)
- [ ] Check for existing output before processing
- [ ] Atomic file operations
- [ ] Clear error handling
- [ ] No partial state corruption

## Safe Temp Paths

### Secure Temporary File Handling

```bash
# Use system temp directory
TEMP_BASE="/tmp"
TEMP_DIR=$(mktemp -d "$TEMP_BASE/relayq-XXXXXX")

# Set appropriate permissions
chmod 700 "$TEMP_DIR"

# Ensure unique filenames
OUTPUT_FILE="$TEMP_DIR/output-$(date +%s)-$$.txt"
```

### Storage Management

```bash
# Cleanup old temp files
find /tmp -name "relayq-*" -type d -mtime +1 -exec rm -rf {} \;

# Monitor disk usage
df -h /tmp
du -sh /tmp/relayq-*
```

## Clear Exit Codes

### Standard Exit Codes

```bash
#!/bin/bash
# Standard exit code conventions

exit_success() {
    echo "$1"
    exit 0
}

exit_error() {
    echo "ERROR: $1" >&2
    exit 1
}

exit_temporary() {
    echo "TEMPORARY FAILURE: $1" >&2
    exit 2
}

exit_usage() {
    echo "USAGE: $1" >&2
    exit 3
}
```

### Error Handling Pattern

```bash
# Main execution with clear error handling
main() {
    local url="$1"

    # Validate input
    if [[ -z "$url" ]]; then
        exit_usage "jobs/transcribe.sh <url>"
    fi

    # Process with error handling
    if ! process_url "$url"; then
        exit_error "Failed to process $url"
    fi

    exit_success "$output_path"
}
```

## Monitoring Patterns

### Job Status Monitoring

```bash
#!/bin/bash
# monitor_jobs.sh - Monitor job health

# Check for stuck jobs
stuck_jobs=$(gh run list --repo Khamel83/relayq --status in_progress --created "$(date -d '6 hours ago' --iso-8601)" | wc -l)

if [ "$stuck_jobs" -gt 0 ]; then
    echo "WARNING: $stuck_jobs jobs running for >6 hours"
    # Send notification
fi

# Check failure rate
total_jobs=$(gh run list --repo Khamel83/relayq --limit 100 | wc -l)
failed_jobs=$(gh run list --repo Khamel83/relayq --limit 100 --json conclusion | jq '[.[] | select(.conclusion == "failure")] | length')

failure_rate=$((failed_jobs * 100 / total_jobs))
if [ "$failure_rate" -gt 20 ]; then
    echo "WARNING: High failure rate: $failure_rate%"
fi
```

### Performance Monitoring

```bash
# Monitor job performance
gh run list --repo Khamel83/relayq --json databaseId,headBranch,conclusion,createdAt,updatedAt | \
jq '.[] | select(.conclusion == "success") |
    {run: .databaseId, duration: (.updatedAt - .createdAt)}' | \
awk '$2 > 7200 {print "Long running job: " $1 " (" $2 " seconds)"}'
```

## Disaster Recovery

### Runner Recovery Procedures

```bash
#!/bin/bash
# recover_runner.sh - Complete runner recovery

# 1. Remove existing runner
./config.sh remove --token "$OLD_TOKEN"

# 2. Clean up old files
rm -rf /opt/actions-runner/_diag

# 3. Download fresh runner
curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# 4. Reconfigure
./config.sh --url https://github.com/Khamel83/relayq --token "$NEW_TOKEN"

# 5. Restart service
sudo systemctl restart actions-runner
```

### Configuration Backup

```bash
# Backup runner configuration
sudo tar -czf runner-backup-$(date +%Y%m%d).tar.gz \
    /opt/actions-runner/.runner \
    /opt/actions-runner/svc.sh \
    /etc/systemd/system/actions-runner.service
```

## Testing Reliability

### Load Testing

```bash
#!/bin/bash
# load_test.sh - Test system under load

# Submit multiple jobs concurrently
for i in {1..10}; do
    ./bin/dispatch.sh .github/workflows/transcribe_audio.yml \
        url="https://example.com/test$i.mp3" &
done

wait

# Monitor completion
gh run list --repo Khamel83/relayq --limit 10
```

### Failure Testing

```bash
#!/bin/bash
# failure_test.sh - Test failure scenarios

# Test runner offline scenario
sudo systemctl stop actions-runner
./bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://example.com/test.mp3
# Job should queue

# Restart and verify job picks up
sudo systemctl start actions-runner
sleep 30
# Job should start automatically
```

## Reliability Checklist

### Runner Setup
- [ ] Runner installed as auto-start service
- [ ] Health monitoring configured
- [ ] Backup procedures documented
- [ ] Recovery procedures tested

### Job Configuration
- [ ] Appropriate timeouts set
- [ ] Concurrency limits configured
- [ ] Idempotent scripts implemented
- [ ] Clear error handling

### Monitoring
- [ ] Job status monitoring
- [ ] Performance tracking
- [ ] Alert notifications
- [ ] Log retention policies

### Testing
- [ ] Load testing performed
- [ ] Failure scenarios tested
- [ ] Recovery procedures validated
- [ ] Documentation verified