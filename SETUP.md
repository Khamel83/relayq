# Setup Guide

**Two single commands to get relayq working.**

## Prerequisites

- SSH access to both machines (you already have this via Tailscale)
- Mac Mini and OCI VM on same Tailscale network

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

## Step 3: Test It

On OCI VM, test the connection:
```bash
python3 -c "from relayq import job; print(job.run('echo \"SUCCESS! relayq is working\"').get())"
```

**Expected output:**
```
SUCCESS! relayq is working
```

## Troubleshooting

If setup fails, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Done

You're all set. See [USAGE.md](USAGE.md) for how to use relayq in your projects.