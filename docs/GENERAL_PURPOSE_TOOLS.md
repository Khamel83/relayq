# General-Purpose Media Processing Tools

## 🎯 Philosophy

**Build powerful, reusable tools first - then let projects leverage them.**

Instead of project-specific implementations, this approach creates a library of general-purpose GitHub Actions workflows that can be used by:
- **RelayQ** (transcription focus)
- **Atlas** (content processing focus)
- **Future projects** (any media processing needs)

## 🛠️ Core Tool Components

### 1. Video/Audio Processor (`video_audio_processor.yml`)

**Purpose**: Complete media processing pipeline
**Use Cases**: Transcription, format conversion, quality analysis, metadata extraction

```yaml
Tasks Available:
- download-transcribe: Download + transcribe media
- download-only: Just download media files
- batch-process: Process multiple files
- metadata-extract: Extract detailed metadata
- quality-analyze: Analyze media quality metrics
- thumbnail-generate: Create thumbnails and previews
- playlist-process: Process entire playlists

Sources Supported:
- YouTube: Videos, playlists, channels
- Vimeo: Professional video content
- SoundCloud: Audio content
- Direct URLs: Any media file URL
```

**Example Usage**:
```bash
# Transcribe a YouTube video
gh workflow run video_audio_processor.yml \
  --field task="download-transcribe" \
  --field source="youtube" \
  --field url="https://youtube.com/watch?v=VIDEO_ID" \
  --field transcription_model="large-v3"

# Process a podcast playlist
gh workflow run video_audio_processor.yml \
  --field task="playlist-process" \
  --field source="youtube" \
  --field url="https://youtube.com/playlist?list=PLAYLIST_ID"
```

### 2. Content Discovery (`content_discovery.yml`)

**Purpose**: Automatically discover and monitor new content
**Use Cases**: Channel monitoring, RSS feeds, Reddit content, automated processing

```yaml
Discovery Methods:
- channel-monitor: Track YouTube channels for new videos
- playlist-scan: Monitor playlists for additions
- rss-monitor: Process RSS feeds for media content
- reddit-monitor: Find media content in subreddits
- import-list: Process a list of URLs
- cleanup-duplicates: Remove duplicate content

Auto-Processing:
- Can automatically trigger Video/Audio Processor
- Keyword filtering for relevant content
- Age-based filtering
- Configurable processing limits
```

**Example Usage**:
```bash
# Monitor a YouTube channel
gh workflow run content_discovery.yml \
  --field task="channel-monitor" \
  --field source_url="https://youtube.com/@channel_name" \
  --field keywords="podcast,interview,tech" \
  --field auto_process="true"

# Monitor Reddit for videos
gh workflow run content_discovery.yml \
  --field task="reddit-monitor" \
  --field source_url="documentaries" \
  --field max_age_days="7" \
  --field auto_process="true"
```

### 3. System Management (`system_management.yml`)

**Purpose**: Maintain and monitor the Mac mini processing system
**Use Cases**: Health checks, storage cleanup, performance monitoring, updates

```yaml
Management Tasks:
- health-check: Complete system health report
- storage-cleanup: Remove old/temporary files
- performance-benchmark: Test system performance
- software-update: Check for package updates
- backup-configs: Backup configuration files
- monitor-resources: Real-time resource usage
- database-maintenance: Database optimization
- security-scan: Security vulnerability check

Scheduling:
- Daily health checks (2 AM)
- Weekly storage cleanup (Sunday 3 AM)
- On-demand execution via workflow dispatch
```

**Example Usage**:
```bash
# Run system health check
gh workflow run system_management.yml \
  --field task="health-check"

# Clean up storage if over 100GB
gh workflow run system_management.yml \
  --field task="storage-cleanup" \
  --field storage_threshold="100"
```

## 🔄 Integration Patterns

### Pattern 1: RelayQ Integration

RelayQ can focus purely on transcription while leveraging these tools:

```yaml
# RelayQ-specific transcription job
- name: RelayQ Transcription
  uses: ./.github/workflows/video_audio_processor.yml
  with:
    task: download-transcribe
    source: youtube
    transcription_model: large-v3
```

### Pattern 2: Atlas Integration

Atlas can focus on content organization while using these tools for processing:

