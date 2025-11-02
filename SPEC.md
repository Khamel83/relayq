# SPEC: 3-Node relayq System (OCI VM + Mac Mini + RPi4)

## Goal
Transform current 2-node system into robust 3-node compute orchestration:
- **OCI VM**: Broker + job submission
- **Mac Mini**: High-power worker (video, transcoding, heavy tasks)
- **RPi4**: Light worker (monitoring, scripts, background tasks)

## Current State
✅ **Working**: OCI VM ↔ Mac Mini
- Single curl command installation
- Job execution tested and functional
- Documentation updated with reality

## Target Architecture

```
OCI VM (100.103.45.61)
├── Redis broker
├── Job submission interface
└── Worker monitoring dashboard

Mac Mini (100.113.216.27)           RPi4 (100.xxx.xxx.xxx)
├── High-power worker                ├── Light worker
├── Video transcoding                ├── Scripts & monitoring
├── Heavy processing                 ├── PiHole log analysis
└── Max 2 concurrent jobs            └── Max 4 concurrent jobs
```

## Implementation Plan

### Phase 0: Fix Redis Reliability (15 minutes)
**CRITICAL: Redis keeps stopping on OCI VM**
1. **Add Redis auto-restart**
   - Systemd service that actually works
   - Health check script
   - Auto-restart on failure

2. **Update installation scripts**
   - Reliable Redis startup
   - Health monitoring
   - Auto-recovery procedures

### Phase 1: RPi4 Integration (30 minutes)
1. **Create RPi4 worker installer**
   - Detect ARM architecture
   - Install lightweight worker config
   - Auto-discover Tailscale IP
   - Start background worker

2. **Update broker to handle multiple workers**
   - Worker registration
   - Health monitoring
   - Load balancing

3. **Test 3-node job distribution**
   - Verify jobs distribute across workers
   - Test worker-specific routing

### Phase 2: Worker Specialization (15 minutes)
1. **Mac Mini: Heavy tasks**
   - Video transcoding
   - Audio processing
   - CPU-intensive work

2. **RPi4: Light tasks**
   - Text processing
   - Monitoring scripts
   - API calls
   - Background jobs

### Phase 3: Enhanced Monitoring (15 minutes)
1. **Worker status dashboard**
   - Health checks
   - Current jobs
   - Worker capabilities

2. **Updated documentation**
   - 3-node setup guide
   - Worker-specific examples
   - Troubleshooting for multi-worker

## Deliverables

### 1. Single-Command Setup
```bash
# RPi4 (one command):
curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-worker-rpi.sh | bash

# Mac Mini (already done, verify only):
pgrep -f "celery.*relayq" && echo "✓ Ready" || echo "Restart needed"
```

### 2. Enhanced API
```python
from relayq import job

# Auto-distributed (any available worker)
job.run("echo hello")

# Worker-specific
job.run_on_mac("ffmpeg -i video.mp4 output.mp4")
job.run_on_rpi("python monitor.py")

# Worker info
job.worker_status()  # Shows all workers
```

### 3. Comprehensive Documentation
- Updated README with 3-node architecture
- SETUP.md with RPi4 instructions
- New MONITORING.md for worker management
- Updated examples for multi-worker scenarios

## Technical Changes

### New Files
- `install-worker-rpi.sh` - RPi4 worker installer
- `relayq/monitoring.py` - Worker health/status
- `MONITORING.md` - Worker management guide

### Updated Files
- `README.md` - 3-node architecture
- `SETUP.md` - Add RPi4 setup step
- `USAGE.md` - Multi-worker examples
- `relayq/client.py` - Worker-specific routing
- `relayq/tasks.py` - Worker identification

## Testing Plan
1. **Current system verification**
   - OCI VM → Mac Mini jobs work
   - Worker health check

2. **RPi4 integration test**
   - Install on RPi4
   - Basic job execution OCI VM → RPi4
   - Multi-worker job distribution

3. **Complete system test**
   - All 3 nodes active
   - Jobs distribute properly
   - Worker-specific routing
   - Failure scenarios (worker down)

## Success Criteria
✅ **Single command installs RPi4 worker**
✅ **Jobs distribute across Mac Mini + RPi4**
✅ **Worker-specific job routing available**
✅ **All workers show in status dashboard**
✅ **Documentation covers 3-node setup**
✅ **System survives worker failures gracefully**

## Risk Mitigation
- Keep Mac Mini setup unchanged (already working)
- RPi4 worker is additive (won't break existing)
- Maintain backward compatibility
- Clear rollback procedures if issues

## Time Estimate: 75 minutes total
- 15 min: Fix Redis reliability (CRITICAL FIRST)
- 30 min: RPi4 integration + testing
- 15 min: Worker specialization
- 15 min: Documentation + monitoring

## Final State
**User experience:**
1. `curl` command on RPi4 → worker joins cluster
2. Mac Mini verification (already working)
3. OCI VM can submit jobs to any/specific worker
4. Clear monitoring and troubleshooting
5. Comprehensive documentation for all scenarios