# Setup Guide

**Three single commands to get your compute cluster working.**

## Prerequisites

- SSH access to all machines (you already have this via Tailscale)
- OCI VM, Mac Mini, and RPi4 on same Tailscale network

## Step 1: Install on OCI VM (Broker)

SSH into your OCI VM and run:
```bash
curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-broker.sh | bash
```

**What this does:**
- Installs and configures Redis
- Installs relayq Python package
- Creates config files
- Sets up firewall rules

**Expected output:**
```
=== Installing relayq Broker on OCI VM ===
→ Updating package list...
→ Installing Redis...
→ Configuring Redis...
→ Starting Redis...
✓ Redis installed and running
→ Installing Python packages...
→ Installing relayq...
✓ Configuration created at ~/.relayq/config.yml
→ Configuring firewall...
=== Installation Complete ===
```

## Step 2: Install on Mac Mini (Worker)

SSH into your Mac Mini and run:
```bash
curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-worker.sh | bash
```

**What this does:**
- Installs relayq Python package
- Creates background worker (low priority)
- Sets up logging

**Expected output:**
```
=== Installing relayq Worker on Mac Mini ===
→ Installing Python packages...
→ Installing relayq...
✓ Configuration created at ~/.relayq/config.yml
→ Starting worker...
✓ Worker running in background
=== Installation Complete ===
```

## Step 3: Install on RPi4 (Light Worker)

SSH into your RPi4 and run:
```bash
curl -fsSL https://raw.githubusercontent.com/Khamel83/relayq/master/install-worker-rpi.sh | bash
```

**What this does:**
- Installs relayq Python package
- Creates RPi4-optimized worker (4 concurrent jobs, low priority)
- Auto-detects Tailscale IP
- Sets up logging

**Expected output:**
```
=== Installing relayq Worker on Raspberry Pi 4 ===
→ Installing Python packages...
→ Installing relayq...
✓ Configuration created at ~/.relayq/config.yml
→ Starting RPi4 worker...
✓ RPi4 worker running in background
=== Installation Complete ===
```

## Step 4: Test the Cluster

On OCI VM, test all workers:
```bash
# Test auto-distribution
python3 -c "from relayq import job, worker_status; print('Cluster:', job.run('echo SUCCESS').get()); print('Status:', worker_status())"

# Test Mac Mini specifically
python3 -c "from relayq import job; print('Mac Mini:', job.run_on_mac('echo \"Hello from Mac\"').get())"

# Test RPi4 specifically
python3 -c "from relayq import job; print('RPi4:', job.run_on_rpi('echo \"Hello from RPi\"').get())"
```

**Expected output:**
```
Cluster: SUCCESS
Status: {'online': True, 'total_workers': 2, 'workers': {...}}
Mac Mini: Hello from Mac
RPi4: Hello from RPi
```

## Troubleshooting

If setup fails, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Done

You're all set. See [USAGE.md](USAGE.md) for how to use relayq in your projects.