# Operations Runbook

## Running Jobs

### From OCI VM (Recommended)

```bash
# Basic transcription
./bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://example.com/audio.mp3

# With additional parameters
./bin/dispatch.sh .github/workflows/transcribe_audio.yml \
  url=https://example.com/audio.mp3 \
  backend=local \
  model=base

# Force specific runner
./bin/dispatch.sh .github/workflows/transcribe_mac.yml url=https://example.com/large.mp3
```

### From GitHub UI

1. Go to repository Actions tab
2. Select workflow (e.g., "Transcribe Audio")
3. Click "Run workflow"
4. Enter parameters
5. Click "Run workflow"

### API/Programmatic

```bash
# Using GitHub CLI
gh workflow run transcribe_audio.yml -f url=https://example.com/audio.mp3

# Using curl (requires personal access token)
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/Khamel83/relayq/actions/workflows/transcribe_audio.yml/dispatches \
  -d '{"ref":"main","inputs":{"url":"https://example.com/audio.mp3"}}'
```

## Monitoring Jobs

### Check Job Status

```bash
# List recent runs
gh run list --repo Khamel83/relayq

# Get specific run details
gh run view <run-id> --repo Khamel83/relayq

# Watch live progress
gh run watch <run-id> --repo Khamel83/relayq

# Check workflow status
gh workflow list --repo Khamel83/relayq
```

### Read Logs

```bash
# View job logs
gh run view <run-id> --repo Khamel83/relayq --log

# Follow logs in real-time
gh run watch <run-id> --repo Khamel83/relayq --log

# Download logs (for large outputs)
gh run download <run-id> --repo Khamel83/relayq
```

### Check Runner Status

```bash
# List all runners
gh api repos/Khamel83/relayq/actions/runners

# Check specific runner
gh api repos/Khamel83/relayq/actions/runners/<runner-id>

# Check runner labels
gh api repos/Khamel83/relayq/actions/runners/<runner-id> | jq '.labels'
```

## Job Management

### Cancel Jobs

```bash
# Cancel specific run
gh run cancel <run-id> --repo Khamel83/relayq

# Cancel multiple runs
gh run list --repo Khamel83/relayq --limit 10 --json databaseId | \
  jq -r '.[].databaseId' | xargs -I {} gh run cancel {} --repo Khamel83/relayq
```

### Re-run Jobs

```bash
# Re-run failed job
gh run rerun <run-id> --repo Khamel83/relayq

# Re-run all failed jobs in workflow
gh run rerun <run-id> --repo Khamel83/relayq --failed
```

### Manage Artifacts

```bash
# List artifacts
gh run list --repo Khamel83/relayq --json artifacts

# Download artifacts
gh run download <run-id> --repo Khamel83/relayq

# Delete old artifacts (cleanup)
gh api repos/Khamel83/relayq/actions/artifacts | \
  jq -r '.artifacts[] | select(.created_at < "2025-11-01") | .id' | \
  xargs -I {} gh api --method DELETE repos/Khamel83/relayq/actions/artifacts/{}
```

## Handling Issues

### Jobs Stay Queued

**Symptoms:**
- Job shows "queued" status indefinitely
- No runner picks up the job

**Troubleshooting:**

1. **Check runner availability:**
   ```bash
   gh api repos/Khamel83/relayq/actions/runners
   ```

2. **Verify labels match:**
   - Job requires: `[self-hosted, audio]`
   - Runner has: `[self-hosted, macmini, audio]` ✅
   - Runner has: `[self-hosted, rpi4, audio]` ✅
   - Runner has: `[self-hosted, linux]` ❌

3. **Check runner status:**
   - Green: Online and idle
   - Yellow: Busy
   - Gray: Offline

4. **Restart runner if needed:**
   ```bash
   # On Mac mini
   sudo ./svc.sh restart

   # On Raspberry Pi
   sudo systemctl restart actions-runner
   ```

### Jobs Fail Immediately

**Symptoms:**
- Job fails without execution
- Error in workflow setup

**Common causes:**
- Invalid input parameters
- Missing required inputs
- Workflow syntax errors

**Debug steps:**
1. Check workflow syntax in GitHub UI
2. Review job logs for specific error
3. Verify required inputs are provided

