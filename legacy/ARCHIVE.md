# RelayQ Legacy Archive

This directory contains the original RelayQ implementation that used Redis as a job queue.

## Archived Components

- **relayq/**: Original Python package with Redis-based job queuing
- **Documentation**: Original docs describing Redis-based architecture
- **Installation Scripts**: Original broker and worker setup scripts

## Migration Status

The legacy Redis-based queue has been replaced by GitHub's native job queue system using GitHub Actions and self-hosted runners.

## Re-enabling Legacy (If Needed)

To restore the Redis-based system:

1. Install Redis broker using `legacy/install-broker.sh`
2. Install workers using `legacy/install-worker*.sh`
3. Use the Python package from `legacy/relayq/`

## Why Migrated

- GitHub provides free, managed job queue
- No need to maintain Redis infrastructure
- Better security (no inbound ports required)
- Integrated with GitHub UI and API
- Free self-hosted runner minutes