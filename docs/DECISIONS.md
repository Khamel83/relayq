# Decision Log

## Migration Decision: GitHub Queue vs Redis

### Decision Made

**Date:** 2025-11-03
**Status:** Implemented
**Decision:** Replace Redis-based job queue with GitHub's native job queue using self-hosted runners.

### Rationale

**Why GitHub Queue:**
- **Zero maintenance**: No Redis infrastructure to manage
- **Free tier**: 2,000 minutes/month for personal use
- **Better UI**: Native GitHub interface for monitoring
- **Integrated**: Works with existing GitHub workflows
- **Secure**: No inbound ports required
- **Reliable**: GitHub's infrastructure vs self-managed Redis

**Why Not Redis:**
- **Maintenance overhead**: Redis server management
- **Security concerns**: Redis exposure to internet
- **Single point of failure**: Service downtime
- **Complexity**: Additional infrastructure component
- **Monitoring**: Separate system to monitor

### Trade-offs

**Benefits of GitHub Queue:**
- ✅ No infrastructure maintenance
- ✅ Free personal tier
- ✅ Integrated with GitHub
- ✅ Better security posture
- ✅ Built-in monitoring
- ✅ API integration

**Limitations:**
- ❌ 2,000 minute monthly limit (free tier)
- ❌ GitHub dependency
- ❌ Less control over queue behavior
- ❌ Workflow file complexity

### Alternatives Considered

1. **Keep Redis**: Status quo, but with maintenance overhead
2. **AWS SQS**: More powerful, but adds cost and complexity
3. **RabbitMQ**: Full-featured, but overkill for personal use
4. **Self-hosted queue**: Complete control, but maintenance burden

### Implementation Decision

**Chosen approach:** GitHub Actions + self-hosted runners
- Use GitHub's workflow_dispatch for job triggers
- Self-hosted runners on Mac mini, RPi4, RPi3
- OCI VM as trigger point via GitHub CLI
- Optional Tailscale for private resource access

## Architecture Decisions

### Runner Labels Strategy

**Decision:** Use descriptive labels for job routing

**Labels defined:**
- `self-hosted`: All self-hosted runners
- `macmini`: macOS runner with heavy capabilities
- `rpi4`: Raspberry Pi 4 with medium capabilities
- `rpi3`: Raspberry Pi 3 for light tasks
- `audio`: Runners capable of audio processing
- `ffmpeg`: Runners with FFmpeg installed
- `heavy`: High-resource runners
- `light`: Low-resource runners

**Rationale:** Labels act as a look-up table for job routing, providing flexibility in job assignment without changing workflow definitions.

### Concurrency Management

**Decision:** Use workflow-level concurrency controls

**Implementation:**
- `audio-processing`: Global audio job coordination
- `macmini-transcribe`: Mac mini-specific limits
- `rpi4-summarize`: RPi4-specific limits

**Rationale:** Prevents resource conflicts while allowing optimal resource utilization.

### Security Model

**Decision:** Outbound-only connections

**Implementation:**
- Runners connect to GitHub (outbound)
- No inbound ports opened
- Tailscale only for private resource access

**Rationale:** Eliminates attack surface while maintaining functionality.

## Technology Decisions

### Job Script Implementation

**Decision:** POSIX shell scripts for maximum compatibility

**Chosen over:**
- Python scripts (more dependencies)
- Makefiles (less flexible)
- Containerized jobs (complexity overhead)

**Rationale:** Shell scripts work on macOS and Linux without additional dependencies.

### Backend Support

**Decision:** Multiple ASR backends with environment switching

**Backends supported:**
- Local (whisper.cpp/whisper)
- OpenAI API
- Router APIs (OpenRouter, etc.)

**Rationale:** Provides flexibility for cost, performance, and privacy requirements.

### Configuration Management

**Decision:** Node-local environment files + GitHub secrets

**Implementation:**
- Runner-specific secrets in `~/.config/relayq/env`
- Shared secrets in GitHub encrypted secrets
- Policy-based routing configuration

**Rationale:** Balances security with convenience and flexibility.

## File Organization Decisions

### Directory Structure

**Decision:** Separate concerns into distinct directories

```
relayq/
├── docs/           # Comprehensive documentation
├── policy/         # Routing and configuration policies
├── bin/            # Utility and dispatch scripts
├── jobs/           # Node-local job scripts
├── .github/        # GitHub workflow definitions
└── legacy/         # Archived Redis-based implementation
```

**Rationale:** Clear separation of concerns makes the project maintainable and understandable.