### Jobs Fail During Execution

**Symptoms:**
- Job starts but fails during processing
- Script execution errors

**Debug steps:**
1. Download job logs
2. Check runner-specific logs
3. Verify dependencies installed on runner
4. Check file permissions and paths

### Runner Connection Issues

**Symptoms:**
- Runner shows offline in GitHub UI
- Jobs not picked up by specific runner

**Troubleshooting:**

1. **Check network connectivity:**
   ```bash
   ping github.com
   curl -I https://github.com
   ```

2. **Check runner service:**
   ```bash
   # macOS
   sudo ./svc.sh status

   # Linux
   sudo systemctl status actions-runner
   ```

3. **Restart runner:**
   ```bash
   # macOS
   sudo ./svc.sh restart

   # Linux
   sudo systemctl restart actions-runner
   ```

4. **Re-register runner if needed:**
   ```bash
   ./config.sh remove --token OLD_TOKEN
   ./config.sh --url https://github.com/Khamel83/relayq --token NEW_TOKEN
   ```

## Data Management

### Where Outputs Go

**Artifacts:**
- Uploaded to GitHub automatically
- Retention: 30 days (free tier)
- Download via UI or `gh run download`

**Node-local paths:**
- Temporary files: `/tmp/` (cleaned automatically)
- Persistent outputs: `/home/runner/work/relayq/relayq/outputs/`
- NAS access (optional): `/mnt/nas/` via Tailscale

**Cleanup strategies:**
```bash
# Clean old artifacts (run weekly)
find /home/runner/work -name "*.tmp" -mtime +7 -delete

# Clean node-local outputs
find /home/runner/work/relayq/relayq/outputs -mtime +30 -delete
```

### Backup and Recovery

**Backup critical data:**
- `policy/policy.yaml`
- `bin/` scripts
- `jobs/` scripts
- Configuration files

**Recovery procedures:**
1. Repository clone provides all code
2. Runner registration can be repeated
3. Policy files control job routing
4. Scripts are version controlled

## Performance Tuning

### Monitor Resource Usage

```bash
# Check runner performance
gh api repos/Khamel83/relayq/actions/runners/<runner-id>/performance

# Monitor job duration
gh run list --repo Khamel83/relayq --json databaseId,headBranch,conclusion,createdAt,updatedAt | \
  jq '.[] | select(.conclusion == "success") | (.updatedAt - .createdAt)'
```

### Optimize Job Distribution

1. **Review policy settings** in `policy/policy.yaml`
2. **Adjust concurrency limits** for resource-intensive jobs
3. **Balance load** across available runners
4. **Monitor job queues** for bottlenecks

### Improve Job Performance

1. **Use appropriate runner** for job type
2. **Optimize script performance** in `jobs/`
3. **Cache dependencies** where possible
4. **Monitor and optimize I/O operations**

## Security

### Secret Management

**GitHub Encrypted Secrets:**
- Store in repository Settings → Secrets
- Available in workflows as environment variables
- Automatically masked in logs

**Node-local secrets:**
- Store in `~/.config/relayq/env` on each runner
- Source from job scripts
- Never commit to repository

### Security Checklist

- [ ] No secrets committed to repository
- [ ] Runner permissions limited to necessary
- [ ] Network access properly firewalled
- [ ] Temporary files cleaned automatically
- [ ] Access logs reviewed regularly
- [ ] Dependencies kept updated

## Automation

### Scheduled Jobs

```bash
# Add to crontab for daily tasks
0 2 * * * /home/ubuntu/relayq/bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://podcast.example.com/latest.mp3
```

### Health Monitoring

```bash
#!/bin/bash
# health_check.sh - Monitor runner health

# Check runner status
RUNNERS=$(gh api repos/Khamel83/relayq/actions/runners | jq '.total_count')
if [ "$RUNNERS" -eq 0 ]; then
    echo "WARNING: No runners online"
    # Send alert notification
fi

# Check recent job failures
FAILED=$(gh run list --repo Khamel83/relayq --limit 10 --json conclusion | jq '[.[] | select(.conclusion == "failure")] | length')
if [ "$FAILED" -gt 5 ]; then
    echo "WARNING: High failure rate: $FAILED/10 jobs failed"
fi
```