# Tailscale MCP Integration - AI-Driven Network Management

## Overview

The **Tailscale Model Context Protocol (MCP) server** allows AI assistants to manage your Tailscale network programmatically. This is perfect for automating RelayQ infrastructure and enabling AI-driven operations.

## What is MCP?

Model Context Protocol (MCP) is a standard for connecting AI assistants to external systems. The Tailscale MCP server exposes Tailscale operations as tools that AI can use.

## Why Use Tailscale MCP?

### For RelayQ
- **Automated deployment**: AI can deploy services across your fleet
- **Dynamic routing**: AI manages which machine runs which job
- **Health monitoring**: AI monitors and restarts services automatically
- **Resource optimization**: AI allocates jobs based on machine availability

### For Infrastructure
- **Zero manual SSH**: AI handles all remote operations
- **Fleet management**: Control OCI VM, Mac Mini, RPi from one interface
- **Service orchestration**: AI starts/stops services across machines
- **Network configuration**: AI manages Funnel/Serve settings

## Quick Start

### 1. Install Tailscale MCP Server

```bash
# Using npm
npx @tailscale/mcp-server

# Or install globally
npm install -g @tailscale/mcp-server
```

### 2. Configure for Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "tailscale": {
      "command": "npx",
      "args": ["-y", "@tailscale/mcp-server"],
      "env": {
        "TAILSCALE_API_KEY": "tskey-api-your-key-here"
      }
    }
  }
}
```

### 3. Get Tailscale API Key

```bash
# Visit Tailscale admin console
open https://login.tailscale.com/admin/settings/keys

# Create a new API key with appropriate permissions
# Copy the key and add to config above
```

### 4. Restart Claude Desktop

The MCP server will now be available to Claude!

## Available MCP Tools

### Device Management

#### `tailscale_list_devices`
List all devices in your Tailnet

```
AI: "Show me all my Tailscale devices"
→ Returns: List of machines with status, IP, etc.
```

#### `tailscale_device_routes`
Get routes for a specific device

```
AI: "What routes are advertised by my OCI VM?"
→ Returns: Routes, subnets, etc.
```

### Service Management

#### `tailscale_serve_config`
Get or set Tailscale Serve/Funnel configuration

```
AI: "Enable Funnel on port 8000 on my Mac Mini"
→ Configures Funnel on specified machine
```

```
AI: "Show Funnel configuration for OCI VM"
→ Returns: Current Funnel/Serve config
```

### DNS & Network

#### `tailscale_dns_nameservers`
Get or set custom DNS nameservers

#### `tailscale_dns_preferences`
Get DNS preferences

## Real-World RelayQ Examples

### Example 1: Deploy Dashboard to OCI VM

**User:** "Deploy the RelayQ dashboard to my OCI VM"

**AI workflow:**
```
1. Uses tailscale_list_devices to find OCI VM
2. Checks if OCI VM is online
3. Creates dashboard.py with job status endpoints
4. Uses SSH via Tailscale to copy files
5. Uses tailscale_serve_config to enable Funnel on port 8000
6. Starts the dashboard service
7. Returns public URL: https://oci-vm.ts.net:8000
```

### Example 2: Distribute Jobs Based on Machine Load

**User:** "Run transcription job on the least busy machine"

**AI workflow:**
```
1. Uses tailscale_list_devices to get all runners (Mac Mini, RPi4)
2. Checks each machine's current load
3. Selects machine with lowest CPU usage
4. Submits job to that specific machine via GitHub Actions
5. Monitors job progress
6. Returns result location
```

### Example 3: Auto-Scale Based on Queue

**User:** "If job queue > 5, start additional runners"

**AI workflow:**
```
1. Checks GitHub Actions queue length
2. If queue > 5:
   a. Uses tailscale_list_devices to find available machines
   b. SSH to idle machines via Tailscale
   c. Starts additional runner services
3. Returns: "Started 2 additional runners on RPi4 and Mac Mini"
```

### Example 4: Health Check and Auto-Recovery

**User:** "Monitor RelayQ services and restart if needed"

**AI workflow:**
```
1. Periodically checks health endpoints via Funnel URLs
2. If service down:
   a. Uses tailscale_list_devices to verify machine is online
   b. SSH via Tailscale to machine
   c. Checks logs
   d. Restarts service
   e. Verifies health check passes
3. Sends notification: "Restarted dashboard on OCI VM"
```

## Integration Patterns

### Pattern 1: AI-Driven Deployment

```
User: "I need a public API for job submission"

AI creates:
1. api.py with /submit endpoint
2. Deploys to OCI VM via Tailscale SSH
3. Uses tailscale_serve_config to enable Funnel
4. Sets up systemd service
5. Returns: "API available at https://oci-vm.ts.net:8000/submit"
```

### Pattern 2: Multi-Machine Orchestration

```
User: "Run job status dashboard on OCI, artifact server on Mac Mini"

AI:
1. Deploys dashboard.py to OCI VM (port 8000)
2. Deploys artifacts.py to Mac Mini (port 8001)
3. Configures Funnel on both machines
4. Updates workflow to post results to both services
5. Returns both URLs
```

### Pattern 3: Dynamic Resource Allocation

```
User: "Process this large audio file"

