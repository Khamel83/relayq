# Operations Security (OPSEC)

## Secret Management

### GitHub Encrypted Secrets

**Where to use:**
- Workflow-level secrets
- API keys that need to be shared across runners
- Non-sensitive configuration values

**Setup:**
1. Go to repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add name and value
4. Use in workflows: `${{ secrets.SECRET_NAME }}`

**Examples:**
```yaml
env:
  OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
  ROUTER_API_KEY: ${{ secrets.ROUTER_API_KEY }}
```

### Node-Local Environment Files

**Where to use:**
- Runner-specific secrets
- Local API keys
- Machine-specific configuration
- Sensitive file paths

**Setup:**
```bash
# Create secure directory
mkdir -p ~/.config/relayq
chmod 700 ~/.config/relayq

# Create environment file
cat > ~/.config/relayq/env << 'EOF'
# API Keys (sensitive)
OPENAI_API_KEY=sk-your-openai-key-here
ROUTER_API_KEY=sk-or-your-router-key-here

# Local paths
WHISPER_MODEL_PATH=/opt/models/whisper
NAS_MOUNT=/mnt/nas

# Backend preferences
ASR_BACKEND=local
EOF

# Secure permissions
chmod 600 ~/.config/relayq/env
```

**Usage in scripts:**
```bash
#!/bin/bash
# Source node-local environment
if [ -f "$HOME/.config/relayq/env" ]; then
    source "$HOME/.config/relayq/env"
fi
```

## Security Best Practices

### Never Commit Secrets

**.gitignore configuration:**
```gitignore
# Environment files
.env
*.env
.env.local
.env.production

# Config files with secrets
config/secrets.yml
**/.config/relayq/env
**/secrets/

# Temporary files
*.key
*.pem
*.p12
secrets.txt
```

### Secret Validation

```bash
#!/bin/bash
# validate_secrets.sh - Check for committed secrets

# Check for common secret patterns
if git grep -q "sk-[a-zA-Z0-9]\{48\}" -- '*.py' '*.sh' '*.yml' '*.yaml'; then
    echo "ERROR: Potential OpenAI API key found in repository"
    exit 1
fi

if git grep -q "password\|secret\|key" -- '*.py' '*.sh' '*.yml' '*.yaml' | grep -v "examples\|template"; then
    echo "WARNING: Potential secrets found in repository"
    exit 1
fi
```

### Environment Isolation

**Production vs Development:**
```bash
# Development environment
if [ "$ENVIRONMENT" = "development" ]; then
    source ~/.config/relayq/dev.env
else
    source ~/.config/relayq/prod.env
fi
```

## Network Security

### No Inbound Ports

**Security principle:**
- Runners connect to GitHub (outbound only)
- No inbound connections required
- Zero attack surface from internet

**Verification:**
```bash
# Check no inbound ports listening
netstat -tuln | grep LISTEN

# Should only show local services, no external ports
```

### Tailscale Security (Optional)

**Use cases:**
- Access to private NAS/storage
- Internal service communication
- Secure file transfers

**Minimal ACLs:**
```json
{
  "ACLs": [
    {
      "Action": "accept",
      "Src": ["tag:relayq-runner"],
      "Dst": ["tag:nas-server:port=2049"]
    }
  ]
}
```

**Security checklist:**
- [ ] Tailscale authentication enabled
- [ ] Minimal ACL permissions
- [ ] Key rotation policy
- [ ] Audit logging enabled

## Runner Security

### Runner Isolation

**Job execution isolation:**
```yaml
# Workflow-level isolation
jobs:
  process:
    runs-on: [self-hosted, audio]
    container: ubuntu:22.04  # Optional container isolation
    steps:
      - name: Process in isolation
        run: |
          # Jobs run in isolated environment
          jobs/transcribe.sh "${{ inputs.url }}"
```

**File system isolation:**
```bash
# Use temp directories for job processing
TEMP_DIR=$(mktemp -d -t relayq-XXXXXX)
chmod 700 "$TEMP_DIR"

# Clean up automatically
trap "rm -rf '$TEMP_DIR'" EXIT
```

### Resource Limits

**Prevent resource abuse:**
```bash
# Limit CPU usage in scripts
timeout 4h jobs/transcribe.sh "$URL"

# Limit memory usage (Linux)
ulimit -v 4194304  # 4GB virtual memory limit

# Limit file size
ulimit -f 1048576  # 1GB file size limit
```

### Access Control

**Runner user permissions:**
```bash
# Dedicated user for runner
sudo useradd -m -s /bin/bash runner
sudo usermod -aG sudo runner  # Limited sudo access

# File permissions
sudo chown -R runner:runner /opt/actions-runner
chmod 755 /opt/actions-runner
```