### Documentation Strategy

**Decision:** Comprehensive documentation with explicit runbook

**Documentation files created:**
- `OVERVIEW.md`: Architecture and motivation
- `SETUP_*.md`: Step-by-step setup guides
- `RUNBOOK.md`: Operations procedures
- `RELIABILITY.md`: Reliability patterns
- `ROUTING_POLICY.md`: Policy engine documentation
- `LLM_ROUTING.md`: Backend routing
- `OPSEC.md`: Security practices
- `DECISIONS.md`: This file

**Rationale:** Future-proofing against knowledge loss and enabling independent maintenance.

## Future-Proofing Decisions

### Policy-Based Routing

**Decision:** Centralized policy configuration

**Implementation:** `policy/policy.yaml` defines job routing rules

**Rationale:** Allows changing routing behavior without modifying workflows or code.

### Modular Job Design

**Decision:** Pluggable job architecture

**Implementation:** Jobs are standalone scripts that can be easily added or modified

**Rationale:** Enables extending functionality without architectural changes.

### Backend Abstraction

**Decision**: Backend-agnostic interface

**Implementation**: Environment variable selection + consistent interface

**Rationale**: Future models (e.g., "Sonnet-6") can be added by changing environment configuration.

## Risk Mitigation Decisions

### Legacy Code Preservation

**Decision:** Archive rather than delete Redis-based code

**Implementation:** Moved to `legacy/` directory with `ARCHIVE.md`

**Rationale:** Provides rollback option and preserves investment in original code.

### Gradual Migration

**Decision:** Support both systems during transition

**Implementation:** Legacy code remains available for fallback

**Rationale:** Reduces risk during migration and provides comparison data.

### Comprehensive Testing

**Decision:** Include acceptance tests in documentation

**Implementation:** Specific test scenarios documented

**Rationale:** Ensures the new system works as intended and provides validation procedures.

## Cost-Benefit Analysis

### Costs of Migration

**One-time costs:**
- Development time: ~2 days
- Learning curve: GitHub Actions workflows
- Documentation effort: comprehensive
- Testing and validation

**Ongoing costs:**
- Potential GitHub minutes beyond free tier: $8/month
- Maintenance of new documentation

### Benefits of Migration

**Immediate benefits:**
- Zero Redis maintenance
- Better security posture
- Integrated monitoring
- Professional UI

**Long-term benefits:**
- Scalability without infrastructure changes
- Community support (GitHub Actions)
- Easier troubleshooting
- Better reliability

**ROI Calculation:**
- Redis maintenance time saved: ~2 hours/month
- Improved reliability: Hard to quantify but significant
- Security improvement: Risk reduction
- **Payback period:** < 1 month

## Success Metrics

### Technical Metrics

- [ ] All runners online and responsive
- [ ] Jobs execute successfully on all target runners
- [ ] Failover works when runner goes offline
- [ ] Concurrency controls prevent resource conflicts
- [ ] No inbound ports required

### Operational Metrics

- [ ] Documentation covers all scenarios
- [ ] New team members can set up system independently
- [ ] Mean time to resolution for common issues < 15 minutes
- [ ] System uptime > 99%

### User Experience Metrics

- [ ] Job submission is intuitive
- [ ] Monitoring is clear and actionable
- [ ] Error messages are helpful
- [ ] System behavior is predictable

## Future Considerations

### Scalability

**Current limits:**
- 2,000 GitHub minutes/month (free tier)
- Physical hardware constraints
- Manual runner management

**Future scaling options:**
- Upgrade to paid GitHub plan
- Add more runners
- Implement auto-scaling (cloud runners)
- Add load balancing

### Feature Enhancements

**Potential additions:**
- Web UI for non-technical users
- Mobile app integration
- Advanced monitoring and alerting
- Automatic backend optimization
- Integration with other services

### Technology Evolution

**Areas to monitor:**
- GitHub Actions feature changes
- New ASR/LLM models
- Runner technology improvements
- Security best practices
- Cost optimization opportunities

## Conclusion

This migration represents a significant architectural improvement that reduces maintenance burden while improving security, reliability, and usability. The decision to use GitHub's native job queue aligns with modern DevOps practices and provides a solid foundation for future enhancements.

The comprehensive documentation and policy-based approach ensures the system remains maintainable and extensible, while the preservation of legacy code provides a safety net during the transition period.

**Next steps:** Monitor system performance, gather user feedback, and iterate on the implementation based on real-world usage patterns.