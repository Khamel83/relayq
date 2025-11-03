# LLM/ASR Backend Routing

## Backend Selection

### Environment-Based Switching

Jobs can route to different ASR/LLM backends based on environment configuration:

```bash
# jobs/transcribe.sh - Backend selection logic
case "$ASR_BACKEND" in
    "local")
        use_local_whisper ;;
    "openai")
        use_openai_api ;;
    "router")
        use_router_api ;;
    *)
        echo "Unknown backend: $ASR_BACKEND"
        exit 1 ;;
esac
```

### Supported Backends

#### Local (whisper.cpp/whisper)

**Advantages:**
- No API costs
- Complete privacy
- Works offline
- Predictable performance

**Disadvantages:**
- Limited to model capabilities
- Resource intensive
- Slower than cloud APIs

**Configuration:**
```bash
ASR_BACKEND=local
WHISPER_MODEL=base  # tiny, base, small, medium, large
WHISPER_MODEL_PATH=/opt/models/
```

#### OpenAI API

**Advantages:**
- High accuracy
- Fast processing
- Multiple models available
- No resource requirements

**Disadvantages:**
- API costs
- Requires internet
- Privacy considerations

**Configuration:**
```bash
ASR_BACKEND=openai
OPENAI_API_KEY=your_key_here
OPENAI_MODEL=whisper-1
```

#### Router API (OpenRouter/etc)

**Advantages:**
- Multiple model choices
- Cost optimization
- Fallback options
- Latest models

**Disadvantages:**
- API costs
- Internet dependency
- Additional complexity

**Configuration:**
```bash
ASR_BACKEND=router
ROUTER_API_KEY=your_key_here
ROUTER_BASE_URL=https://openrouter.ai/api/v1
ROUTER_MODEL=openai/whisper-1
```

## Backend Implementation

### Local Whisper Implementation

```bash
#!/bin/bash
# Local whisper implementation

use_local_whisper() {
    local input_file="$1"
    local output_file="$2"

    # Check if model exists
    local model_path="${WHISPER_MODEL_PATH}/${WHISPER_MODEL}.bin"
    if [ ! -f "$model_path" ]; then
        echo "Downloading model: $WHISPER_MODEL"
        mkdir -p "$WHISPER_MODEL_PATH"
        curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${WHISPER_MODEL}.bin" \
            -o "$model_path"
    fi

    # Run transcription
    if command -v whisper.cpp &> /dev/null; then
        whisper.cpp -m "$model_path" -f "$input_file" -otxt > "$output_file"
    elif command -v whisper &> /dev/null; then
        whisper "$input_file" --model "$WHISPER_MODEL" --output_format txt > "$output_file"
    else
        echo "Error: Neither whisper.cpp nor whisper found"
        exit 1
    fi
}
```

### OpenAI API Implementation

```bash
#!/bin/bash
# OpenAI API implementation

use_openai_api() {
    local input_file="$1"
    local output_file="$2"

    # Convert audio to required format
    local temp_file=$(mktemp --suffix=.mp3)
    ffmpeg -i "$input_file" -ar 16000 -ac 1 -c:a mp3 "$temp_file" -y

    # Transcribe via API
    curl -X POST "https://api.openai.com/v1/audio/transcriptions" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: multipart/form-data" \
        -F "file=@$temp_file" \
        -F "model=$OPENAI_MODEL" \
        -F "response_format=text" > "$output_file"

    rm -f "$temp_file"
}
```

### Router API Implementation

```bash
#!/bin/bash
# Router API implementation (OpenRouter example)

use_router_api() {
    local input_file="$1"
    local output_file="$2"

    # Prepare audio file
    local temp_file=$(mktemp --suffix=.mp3)
    ffmpeg -i "$input_file" -ar 16000 -ac 1 -c:a mp3 "$temp_file" -y

    # Transcribe via router
    curl -X POST "${ROUTER_BASE_URL}/audio/transcriptions" \
        -H "Authorization: Bearer $ROUTER_API_KEY" \
        -H "HTTP-Referer: https://github.com/Khamel83/relayq" \
        -H "X-Title: RelayQ" \
        -H "Content-Type: multipart/form-data" \
        -F "file=@$temp_file" \
        -F "model=$ROUTER_MODEL" > "$output_file"

    rm -f "$temp_file"
}
```

## Model Management

### Local Model Storage

```bash
# Model directory structure
/opt/models/
├── whisper/
│   ├── tiny.bin
│   ├── base.bin
│   ├── small.bin
│   ├── medium.bin
│   └── large.bin
└── custom/
    └── your-model.bin
```

### Model Selection Logic

```python
# select_model.py - Smart model selection
def select_model(file_size_mb, backend="local"):
    """Select appropriate model based on file size and backend"""

    if backend == "local":
        if file_size_mb < 10:
            return "base"
        elif file_size_mb < 50:
            return "small"
        elif file_size_mb < 200:
            return "medium"
        else:
            return "large"

    # Cloud backends use standard models
    return "whisper-1"
```

### Model Download Management