## Data Protection

### Data at Rest

**Encrypt sensitive data:**
```bash
# Encrypt local model files
gpg --symmetric --cipher-algo AES256 model.bin

# Decrypt when needed
gpg --decrypt --output model.bin model.bin.gpg
```

**Secure temporary files:**
```bash
# Use encrypted temp directory
TEMP_DIR=$(mktemp -d -t relayq-XXXXXX)
chmod 700 "$TEMP_DIR"

# Secure file creation
umask 077
touch "$TEMP_DIR/sensitive_data.txt"
```

### Data in Transit

**API communication:**
```bash
# Use HTTPS for all API calls
curl -X POST "https://api.openai.com/v1/audio/transcriptions" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    --cacert /etc/ssl/certs/ca-certificates.crt
```

**File transfers:**
```bash
# Secure file copy
scp -i ~/.ssh/relayq_key user@host:/path/to/file

# Use SFTP with key authentication
sftp -i ~/.ssh/relayq_key user@host
```

## Audit and Monitoring

### Access Logging

```bash
#!/bin/bash
# audit_log.sh - Security event logging

log_security_event() {
    local event="$1"
    local details="$2"
    echo "$(date),SECURITY,$event,$details" >> /var/log/relayq/security.log
}

# Log job starts
log_security_event "JOB_START" "workflow=$1 runner=$2"

# Log secret access
log_security_event "SECRET_ACCESS" "backend=$ASR_BACKEND"
```

### Monitoring for Anomalies

```bash
#!/bin/bash
# security_monitor.sh - Monitor for suspicious activity

# Check for unusual job patterns
unusual_jobs=$(gh run list --repo Khamel83/relayq --json headBranch | \
    jq -r '.[] | select(.headBranch | startswith("tmp/")) | .headBranch' | wc -l)

if [ "$unusual_jobs" -gt 5 ]; then
    echo "WARNING: Unusual number of temporary branch jobs: $unusual_jobs"
fi

# Check for failed authentication attempts
failed_auth=$(grep "authentication failed" /var/log/relayq/security.log | wc -l)
if [ "$failed_auth" -gt 10 ]; then
    echo "WARNING: High number of failed authentication attempts: $failed_auth"
fi
```

## Incident Response

### Security Incident Checklist

**Immediate response:**
1. **Identify scope** - What systems/data affected?
2. **Contain threat** - Revoke compromised credentials
3. **Preserve evidence** - Don't delete logs
4. **Notify stakeholders** - Alert relevant parties

**Recovery steps:**
1. **Rotate secrets** - Update all API keys
2. **Update runner tokens** - Generate new tokens
3. **Review access logs** - Identify breach point
4. **Patch vulnerabilities** - Fix security gaps
5. **Monitor closely** - Watch for further issues

### Secret Rotation Procedure

```bash
#!/bin/bash
# rotate_secrets.sh - Rotate all secrets

# Rotate OpenAI API key
echo "Rotating OpenAI API key..."
# Generate new key via OpenAI dashboard
# Update GitHub secret
# Update node-local env files

# Rotate runner tokens
echo "Rotating runner tokens..."
gh api --method DELETE repos/Khamel83/relayq/actions/runners/<runner-id>/remove-token
./config.sh remove --token "$OLD_TOKEN"
./config.sh --url https://github.com/Khamel83/relayq --token "$NEW_TOKEN"

# Verify everything works
./bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://example.com/test.mp3
```

## Compliance Considerations

### Data Privacy

**Personal data handling:**
- Process data locally when possible
- Avoid sending sensitive data to cloud APIs
- Implement data retention policies
- Provide data deletion procedures

**Example data handling:**
```bash
# Auto-delete processed files
cleanup_processed_files() {
    local processed_dir="/tmp/processed"
    find "$processed_dir" -type f -mtime +7 -delete
}
```

### Security Checklist

### Daily Checks
- [ ] Review security logs for anomalies
- [ ] Verify runner status and health
- [ ] Check for failed authentication attempts
- [ ] Monitor job completion rates

### Weekly Checks
- [ ] Review and rotate secrets if needed
- [ ] Update runner software
- [ ] Audit file permissions
- [ ] Check network security

### Monthly Checks
- [ ] Security audit of repository
- [ ] Review and update policies
- [ ] Test incident response procedures
- [ ] Validate backup and recovery procedures

### Security Policies

**Required:**
- No secrets committed to repository
- All runners use outbound-only connections
- Regular secret rotation
- Security logging enabled
- Access control implemented

**Recommended:**
- Tailscale for private resource access
- Container isolation for jobs
- Regular security audits
- Incident response plan
- Security training for users