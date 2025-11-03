# Cluster Scaling Guide

## Current Architecture (Working)

```
OCI VM (Broker)     →  Mac Mini (Worker: Heavy Tasks)
                    →  RPi4 (Worker: Light Tasks)
```

**What works:** 1 broker + 2 workers, single-command installation each.

---

## 🚀 Scaling Options

### Option 1: RPi3 as Third Worker

**Expanded Architecture:**
```
OCI VM (Broker)     →  Mac Mini (Heavy: video transcoding)
                    →  RPi4 (Light: monitoring, background tasks)
                    →  RPi3 (Light-Medium: backup processing, additional monitoring)
```

**Benefits:**
- More concurrent job capacity
- Redundancy if one worker goes down
- Distributed monitoring across multiple devices
- Lower-power background processing

**Installation:**
```bash
# On RPi3 (one-time setup)
curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-worker-rpi.sh | bash
```

**Usage:** No code changes needed. Jobs auto-distribute across 3 workers.

---

### Option 2: RPi3 as Backup Broker + Pi-hole

**High-Availability Architecture:**
```
Primary Broker:    OCI VM (100.103.45.61)
Backup Broker:     RPi3 (always-on, UPS power)
Workers:           Mac Mini + RPi4
```

**Benefits:**
- **Network resilience:** If OCI VM goes down, RPi3 takes over
- **UPS power:** Keeps running during power outages
- **Pi-hole integration:** Network-level ad blocking + relayq backup
- **Lower power consumption** than running OCI VM 24/7
- **Local processing:** Jobs can continue without internet

---

## 🛠️ Implementation: RPi3 as Backup Broker + Pi-hole

### Step 1: Prepare RPi3
```bash
# Install Pi-hole (one time)
curl -sSL https://install.pi-hole.net | bash

# Configure as network DNS server
# Update router DHCP to use RPi3 as DNS
```

### Step 2: Install Backup Broker
```bash
# Install relayq broker on RPi3
curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-broker.sh | bash

# Configure external Redis access
sudo sed -i 's/^bind 127.0.0.1.*/bind 127.0.0.1 -::1/' /etc/redis/redis.conf
sudo systemctl restart redis
```

### Step 3: Update Worker Configuration
On Mac Mini and RPi4, update `~/.relayq/config.yml`:
```yaml
broker:
  host: 100.103.45.61  # Primary: OCI VM
  # Fallback to RPi3 would require broker_failover support (future feature)
  port: 6379
  db: 0
```

### Step 4: Failover Procedure (Manual)
If OCI VM goes down:
```bash
# On RPi3 - start taking jobs
redis-cli ping  # Verify Redis running

# From any client - update broker config to point to RPi3 IP
# Then continue using: from relayq import job
```

---

## 📊 Comparison: RPi3 Use Cases

| Use Case | Setup Complexity | Benefits | Best For |
|----------|------------------|----------|----------|
| **Third Worker** | Low (1 command) | More processing power, redundancy | Need more job capacity |
| **Backup Broker** | Medium (Pi-hole + relayq) | High availability, local processing | Network resilience, power outages |
| **Pi-hole Only** | Low | Network ad blocking | Basic network improvement |

---

## 🔮 Future Enhancement: Automatic Failover

**Current State:** Manual broker switching
**Future Goal:** Workers automatically detect broker failure and connect to backup

**Implementation would need:**
- Multiple broker URLs in worker config
- Health checking between brokers
- Automatic broker switching logic

---

## 📝 Quick Reference

### Add RPi3 as Worker:
```bash
curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-worker-rpi.sh | bash
```

### Add RPi3 as Backup Broker + Pi-hole:
```bash
# Pi-hole setup
curl -sSL https://install.pi-hole.net | bash

# Relayq broker setup
curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-broker.sh | bash
```

### Verify New Node:
```bash
# From OCI VM or any client
python3 -c "from relayq import worker_status; print(worker_status())"
```

---

**Note:** All scaling options are optional. Current 2-node system (OCI VM + Mac Mini) works perfectly for basic needs. RPi3 additions are for enhanced reliability and capacity.