```bash
#!/bin/bash
# manage_models.sh - Model download and management

download_model() {
    local model="$1"
    local model_dir="/opt/models/whisper"

    if [ ! -f "$model_dir/${model}.bin" ]; then
        echo "Downloading model: $model"
        curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${model}.bin" \
            -o "$model_dir/${model}.bin"
    fi
}

# Pre-download common models
for model in tiny base small; do
    download_model "$model"
done
```

## Cost Optimization

### Backend Cost Analysis

| Backend | Cost per minute | Quality | Speed | Privacy |
|---------|-----------------|---------|-------|----------|
| Local | $0.00 (electricity) | Good | Medium | Full |
| OpenAI | $0.006 | Excellent | Fast | None |
| Router | $0.003-0.01 | Good-Excellent | Fast | Limited |

### Smart Routing Logic

```python
# route_by_cost.py - Cost-based routing

def choose_backend(file_size_mb, priority="normal", privacy_required=False):
    """Choose backend based on cost and requirements"""

    if privacy_required:
        return "local"

    if priority == "high" and file_size_mb < 100:
        return "openai"  # Fast but more expensive

    if file_size_mb > 500:
        return "local"  # Avoid high API costs for large files

    # Default to most cost-effective
    return "router" if os.getenv("ROUTER_API_KEY") else "local"
```

### Usage Monitoring

```bash
#!/bin/bash
# monitor_usage.sh - Track API usage and costs

# Track OpenAI usage
if [ "$ASR_BACKEND" = "openai" ]; then
    echo "$(date),openai,$DURATION_SECONDS,$INPUT_SIZE_MB" >> /var/log/relayq/usage.log
fi

# Track router usage
if [ "$ASR_BACKEND" = "router" ]; then
    echo "$(date),router,$DURATION_SECONDS,$INPUT_SIZE_MB" >> /var/log/relayq/usage.log
fi
```

## Future Model Integration

### Preparing for New Models

```bash
# Environment variable for future models
ASR_MODEL=whisper-1  # Current
# ASR_MODEL=sonnet-6  # Future
# ASR_MODEL=gpt-5-audio  # Future
```

### Backend-Agnostic Interface

```python
# backend_interface.py - Abstract backend interface

class ASRBackend:
    def transcribe(self, audio_file, model=None):
        raise NotImplementedError

class LocalBackend(ASRBackend):
    def transcribe(self, audio_file, model="base"):
        # Local implementation
        pass

class OpenAIBackend(ASRBackend):
    def transcribe(self, audio_file, model="whisper-1"):
        # OpenAI implementation
        pass

class RouterBackend(ASRBackend):
    def transcribe(self, audio_file, model=None):
        # Router implementation
        pass

# Factory pattern
def create_backend(backend_type):
    backends = {
        "local": LocalBackend,
        "openai": OpenAIBackend,
        "router": RouterBackend
    }
    return backends[backend_type]()
```

## Configuration Examples

### Mac mini Configuration

```bash
# ~/.config/relayq/env
ASR_BACKEND=local
WHISPER_MODEL=base
WHISPER_MODEL_PATH=/opt/models/whisper/

# Fallback API keys
OPENAI_API_KEY=sk-...
ROUTER_API_KEY=sk-or-...
```

### RPi4 Configuration

```bash
# ~/.config/relayq/env
ASR_BACKEND=router  # Better performance than local on Pi
ROUTER_API_KEY=sk-or-...
ROUTER_MODEL=openai/whisper-1

# Fallback to tiny model if internet down
WHISPER_MODEL=tiny
WHISPER_MODEL_PATH=/home/pi/.cache/whisper/
```

### RPi3 Configuration

```bash
# ~/.config/relayq/env
ASR_BACKEND=openai  # Pi 3 too slow for local processing
OPENAI_API_KEY=sk-...

# Emergency fallback
ROUTER_API_KEY=sk-or-...
```

## Testing Backends

### Backend Validation

```bash
#!/bin/bash
# test_backends.sh - Validate backend functionality

test_local() {
    echo "Testing local backend..."
    ASR_BACKEND=local jobs/transcribe.sh test_audio.mp3
}

test_openai() {
    echo "Testing OpenAI backend..."
    ASR_BACKEND=openai jobs/transcribe.sh test_audio.mp3
}

test_router() {
    echo "Testing router backend..."
    ASR_BACKEND=router jobs/transcribe.sh test_audio.mp3
}

# Run all tests
test_local && test_openai && test_router
```

### Performance Comparison

```bash
#!/bin/bash
# benchmark_backends.sh - Compare backend performance

for backend in local openai router; do
    echo "Benchmarking $backend..."
    time ASR_BACKEND=$backend jobs/transcribe.sh benchmark_audio.mp3
done
```

## Migration Path

### Adding New Backends

1. **Add environment variable** for new backend
2. **Implement backend logic** in job script
3. **Update configuration documentation**
4. **Test new backend**
5. **Update routing logic**

### Backward Compatibility

- Existing backends continue to work
- Default backend selection preserved
- Configuration changes optional
- Migration documentation provided