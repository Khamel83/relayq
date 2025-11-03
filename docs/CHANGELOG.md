# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub-first hybrid runner architecture
- Comprehensive documentation suite
- Policy-based job routing system
- Multiple ASR backend support (local, OpenAI, router)
- Security and operational procedures

### Changed
- Migrated from Redis-based queue to GitHub Actions
- Archived legacy code to `legacy/` directory
- Updated architecture to use self-hosted runners

### Deprecated
- Redis-based job queue system
- Original Python client library

### Removed
- Original installation scripts (moved to legacy)

### Security
- No inbound ports required
- Enhanced secret management
- Improved security posture

---

## [1.0.0-hybrid] - 2025-11-03

### Major Changes
- **Breaking Change**: Complete migration from Redis to GitHub Actions
- **New Architecture**: GitHub-first hybrid runner system
- **Documentation**: Comprehensive documentation suite

### Added
- GitHub Actions workflow integration
- Self-hosted runner support for macOS and Raspberry Pi
- Policy-based job routing with `policy/policy.yaml`
- Dispatch script `bin/dispatch.sh` for OCI VM triggering
- Target selection script `bin/select_target.py`
- Audio transcription job script `jobs/transcribe.sh`
- Multiple ASR backend support:
  - Local Whisper/whisper.cpp
  - OpenAI API
  - Router APIs (OpenRouter, etc.)

### Documentation
- `OVERVIEW.md` - Complete architecture overview
- `SETUP_RUNNERS_mac.md` - macOS runner setup guide
- `SETUP_RUNNERS_rpi.md` - Raspberry Pi runner setup guide
- `SETUP_OCI_TRIGGER.md` - OCI VM trigger setup
- `ROUTING_POLICY.md` - Policy engine documentation
- `RUNBOOK.md` - Operations runbook
- `RELIABILITY.md` - Reliability patterns and procedures
- `LLM_ROUTING.md` - ASR/LLM backend routing
- `OPSEC.md` - Security practices and procedures
- `DECISIONS.md` - Detailed decision log
- `TASKS.md` - Project implementation checklist

### Features
- **Zero Configuration**: Runners auto-discover and self-configure
- **Pooled Execution**: Jobs automatically distribute across available runners
- **Failover Support**: Automatic fallback to alternative runners
- **Concurrency Control**: Resource-level job coordination
- **Multi-Backend Support**: Flexible ASR backend selection
- **Secure Architecture**: Outbound-only connections, no exposed ports
- **Cost Optimization**: Free GitHub minutes + local processing

### Workflows
- `transcribe_audio.yml` - Pooled audio processing
- `transcribe_mac.yml` - Mac mini-specific processing
- `transcribe_rpi.yml` - Raspberry Pi-specific processing

### Security
- Node-local secret management
- GitHub encrypted secrets integration
- Runner isolation and resource limits
- Comprehensive security documentation

### Reliability
- Runner auto-restart configuration
- Health monitoring procedures
- Idempotent job scripts
- Comprehensive error handling

### Performance
- Concurrency controls for resource management
- Optimized job distribution
- Timeout management for long-running tasks
- Performance monitoring capabilities

### Breaking Changes
- Redis-based queue system replaced by GitHub Actions
- Original Python client library archived
- New workflow-based job submission
- Updated configuration management

### Migration
- Legacy code preserved in `legacy/` directory
- Comprehensive migration documentation
- Step-by-step setup guides
- Backward compatibility considerations

### Dependencies
- GitHub Actions (free tier: 2,000 minutes/month)
- Self-hosted runners (macOS, Raspberry Pi)
- Optional: FFmpeg for audio processing
- Optional: Python with whisper libraries

### Supported Platforms
- macOS 11+ (Big Sur or later)
- Raspberry Pi OS (64-bit recommended)
- Ubuntu/Debian Linux

### Known Limitations
- 2,000 minute monthly limit on GitHub free tier
- Requires internet connectivity for GitHub communication
- Runner management is manual
- Limited to runner hardware capabilities

---

## [0.9.0] - 2025-11-02

### Added
- Redis-based job queue system
- Python client library
- Installation scripts for workers
- Basic documentation

### Features
- Distributed job execution
- Worker auto-discovery
- Basic load balancing
- Redis queue management

### Documentation
- Basic README and setup instructions
- Installation script documentation
- Usage examples

---

## Migration Guide

### From 0.9.0 to 1.0.0-hybrid

1. **Stop existing Redis workers**
   ```bash
   sudo systemctl stop old_services
   ```

2. **Archive existing installation**
   ```bash
   mv /opt/relayq /opt/relayq-legacy
   ```

3. **Set up new GitHub-based system**
   - Follow setup guides in `docs/`
   - Install self-hosted runners
   - Configure OCI VM trigger

4. **Migrate jobs**
   - Convert job scripts to new format
   - Update job submission to use GitHub Actions
   - Test with sample workloads

5. **Update automation**
   - Replace Redis client calls with GitHub CLI
   - Update cron jobs to use `bin/dispatch.sh`
   - Modify application integrations

### Rollback

If needed, legacy Redis-based system can be restored:
1. Restore `/opt/relayq-legacy` to `/opt/relayq`
2. Start Redis service
3. Re-register workers
4. Update applications to use Python client

---

## Support

For questions about migration:
- Review `docs/DECISIONS.md` for migration rationale
- Check `docs/TASKS.md` for implementation status
- Consult individual setup guides for detailed procedures
- Open GitHub issue for specific problems