AI:
1. Checks file size (500MB)
2. Uses tailscale_list_devices to find capable machines
3. Identifies Mac Mini (most powerful)
4. Verifies Mac Mini is online and not busy
5. Submits job to Mac Mini runner
6. Monitors progress
7. Returns transcription result
```

## Configuration for RelayQ

### Store API Key Securely

```bash
# Add to .env.tailscale
cat >> .env.tailscale << EOF
TAILSCALE_API_KEY=tskey-api-your-key-here
EOF

chmod 600 .env.tailscale
```

### Enable AI-Driven Operations

**Option 1: Claude Desktop MCP** (recommended for interactive use)

Edit Claude Desktop config as shown above

**Option 2: API-based** (for automated scripts)

```python
import os
import requests

TAILSCALE_API_KEY = os.getenv('TAILSCALE_API_KEY')
TAILNET = 'your-tailnet.ts.net'

def list_devices():
    url = f'https://api.tailscale.com/api/v2/tailnet/{TAILNET}/devices'
    headers = {'Authorization': f'Bearer {TAILSCALE_API_KEY}'}
    response = requests.get(url, headers=headers)
    return response.json()

def enable_funnel(device_id, port):
    url = f'https://api.tailscale.com/api/v2/device/{device_id}/serve_config'
    headers = {'Authorization': f'Bearer {TAILSCALE_API_KEY}'}
    config = {
        "TCP": {
            str(port): {
                "HTTPS": True
            }
        }
    }
    response = requests.post(url, headers=headers, json=config)
    return response.json()
```

## Advanced Use Cases

### Automated Failover

```python
# Auto-failover script (can be driven by AI via MCP)
def ensure_service_running(service_name, primary_machine, backup_machine):
    """
    Ensure service is running, failover to backup if needed
    """
    # Check primary
    if not is_healthy(primary_machine, service_name):
        # Failover to backup
        stop_service(primary_machine, service_name)
        start_service(backup_machine, service_name)
        update_funnel(backup_machine)
        notify_admin(f"Failed over {service_name} to {backup_machine}")
```

### Load Balancing

```python
def distribute_jobs(jobs):
    """
    AI can use this pattern to distribute jobs across fleet
    """
    machines = list_available_machines()
    for job in jobs:
        # Pick least loaded machine
        target = min(machines, key=lambda m: get_load(m))
        submit_job(target, job)
```

### Smart Routing

```python
def route_job(job_type, job_size):
    """
    AI uses Tailscale MCP to query machine capabilities
    """
    if job_size > 1_000_000:  # Large file
        return "macmini"  # Most powerful
    elif job_type == "transcription":
        return "oci-vm"  # Always-on
    else:
        return "rpi4"  # Light tasks
```

## AI Assistant Prompts

### For Deployment

```
AI, deploy a Flask dashboard for RelayQ that shows:
- Current jobs (query GitHub Actions API)
- Runner status
- Recent completions

Deploy to OCI VM, enable Funnel, make it public
```

### For Monitoring

```
AI, monitor all RelayQ services every 5 minutes:
- Check health endpoints
- Restart if down
- Alert me if can't recover
```

### For Operations

```
AI, I need to process 10 audio files:
- Check which machines are available
- Distribute jobs based on machine load
- Monitor progress
- Collect results when done
```

## Security Considerations

### API Key Permissions

When creating Tailscale API key, use minimum required permissions:

- ✅ `devices:read` - List devices
- ✅ `devices:write` - Update device config
- ✅ `routes:read` - View routes
- ✅ `routes:write` - Advertise routes
- ⚠️ `all` - Only if absolutely needed

### Environment Security

```bash
# Never commit API keys
echo ".env.tailscale" >> .gitignore

# Secure permissions
chmod 600 .env.tailscale

# Rotate keys regularly
# Visit: https://login.tailscale.com/admin/settings/keys
```

### Audit Logging

```python
import logging

logging.basicConfig(
    filename='tailscale-operations.log',
    level=logging.INFO,
    format='%(asctime)s - %(message)s'
)

def log_operation(operation, machine, details):
    logging.info(f"{operation} on {machine}: {details}")
```

## Combining with Funnel Module

The MCP server works perfectly with this Funnel module:

```
User: "Make RelayQ dashboard public"

AI workflow:
1. Uses tailscale_serve_config (MCP) to check current config
2. Creates dashboard.py (from this module's templates)
3. Runs ./scripts/funnel-start.sh (from this module)
4. Verifies via MCP that Funnel is active
5. Returns public URL
```

## Troubleshooting

### MCP Server Not Working

1. **Check config location:**
   ```bash
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

2. **Verify API key:**
   ```bash
   export TAILSCALE_API_KEY=tskey-api-...
   curl -H "Authorization: Bearer $TAILSCALE_API_KEY" \
     https://api.tailscale.com/api/v2/tailnet/-/devices
   ```

3. **Restart Claude Desktop**

### API Rate Limits

Tailscale API has rate limits. If you hit them:

1. Cache device list
2. Reduce polling frequency
3. Use webhooks instead of polling

## Resources

- [Tailscale MCP Server](https://github.com/tailscale/mcp-server-tailscale)
- [Tailscale API Docs](https://tailscale.com/api)
- [MCP Specification](https://modelcontextprotocol.io/)
- [Claude Desktop](https://claude.ai/download)

## Next Steps

1. Install Tailscale MCP server
2. Configure Claude Desktop
3. Try example queries: "List my Tailscale devices"
4. Build automation for RelayQ operations
5. Create custom AI workflows

---

**With MCP, AI can manage your entire Tailscale infrastructure!** 🤖
