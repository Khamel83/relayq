# Routing Policy Configuration

## Overview

The routing policy determines which runner executes which jobs based on job types, constraints, and available resources.

## Policy Schema

`policy/policy.yaml` defines job routing rules:

```yaml
routes:
  <job_type>:
    prefer: [label1, label2, ...]     # Preferred runner labels (in order)
    fallback: [label1, label2, ...]   # Fallback runners if preferred unavailable
    constraints:                     # Optional job requirements
      needs_ffmpeg: true
      max_size_mb: 500
      min_memory_gb: 2
      max_concurrent: 1
```

## Default Policy

### transcribe Route

```yaml
transcribe:
  prefer: [macmini]
  fallback: [rpi4]
  constraints:
    needs_ffmpeg: true
    max_size_mb: 1000
    min_memory_gb: 2
    max_concurrent: 1
```

**Rationale:**
- **Prefer Mac mini**: Better performance for audio processing
- **Fallback to RPi4**: For smaller files or when Mac mini busy
- **FFmpeg required**: For audio format conversion
- **Memory constraint**: Ensure adequate resources
- **Concurrency limit**: Prevent resource conflicts

### summarize Route

```yaml
summarize:
  prefer: [rpi4]
  fallback: [macmini]
  constraints:
    max_size_mb: 100
    min_memory_gb: 1
    max_concurrent: 2
```

**Rationale:**
- **Prefer RPi4**: Lighter task, conserves Mac mini for heavy work
- **Fallback to Mac mini**: If RPi4 unavailable or busy
- **Lower constraints**: Text processing is less resource-intensive

### thumbnail Route

```yaml
thumbnail:
  prefer: [macmini]
  fallback: [rpi4]
  constraints:
    needs_ffmpeg: true
    max_size_mb: 200
    min_memory_gb: 1
    max_concurrent: 2
```

## Policy Engine

### select_target.py Usage

```bash
# Select target workflow based on policy
./bin/select_target.py transcribe '{"url": "https://example.com/file.mp3", "size_mb": 50}'

# Output: .github/workflows/transcribe_audio.yml (pooled)
# or: .github/workflows/transcribe_mac.yml (Mac-specific)
# or: .github/workflows/transcribe_rpi.yml (RPi-specific)
```

### Selection Logic

1. **Check constraints**: Verify job meets all constraints
2. **Preferred runners**: Try each preferred label in order
3. **Fallback runners**: Try each fallback label in order
4. **Pooled vs specific**: Choose pooled workflow unless constraints force specific runner
5. **No match**: Return error if no suitable runner found

### Constraint Evaluation

```python
def evaluate_constraints(constraints, job_params):
    """Check if job meets runner constraints"""

    # Size constraint
    if 'max_size_mb' in constraints:
        if job_params.get('size_mb', 0) > constraints['max_size_mb']:
            return False

    # Memory constraint
    if 'min_memory_gb' in constraints:
        # Check runner memory availability
        pass

    # Software requirement
    if 'needs_ffmpeg' in constraints:
        # Verify runner has FFmpeg installed
        pass

    return True
```

## Label Mappings

### Runner Capabilities

| Label | Runner | Capabilities | Typical Use |
|-------|--------|--------------|-------------|
| `macmini` | Mac mini | Heavy processing, FFmpeg, lots of RAM | Audio/video transcoding |
| `rpi4` | Raspberry Pi 4 | Light processing, modest memory | Text processing, small audio |
| `rpi3` | Raspberry Pi 3 | Very light processing, limited memory | Overflow tasks, monitoring |
| `audio` | Mac mini, RPi4 | Audio processing capabilities | Transcription, analysis |
| `ffmpeg` | Mac mini, RPi4 | FFmpeg installed | Video/audio conversion |
| `heavy` | Mac mini | High CPU/memory available | Large file processing |
| `light` | RPi4, RPi3 | Limited resources | Small tasks |
| `overflow` | RPi3 | Backup processing | Non-urgent tasks |

### Workflow Labels

- **Pooled workflows**: Use generic labels (`audio`, `light`, `heavy`)
- **Specific workflows**: Use runner-specific labels (`macmini`, `rpi4`, `rpi3`)

## Dynamic Routing

### Runtime Decision Making

```python
# Example: Choose backend based on file size
def choose_backend(file_size_mb):
    if file_size_mb > 100:
        return "macmini"  # Large files need more power
    elif file_size_mb > 20:
        return "pooled"   # Medium files, either runner
    else:
        return "rpi4"     # Small files, use efficient runner
```

### Load Balancing

```python
# Example: Distribute jobs based on current load
def select_least_loaded_runner(available_runners):
    # Check GitHub API for runner status
    # Select runner with fewest active jobs
    pass
```

## Policy Updates

### Hot Reloading

Policies are read from `policy/policy.yaml` at runtime:
- No restart required for policy changes
- Changes take effect for new jobs
- Existing jobs continue with original policy

### Versioning

```yaml
# Policy version for compatibility
policy_version: "1.0"
last_updated: "2025-11-03"
```

## Troubleshooting

### Jobs Not Executing

1. **Check policy syntax**: `python -c 'import yaml; yaml.safe_load(open("policy/policy.yaml"))'`
2. **Verify runner labels**: Check in GitHub UI
3. **Check constraints**: Job may not meet runner requirements
4. **Runner availability**: Verify runners are online

### Wrong Runner Selected

1. **Review prefer/fallback order**: Adjust in policy.yaml
2. **Check constraint logic**: May be too restrictive
3. **Verify label mapping**: Ensure labels match runner capabilities

### Performance Issues

1. **Analyze job distribution**: Check if jobs are balanced
2. **Adjust constraints**: May be blocking optimal runners
3. **Monitor resource usage**: Check if runners are overloaded