# Project Tasks Checklist

## Bootstrapping

- [ ] Create branch `hybrid-runner-migration`
- [ ] Move legacy code to `legacy/` directory
- [ ] Write `legacy/ARCHIVE.md` explaining migration
- [ ] Create directory structure (`docs/`, `policy/`, `bin/`, `jobs/`)
- [ ] Commit scaffolding (docs, policy, bin, jobs, workflows)
- [ ] Initialize project tracking in this file

## Documentation

### Core Documentation
- [x] `docs/OVERVIEW.md` - Architecture and motivation
- [x] `docs/SETUP_RUNNERS_mac.md` - macOS runner setup
- [x] `docs/SETUP_RUNNERS_rpi.md` - Raspberry Pi runner setup
- [x] `docs/SETUP_OCI_TRIGGER.md` - OCI VM trigger setup
- [x] `docs/ROUTING_POLICY.md` - Policy engine documentation
- [x] `docs/RUNBOOK.md` - Operations procedures
- [x] `docs/RELIABILITY.md` - Reliability patterns
- [x] `docs/LLM_ROUTING.md` - Backend routing guide
- [x] `docs/OPSEC.md` - Security practices
- [x] `docs/DECISIONS.md` - Decision log
- [x] `docs/CHANGELOG.md` - Version history

### Documentation Review
- [ ] Review all docs for clarity and completeness
- [ ] Test setup procedures from scratch
- [ ] Validate troubleshooting steps
- [ ] Cross-reference related documents
- [ ] Add diagrams where helpful

## Runners

### Mac mini Setup
- [ ] Download runner binary for macOS
- [ ] Configure with appropriate labels: `self-hosted, macmini, audio, ffmpeg, heavy`
- [ ] Install as system service using `svc.sh`
- [ ] Install FFmpeg and Python dependencies
- [ ] Create `~/.config/relayq/env` with local configuration
- [ ] Test runner connectivity to GitHub
- [ ] Verify labels appear correctly in GitHub UI
- [ ] Test job execution

### RPi4 Setup
- [ ] Download runner binary for ARM architecture
- [ ] Create dedicated `runner` user
- [ ] Configure with appropriate labels: `self-hosted, rpi4, audio, light`
- [ ] Create systemd service for auto-start
- [ ] Install FFmpeg and Python dependencies
- [ ] Create `~/.config/relayq/env` with Pi-specific settings
- [ ] Test runner connectivity to GitHub
- [ ] Verify labels appear correctly in GitHub UI
- [ ] Test job execution

### RPi3 Setup (Optional)
- [ ] Follow RPi4 setup procedure
- [ ] Use labels: `self-hosted, rpi3, overflow, verylight`
- [ ] Configure for minimal resource usage
- [ ] Test with lightweight tasks only

## OCI Trigger Setup

### GitHub CLI Installation
- [ ] Install GitHub CLI on OCI VM
- [ ] Authenticate with GitHub account
- [ ] Verify repository access
- [ ] Test basic workflow operations

### Dispatch Script
- [ ] Implement `bin/dispatch.sh` with error handling
- [ ] Add support for multiple parameters
- [ ] Include run URL output
- [ ] Test with all workflow types
- [ ] Add help documentation

### Integration Testing
- [ ] Test dispatch from OCI VM
- [ ] Verify job execution on runners
- [ ] Test parameter passing
- [ ] Validate error handling
- [ ] Check result retrieval

## Jobs Implementation

### Transcription Script
- [ ] Implement `jobs/transcribe.sh` with multiple backend support
- [ ] Add local Whisper backend
- [ ] Add OpenAI API backend
- [ ] Add router API backend (OpenRouter)
- [ ] Implement backend selection logic
- [ ] Add error handling and logging
- [ ] Create idempotent behavior
- [ ] Add temporary file cleanup

### Backend Configuration
- [ ] Create `jobs/env.example` template
- [ ] Document all environment variables
- [ ] Add example API key configurations
- [ ] Include model selection examples
- [ ] Document NAS mount options

### Testing Jobs
- [ ] Test transcription with local backend
- [ ] Test transcription with OpenAI backend
- [ ] Test transcription with router backend
- [ ] Verify output file handling
- [ ] Test error conditions
- [ ] Validate cleanup procedures

## Workflows

### Pooled Workflow
- [ ] Create `.github/workflows/transcribe_audio.yml`
- [ ] Configure for `[self-hosted, audio]` labels
- [ ] Add `workflow_dispatch` trigger with URL input
- [ ] Set appropriate timeout (240 minutes)
- [ ] Add concurrency control: `audio-processing`
- [ ] Implement job steps: fetch, transcribe, upload artifact
- [ ] Add error handling and logging

### Mac-specific Workflow
- [ ] Create `.github/workflows/transcribe_mac.yml`
- [ ] Configure for `[self-hosted, macmini]` labels
- [ ] Add concurrency control: `macmini-transcribe`
- [ ] Use same job logic as pooled version
- [ ] Add Mac-specific optimizations