```yaml
# Atlas content pipeline
- name: Atlas Content Pipeline
  run: |
    # Step 1: Discover new content
    gh workflow run content_discovery.yml \
      --field task="channel-monitor" \
      --field auto_process="true"

    # Step 2: Process discovered content
    gh workflow run video_audio_processor.yml \
      --field task="download-transcribe"
```

### Pattern 3: Custom Project Integration

Any new project can immediately use these tools:

```yaml
# Custom project - movie analysis
- name: Movie Analysis Pipeline
  uses: ./.github/workflows/video_audio_processor.yml
  with:
    task: quality-analyze
    source: direct
```

## 🎛️ Configuration & Customization

### Environment Variables
All tools support RelayQ environment variables:
```bash
# ~/.config/relayq/env
OPENAI_API_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_KEYS="your-keys-here"
ASR_BACKEND=local
WHISPER_MODEL=large-v3
ENABLE_METAL_ACCELERATION=true
MPS_DEVICE=mps
```

### Custom Parameters
Each tool supports extensive customization:
- **Quality settings**: 4K, 1080p, 720p, audio-only
- **Transcription models**: large-v3, large-v2, medium, base
- **Output formats**: MP4, WebM, MP3, WAV, SRT, VTT
- **Processing limits**: Batch sizes, timeouts, resource limits

### Storage Management
Configurable storage locations and cleanup policies:
```yaml
Storage Locations:
  /tmp/media-processing/     # Processing workspace
  /tmp/content-discovery/   # Discovery results
  /tmp/system-report/       # System reports

Cleanup Policies:
  - Retain artifacts for 7-30 days
  - Automatic cleanup of temp files
  - Configurable storage thresholds
```

## 🚀 Benefits of This Approach

### 1. **Code Reusability**
- Single implementation works for all projects
- No duplicated code across repositories
- Consistent behavior across all uses

### 2. **Maintainability**
- One place to fix bugs or add features
- All projects benefit from improvements
- Easier to test and validate

### 3. **Flexibility**
- Mix and match tools as needed
- Easy to extend with new capabilities
- Compatible with any project structure

### 4. **Scalability**
- Tools designed for production use
- Resource monitoring and management
- Performance optimization built-in

## 📋 Implementation Guide

### Getting Started
1. **Install these workflows** in your repository
2. **Configure environment** variables
3. **Test with sample URLs**
4. **Customize parameters** for your needs

### Integration Steps
1. **Identify your needs** (transcription, discovery, management)
2. **Choose relevant tools** from the toolkit
3. **Create wrapper workflows** if needed
4. **Set up automation** (schedules, triggers)
5. **Monitor and optimize** based on usage

### Best Practices
- **Start small**: Test individual tools first
- **Monitor resources**: Use system management tools
- **Clean up regularly**: Prevent storage issues
- **Log everything**: Track usage and performance
- **Version control**: Keep workflow configurations tracked

## 🔧 Extension Points

### Adding New Sources
Extend video_audio_processor.yml to support new platforms:
```yaml
New Platform Support:
- Add platform option to source choice
- Implement platform-specific download logic
- Add platform-specific metadata extraction
- Test with sample content
```

### Adding New Processing Tasks
Extend video_audio_processor.yml with new capabilities:
```yaml
New Tasks:
- Add to task choices in workflow_dispatch
- Implement processing logic
- Add output handling
- Update documentation
```

### Adding New Discovery Methods
Extend content_discovery.yml for new sources:
```yaml
New Discovery:
- Add discovery method to task choices
- Implement monitoring logic
- Add content filtering
- Test with real feeds
```

## 🎯 Future Roadmap

### Phase 1: Core Tools ✅
- Video/Audio Processor
- Content Discovery
- System Management

### Phase 2: Enhanced Tools
- **API Gateway**: Centralized access to all tools
- **Web Interface**: Visual management dashboard
- **Database Integration**: Persistent storage for results
- **Advanced Analytics**: Processing statistics and insights

### Phase 3: Ecosystem
- **Plugin System**: Third-party extensions
- **Multi-Runner Support**: Distribute processing across multiple machines
- **Cloud Integration**: AWS, Google Cloud, Azure runners
- **AI Enhancement**: Advanced content analysis and classification

---

**Result**: A comprehensive, reusable toolkit for video/audio processing that can serve any project's needs while maintaining clean separation of concerns between tools and projects.