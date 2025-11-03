# GitHub Actions + RelayQ: Free Job Orchestration Platform

## 🎯 The Killer Combination

**GitHub Actions:** Free job orchestration (2,000 minutes/month)
**RelayQ:** Free local processing (unlimited)

**Result:** Enterprise-level job scheduling with zero costs.

---

## 🔍 Research Findings: Why This Isn't Common

### Existing Solutions (What Others Do)

**1. Self-Hosted GitHub Runners**
- **What they are:** GitHub runs jobs directly on your machines
- **Problems:**
  - Complex setup (port forwarding, firewall config)
  - Security concerns (GitHub directly accesses your network)
  - Maintenance overhead (runner updates, monitoring)
  - Always-on requirement (machine must be ready 24/7)

**2. SSH Actions (like appleboy/ssh-action)**
- **What they do:** SSH from GitHub runner to your machines
- **Problems:**
  - One-off commands only (no job queuing)
  - No persistence if connection fails
  - Manual error handling and retries
  - Complex SSH key management

**3. Cloud-only Solutions**
- **What they are:** AWS Batch, Google Cloud Run, etc.
- **Problems:**
  - Always costs money
  - No access to local files/network
  - Cold start delays

### Why RelayQ + GitHub Actions is Unique

**The Gap Nobody Filled:**
- ✅ **Free orchestration** (GitHub Actions)
- ✅ **Free local processing** (RelayQ)
- ✅ **No direct network exposure** (RelayQ initiates connection)
- ✅ **Job queuing and persistence** (Redis)
- ✅ **Zero maintenance** once set up

**You get enterprise job scheduling** without enterprise complexity or costs.

---

## 📊 Cost Analysis

### GitHub Actions Free Tier
- **2,000 minutes/month** = 33 hours of processing
- **Cost after:** $0.008/minute Linux, $0.08/minute macOS

### RelayQ + Your Hardware
- **Unlimited minutes** = Free forever
- **Hardware cost:** Already owned hardware

### Break-Even Analysis
**Video transcoding (1 hour task):**
- GitHub Actions: 60 minutes + 60 minutes runner = 120 minutes
- RelayQ: 0 GitHub minutes (just triggers) + 1 hour local processing
- **Savings:** 120 GitHub minutes per hour of video

**Monthly usage of just 10 hours video processing:**
- GitHub Actions: 1,200 minutes (60% of free tier)
- RelayQ: ~10 minutes (just orchestration triggers)

---

## 🏗️ Architecture Specification

### Data Flow
```
You/GitHub/Webhook → GitHub Action (2 min) → OCI VM → RelayQ → Mac Mini/RPi4 → Results Back
```

### Components
1. **GitHub Actions:** Job orchestration and triggers
2. **OCI VM (RelayQ Broker):** Job queuing and distribution
3. **Local Workers:** Actual processing (Mac Mini, RPi4, etc.)

### Security Model
- ✅ **No inbound ports** needed (workers connect to Redis)
- ✅ **No direct GitHub access** to your network
- ✅ **Secrets managed** by GitHub (broker URL, auth)
- ✅ **Network isolation** (only outbound Redis connection)

---

## 🚀 Implementation Guide

### Step 1: Prepare GitHub Repository
```yaml
# .github/workflows/relayq.yml
name: RelayQ Job Processing

on:
  workflow_dispatch:  # Manual trigger from GitHub UI
    inputs:
      command:
        description: 'Command to run on your cluster'
        required: true
        default: 'echo "Hello from RelayQ"'
      worker:
        description: 'Target worker (optional)'
        required: false
        default: 'auto'

  schedule:  # Daily/weekly tasks
    - cron: '0 2 * * *'  # 2 AM daily

  push:  # File-based triggers
    paths:
      - 'videos/*.mp4'
      - 'data/*.csv'

jobs:
  relayq-job:
    runs-on: ubuntu-latest
    timeout-minutes: 5  # Only for orchestration

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install RelayQ
        run: |
          pip3 install --user git+https://github.com/Khamel83/relayq.git

      - name: Execute Job on Cluster
        env:
          RELAYQ_BROKER_URL: ${{ secrets.RELAYQ_BROKER_URL }}
        run: |
          python3 -c "
import os
from relayq import job

broker_url = os.environ.get('RELAYQ_BROKER_URL', 'redis://127.0.0.1:6379/0')
command = '''${{ github.event.inputs.command }}'''
worker = '''${{ github.event.inputs.worker }}'''

print(f'Executing: {command}')
if worker != 'auto':
    result = job.run_on_mac(command) if worker == 'mac' else job.run_on_rpi(command)
else:
    result = job.run(command)

output = result.get(timeout=300)  # 5 minute orchestration timeout
print(f'Job completed: {output}')
"
```

