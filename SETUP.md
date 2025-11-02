# Setup Guide

Run these commands **once** to install relayq.

## Prerequisites

- SSH access to both machines (you already have this via Tailscale)
- Mac Mini and OCI VM on same Tailscale network

## Step 1: Install on OCI VM (Broker)

SSH into your OCI VM:
```bash
ssh oci-dev
```

Download and run the broker installer:
```bash
curl -o install-broker.sh https://raw.githubusercontent.com/Khamel83/relayq/main/install-broker.sh
chmod +x install-broker.sh
./install-broker.sh
```

**What this does:**
- Installs Redis
- Configures Redis to start on boot
- Installs relayq Python package
- Creates config file

**Expected output:**
```
✓ Redis installed
✓ Redis running on 127.0.0.1:6379
✓ relayq installed
✓ Setup complete
```

## Step 2: Install on Mac Mini (Worker)

SSH into your Mac Mini:
```bash
ssh macmini
```

Download and run the worker installer:
```bash
curl -o install-worker.sh https://raw.githubusercontent.com/Khamel83/relayq/main/install-worker.sh
chmod +x install-worker.sh
./install-worker.sh
```

**What this does:**
- Installs relayq Python package
- Creates worker service (low priority)
- Configures worker to start on boot
- Sets up logging

**Expected output:**
```
✓ relayq installed
✓ Worker service created
✓ Worker running (low priority)
✓ Setup complete
```

## Step 3: Test It

On OCI VM, run the test script:
```bash
curl -o test-relayq.sh https://raw.githubusercontent.com/Khamel83/relayq/main/test-relayq.sh
chmod +x test-relayq.sh
./test-relayq.sh
```

**Expected output:**
```
✓ Redis responding
✓ Worker connected
✓ Test job submitted
✓ Test job completed
✓ relayq is working!
```

## Troubleshooting

If setup fails, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Done

You're all set. See [USAGE.md](USAGE.md) for how to use relayq in your projects.