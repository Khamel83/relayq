# Tailscale Funnel Module - Local-First Public Web Apps

**Stop paying for hosting. Stop configuring DNS. Stop wrestling with SSL certificates.**

This reusable module lets you run ANY web application locally and share it publicly with automatic HTTPS - no domain required.

## 🎯 The Problem

Traditional web hosting requires:
- ❌ Domain registration ($10-50/year per domain)
- ❌ DNS configuration (complex, error-prone)
- ❌ SSL certificate management (Let's Encrypt, renewals, etc.)
- ❌ Server hosting ($5-100+/month)
- ❌ Deployment pipelines (CI/CD, FTP, etc.)
- ❌ Port forwarding / firewall rules

## ✅ The Solution: Tailscale Funnel

Run locally, share globally:
- ✅ **Free** (Tailscale free tier is generous)
- ✅ **Automatic HTTPS** (TLS certificates handled for you)
- ✅ **No DNS** (uses `your-machine.your-tailnet.ts.net`)
- ✅ **Local control** (restart, update, debug instantly)
- ✅ **Zero deployment** (just run locally)
- ✅ **Privacy** (disable anytime with one command)

## 🏗️ Architecture

```
Your Local Machine                          Public Internet
┌─────────────────────┐                    ┌──────────────┐
│  Your App           │                    │   Users      │
│  localhost:8000     │                    │              │
│         ↓           │                    │              │
│  Tailscale Funnel   │ ◄──────HTTPS─────►│  Browser     │
│  (port 8000)        │                    │              │
└─────────────────────┘                    └──────────────┘

Public URL: https://my-laptop.my-tailnet.ts.net
```

**Key Benefits:**
1. App runs locally - full control, instant updates
2. Tailscale Funnel creates secure HTTPS tunnel
3. Anyone can access via public URL
4. No infrastructure to manage

## 🚀 Quick Start (30 seconds)

1. **Setup:**
   ```bash
   cd tailscale-funnel-module
   ./scripts/funnel-setup.sh
   ```

2. **Configure:**
   ```bash
   nano tailscale-config.json  # Set your port number
   ```

3. **Start:**
   ```bash
   ./scripts/funnel-start.sh
   ```

That's it! Your app is now publicly accessible with HTTPS! 🎉

## 📂 Module Structure

```
tailscale-funnel-module/
├── README.md                    # This file
├── INTEGRATION_GUIDE.md         # How to add to your project
│
├── scripts/
│   ├── funnel-setup.sh          # Initial setup
│   ├── funnel-start.sh          # Start Funnel
│   ├── funnel-stop.sh           # Stop Funnel
│   └── funnel-status.sh         # Status & URL
│
├── templates/
│   ├── .env.tailscale           # Environment template
│   └── tailscale-config.json    # Project config template
│
├── examples/
│   └── relayq/                  # RelayQ integration example
│
└── docs/
    ├── ARCHITECTURE.md          # Deep dive
    ├── SECURITY.md              # Security considerations
    └── TROUBLESHOOTING.md       # Common issues
```

## 💡 Use Cases

Perfect for:
- **Local-first SaaS** - Build and run locally, share with customers
- **Job orchestration dashboards** - Public access to job status/results
- **Client demos** - Share prototypes without deploying
- **Personal tools** - Run your own services at home
- **Development environments** - Share preview with team
- **Side projects** - No hosting costs

## 🆚 Comparison

| Feature | Traditional Hosting | Tailscale Funnel |
|---------|-------------------|------------------|
| Domain needed | Yes ($10-50/yr) | No (free .ts.net) |
| SSL setup | Manual/Let's Encrypt | Automatic |
| Hosting cost | $5-100+/month | Free |
| Deployment | Complex | Just run locally |
| Update time | Minutes (build/deploy) | Instant (restart) |
| Privacy control | Limited | Complete (on/off) |
| Local debugging | Hard (remote) | Easy (local) |

## 🔐 Security Notes

- ✅ Automatic HTTPS/TLS
- ✅ Traffic encrypted by Tailscale
- ⚠️ Anyone with URL can access (add authentication!)
- ⚠️ Your local machine must stay running
- ⚠️ Backup important data regularly

## 📖 Documentation

- [Integration Guide](INTEGRATION_GUIDE.md) - Add to any project
- [Architecture](docs/ARCHITECTURE.md) - Deep dive
- [Security](docs/SECURITY.md) - Security considerations
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues

## 🎯 When NOT to Use This

Don't use Tailscale Funnel for:
- ❌ High-traffic production apps (your laptop can't handle 10k users)
- ❌ Apps requiring 99.99% uptime (your machine goes to sleep)
- ❌ When you need a custom branded domain (use traditional hosting)
- ❌ Large teams (harder to coordinate local deployments)

**But DO use for:**
- ✅ Personal projects
- ✅ Side businesses with < 100 users
- ✅ Internal tools
- ✅ Prototypes/demos
- ✅ Development environments

## 🚀 Next Steps

1. Read [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) to add this to your project
2. Check [examples/relayq/](examples/relayq/) for RelayQ-specific integration
3. Explore [docs/](docs/) for detailed guides

## 📜 License

This module is free to use, modify, and distribute. No attribution required.

---

**Built for developers who want to run locally and share globally.** 🌍