### Step 2: Configure GitHub Secrets
```bash
# In GitHub repo → Settings → Secrets
RELAYQ_BROKER_URL=redis://100.103.45.61:6379/0  # Your OCI VM IP
```

### Step 3: Setup Workflow Triggers

#### Manual Trigger (GitHub UI)
1. Go to Actions tab in your repo
2. Select "RelayQ Job Processing"
3. Click "Run workflow"
4. Enter command and target worker
5. Jobs execute on your Mac Mini/RPi4

#### Scheduled Jobs
```yaml
# Daily backup at 2 AM
- cron: '0 2 * * *'
# Input: command="/home/ubuntu/backup.sh"
```

#### File-based Triggers
```yaml
# Process videos when uploaded
on:
  push:
    paths: ['videos/*.mp4']
# Automatically transcode new videos
```

---

## 💡 Advanced Use Cases

### 1. Video Processing Pipeline
```yaml
# When video uploaded to repo
on:
  push:
    paths: ['videos/raw/*.mp4']

jobs:
  transcode:
    runs-on: ubuntu-latest
    steps:
      - name: Transcode on Mac Mini
        run: |
          python3 -c "
from relayq import job
import glob

# Find new videos
videos = glob.glob('videos/raw/*.mp4')
for video in videos:
    output = video.replace('/raw/', '/processed/')
    job.transcode(video, output, options='-c:v libx264 -crf 23')
"
```

### 2. Data Processing Automation
```yaml
# Daily data processing
on:
  schedule:
    - cron: '0 3 * * *'  # 3 AM daily

jobs:
  process-data:
    runs-on: ubuntu-latest
    steps:
      - name: Download and Process Data
        run: |
          python3 -c "
from relayq import job
import requests

# Download latest data
data = requests.get('https://api.example.com/data').json
job.run(f'echo \"{data}\" > /tmp/latest_data.json')
job.run('python3 /home/ubuntu/process_data.py')
"
```

### 3. System Monitoring and Alerts
```yaml
# Health checks every hour
on:
  schedule:
    - cron: '0 * * * *'  # Every hour

jobs:
  health-check:
    runs-on: ubuntu-latest
    steps:
      - name: Monitor Cluster Health
        run: |
          python3 -c "
from relayq import worker_status
import requests

status = worker_status()
if status['total_workers'] == 0:
    # Send alert (webhook, email, etc.)
    requests.post('https://hooks.slack.com/YOUR_WEBHOOK', json={
        'text': '⚠️ RelayQ cluster: No workers online!'
    })
"
```

---

## 🔧 Troubleshooting

### Common Issues

**Job doesn't start:**
```bash
# Check Redis connectivity from GitHub Action
python3 -c "
from relayq.config import get_broker_url
print(f'Broker URL: {get_broker_url()}')
"
```

**Worker offline:**
```bash
# Check from your OCI VM
python3 -c "from relayq import worker_status; print(worker_status())"
```

**GitHub Action timeouts:**
- Increase `timeout-minutes` in workflow
- Check if job is actually running on worker
- Verify Redis connection

### Monitoring

**Track job usage:**
```python
# Add to your jobs for monitoring
from relayq import worker_status
status = worker_status()
print(f"Total jobs processed: {status['workers']['celery@macmini.local']['total_jobs']}")
```

---

## 🎯 When to Use This Pattern

### Perfect For:
- ✅ **Scheduled tasks** (backups, processing, monitoring)
- ✅ **Manual job submission** (GitHub UI interface)
- ✅ **Event-driven processing** (file uploads, webhooks)
- ✅ **Cost optimization** (use free tier for orchestration, local for processing)
- ✅ **Web-based job control** (trigger from anywhere)

### Use Direct RelayQ Instead:
- 🚫 **Quick one-off commands** (faster to run directly)
- 🚫 **High-frequency small jobs** (GitHub Actions overhead)
- 🚫 **Real-time processing** (GitHub Actions delays)
- 🚫 **When you're already at terminal** (just use RelayQ directly)

---

## 📈 Scaling Considerations

### Adding More Workers
```bash
# New device → Install worker
curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-worker.sh | bash
```

### Increasing GitHub Actions Limits
- **Free tier:** 2,000 minutes/month
- **Pro ($4/month):** 3,000 minutes/month
- **Team:** 50,000 minutes/month

### Backup Broker Option
- Add RPi3 as backup broker (see CLUSTER-SCALING.md)
- Update `RELAYQ_BROKER_URL` in GitHub secrets during failover

---

## 🚀 Quick Start Checklist

1. ✅ **RelayQ cluster working** (OCI VM + Mac Mini)
2. ✅ **GitHub repository created**
3. ✅ **Workflow file added** (copy from examples)
4. ✅ **Secrets configured** (`RELAYQ_BROKER_URL`)
5. ✅ **Test manual job** via GitHub Actions UI
6. ✅ **Set up schedules** for recurring tasks

**You now have enterprise-level job orchestration for free.**