### RPi-specific Workflow
- [ ] Create `.github/workflows/transcribe_rpi.yml`
- [ ] Configure for `[self-hosted, rpi4]` labels
- [ ] Add concurrency control: `rpi4-transcribe`
- [ ] Use same job logic as pooled version
- [ ] Add Pi-specific optimizations

### Workflow Testing
- [ ] Test each workflow individually
- [ ] Verify label matching works correctly
- [ ] Test concurrency controls
- [ ] Validate artifact upload
- [ ] Test error scenarios

## Policy and Routing

### Policy Configuration
- [ ] Create `policy/policy.yaml` with routing rules
- [ ] Define `transcribe` route with Mac mini preference
- [ ] Define `summarize` route with RPi4 preference
- [ ] Add constraint definitions (FFmpeg, memory, etc.)
- [ ] Document policy schema

### Target Selection Script
- [ ] Implement `bin/select_target.py`
- [ ] Add policy YAML parsing
- [ ] Implement constraint evaluation
- [ ] Add fallback logic
- [ ] Include error handling

### Routing Testing
- [ ] Test policy-based workflow selection
- [ ] Verify constraint enforcement
- [ ] Test fallback behavior
- [ ] Validate edge cases

## Data Access and Storage

### File Handling
- [ ] Implement secure temporary file creation
- [ ] Add atomic file operations
- [ ] Create cleanup procedures
- [ ] Test with various file sizes

### NAS Integration (Optional)
- [ ] Set up Tailscale for private network access
- [ ] Mount NAS storage on runners
- [ ] Update job scripts to use NAS paths
- [ ] Test file access through Tailscale
- [ ] Document NAS configuration

### Output Management
- [ ] Configure artifact upload for results
- [ ] Implement local output file handling
- [ ] Add cleanup policies for old outputs
- [ ] Test result retrieval methods

## Reliability and Monitoring

### Service Configuration
- [ ] Configure auto-restart for all runners
- [ ] Add health monitoring scripts
- [ ] Implement backup procedures
- [ ] Test recovery scenarios

### Monitoring Setup
- [ ] Create job status monitoring
- [ ] Add performance tracking
- [ ] Implement alerting for failures
- [ ] Set up log collection

### Testing Reliability
- [ ] Test runner failure scenarios
- [ ] Validate failover behavior
- [ ] Test concurrent job handling
- [ ] Verify timeout handling

## Security and OPSEC

### Secret Management
- [ ] Set up GitHub encrypted secrets
- [ ] Configure node-local environment files
- [ ] Validate secret isolation
- [ ] Add secret rotation procedures

### Access Control
- [ ] Configure runner user permissions
- [ ] Implement file system isolation
- [ ] Add resource limits
- [ ] Test access controls

### Security Validation
- [ ] Verify no inbound ports required
- [ ] Test network security
- [ ] Validate data handling
- [ ] Run security audit

## Integration and Validation

### End-to-End Testing
- [ ] Test complete job lifecycle
- [ ] Validate all trigger methods
- [ ] Test all backend options
- [ ] Verify error handling

### Performance Testing
- [ ] Test with various file sizes
- [ ] Measure job completion times
- [ ] Validate resource usage
- [ ] Test concurrent load

### Acceptance Tests
- [ ] Run Mac-specific workflow with Mac offline
- [ ] Verify job queues correctly
- [ ] Test pooled workflow execution
- [ ] Validate automatic job pickup

## Documentation and Finalization

### Documentation Review
- [ ] Review all setup procedures
- [ ] Validate troubleshooting steps
- [ ] Test runbook procedures
- [ ] Cross-reference all documents

### Project Completion
- [ ] Update `docs/CHANGELOG.md` with migration details
- [ ] Create final commit with logical grouping
- [ ] Open pull request with comprehensive description
- [ ] Tag release `v1.0.0-hybrid`
- [ ] Archive old documentation appropriately

## Post-Migration

### Monitoring Period
- [ ] Monitor system for 1 week
- [ ] Collect performance metrics
- [ ] Document any issues found
- [ ] Update documentation based on findings

### Optimization
- [ ] Analyze job distribution patterns
- [ ] Optimize runner assignments
- [ ] Tune timeout and concurrency settings
- [ ] Update policies based on usage

### Future Enhancements
- [ ] Identify improvement opportunities
- [ ] Plan additional job types
- [ ] Consider automation improvements
- [ ] Document roadmap

## Checklist Validation

### Before PR
- [ ] All acceptance tests pass
- [ ] Documentation is complete and accurate
- [ ] No secrets committed to repository
- [ ] All runners online and functional
- [ ] CI/CD pipeline working

### After Merge
- [ ] Monitor for any regressions
- [ ] Update any external references
- [ ] Communicate changes to stakeholders
- [ ] Archive migration branch appropriately

---

## Notes

- This checklist should be used as a guide for implementation progress
- Items can be completed in parallel where dependencies allow
- Regular updates to this file help track project progress
- Consider using external checklist tools for better tracking