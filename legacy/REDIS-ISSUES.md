# Redis Connection Issues - Detailed Analysis

## 🚨 PROBLEM SUMMARY

Redis starts successfully but dies immediately when relayq attempts to use it for job execution. This is the critical blocker preventing the 3-node cluster from functioning.

## 📋 ISSUE TIMELINE

### Initial Discovery (Nov 1, 23:20 PDT)
- Redis starts: `redis-server --daemonize yes` ✅
- Redis responds: `redis-cli ping` → PONG ✅
- Job submission fails: `python3 -c "from relayq import job; print(job.run('echo SUCCESS').get())"` ❌
- Error: `ConnectionError: Error 111 connecting to 127.0.0.1:6379. Connection refused`

### Investigation Process
1. **First attempt**: Basic Redis start → died during job execution
2. **Second attempt**: Explicit binding `--bind 127.0.0.1` → still died
3. **Third attempt**: Verbose logging revealed SIGTERM signal

## 🔍 ROOT CAUSE ANALYSIS

### Multiple Redis Managers Conflict

#### Systemd Redis Service
```bash
sudo systemctl status redis-server
# Status: failed (Result: exit-code) since Sat 2025-11-01 22:33:34 PDT
# Duration: 11.184s
# Status: "Redis is loading..."
```
- Ubuntu's built-in Redis service was conflicting
- **Fix applied**: `sudo systemctl stop redis-server && sudo systemctl disable redis-server`

#### Custom Health Monitor (OUR OWN CODE)
```bash
sudo systemctl list-timers | grep redis
# relayq-redis-monitor.timer     relayq-redis-monitor.service
```
- Our installation script created a health monitor that kills Redis
- **Fix applied**: `sudo systemctl stop relayq-redis-monitor.timer && sudo systemctl disable relayq-redis-monitor.timer`

### Redis Death Pattern Analysis

From `/tmp/redis.log` during job submission:
```
3613222:M 01 Nov 2025 23:21:26.721 # User requested shutdown...
3613222:M 01 Nov 2025 23:21:26.721 * Saving the final RDB snapshot before exiting...
3613222:M 01 Nov 2025 23:21:26.724 * DB saved on disk
3613222:M 01 Nov 2025 23:21:26.724 # Redis is now ready to exit, bye bye...
```

**Key insight**: Redis receives SIGTERM and shuts down gracefully, suggesting a process is intentionally killing it.

## 🧪 TESTING EVIDENCE

### Successful Redis Start
```bash
$ redis-server --daemonize yes --loglevel verbose --logfile /tmp/redis.log
$ redis-cli ping
PONG
$ ps aux | grep redis
ubuntu   3613222  0.0  0.0  23648  3952 ?        Ssl  23:21   0:00 redis-server *:6379
```

### Mac Mini Connection Evidence
```
3613222:M 01 Nov 2025 23:21:26.534 * Accepted 100.113.216.27:63669
```
- Mac Mini worker successfully connected to Redis
- Confirms network connectivity is working

### Job Submission Triggering Death
```bash
$ python3 -c "from relayq import job; print('Test:', job.run('echo SUCCESS').get())"
# Redis dies immediately with SIGTERM
```

## 🔧 SOLUTIONS ATTEMPTED

### 1. Systemd Conflict Resolution ✅
```bash
sudo systemctl stop redis-server
sudo systemctl disable redis-server
```
**Result**: Redis still dies during job execution

### 2. Health Monitor Removal ✅
```bash
sudo systemctl stop relayq-redis-monitor.timer
sudo systemctl disable relayq-redis-monitor.timer
```
**Result**: Redis still dies during job execution

### 3. Alternative Port Attempt ❌
```bash
redis-server --port 6380 --daemonize yes
```
**Result**: Not yet tested (pending)

## 🎯 CURRENT WORKING THEORY

After disabling both known Redis killers (systemd + our monitor), Redis still dies. Possible remaining causes:

1. **Unknown process killing Redis** - Something else is sending SIGTERM
2. **Celery/relayq internal logic** - Something in our job submission code triggers Redis shutdown
3. **Resource constraints** - Redis runs out of memory/disk during job processing
4. **Configuration conflict** - Redis config has built-in self-protection that triggers

## 📊 DEBUGGING COMMANDS FOR FUTURE

### Monitor Redis Death in Real-time
```bash
# Terminal 1: Watch Redis process
watch -n 0.5 'ps aux | grep redis'

# Terminal 2: Monitor system signals
sudo auditd -k redis,kill

# Terminal 3: Redis logs
tail -f /tmp/redis.log

# Terminal 4: Test job
python3 -c "from relayq import job; print(job.run('echo SUCCESS').get())"
```

### Check All Redis-related Services
```bash
# Find anything that might manage Redis
sudo systemctl list-units | grep -i redis
sudo systemctl list-timers | grep -i redis
ps aux | grep -i redis | grep -v grep
```

### Test with Different Redis Configuration
```bash
# Minimal config
redis-server --port 6380 --daemonize yes --logfile /tmp/redis-alt.log --save ""

# Update relayq to use new port (need to modify config)
```

## 💡 LESSONS LEARNED

1. **Complex monitoring creates single points of failure** - Our "auto-restart" system became the killer
2. **System service conflicts are hard to debug** - Multiple Redis managers fighting each other
3. **Over-engineering kills reliability** - Simple Redis works until we added "helpful" automation
4. **Test incrementally** - Should have tested basic Redis → relayq before building cluster

## 🎯 NEXT STEPS (When Returning to This)

1. **Identify the unknown Redis killer** with auditd monitoring
2. **Try alternative Redis port** to bypass any port-specific conflicts
3. **Test minimal Redis configuration** to eliminate config issues
4. **Consider alternative message brokers** (RabbitMQ, PostgreSQL) if Redis cannot be stabilized
5. **Simplify installation scripts** to remove complex monitoring that causes more problems than it solves

---
*Issue discovered: November 1, 2025*
*Root causes partially identified, unknown killer process remains*