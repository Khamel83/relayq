#!/bin/bash
# RelayQ Audio Transcription Script
# Supports multiple backends: local Whisper, OpenAI API, Router APIs

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_BASE="/tmp"
OUTPUT_DIR="/tmp/relayq-outputs"

# Source node-local environment if available
if [[ -f "$HOME/.config/relayq/env" ]]; then
    source "$HOME/.config/relayq/env"
fi

# Default values
ASR_BACKEND="${ASR_BACKEND:-local}"
WHISPER_MODEL="${WHISPER_MODEL:-base}"
WHISPER_MODEL_PATH="${WHISPER_MODEL_PATH:-/opt/models/whisper}"
OPENAI_API_KEY="${OPENAI_API_KEY:-}"
ROUTER_API_KEY="${ROUTER_API_KEY:-}"
ROUTER_BASE_URL="${ROUTER_BASE_URL:-https://openrouter.ai/api/v1}"
ROUTER_MODEL="${ROUTER_MODEL:-openai/whisper-1}"

# Logging functions
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Cleanup function
cleanup() {
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log_info "Cleaned up temporary directory: $TEMP_DIR"
    fi
}

# Set up cleanup on exit
trap cleanup EXIT

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to validate URL
validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]]; then
        log_error "Invalid URL format: $url"
        return 1
    fi
}

# Function to download file
download_file() {
    local url="$1"
    local dest_dir="$2"
    local filename

    # Extract filename from URL
    filename=$(basename "$url")
    if [[ -z "$filename" ]]; then
        # Generate random filename if URL ends with /
        filename="audio-$(date +%s).mp3"
    fi

    local dest_path="$dest_dir/$filename"

    log_info "Downloading from: $url"
    if ! curl -L -o "$dest_path" --fail --show-error --silent "$url"; then
        log_error "Failed to download file from: $url"
        return 1
    fi

    log_info "Downloaded to: $dest_path"

    # Verify file exists and has content
    if [[ ! -f "$dest_path" || ! -s "$dest_path" ]]; then
        log_error "Downloaded file is empty or missing: $dest_path"
        return 1
    fi

    echo "$dest_path"
}

# Function to check FFmpeg availability
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        log_error "FFmpeg not found. Please install FFmpeg."
        return 1
    fi
}

# Function to convert audio to required format
convert_audio() {
    local input_file="$1"
    local output_file="$2"

    log_info "Converting audio to WAV format"
    if ! ffmpeg -i "$input_file" -ar 16000 -ac 1 -c:a pcm_s16le "$output_file" -y 2>/dev/null; then
        log_error "Failed to convert audio file"
        return 1
    fi

    log_info "Audio conversion completed"
}

# Function to download Whisper model
download_whisper_model() {
    local model="$1"
    local model_file="${WHISPER_MODEL_PATH}/${model}.bin"

    if [[ -f "$model_file" ]]; then
        log_info "Model already exists: $model_file"
        return 0
    fi

    log_info "Downloading Whisper model: $model"
    mkdir -p "$WHISPER_MODEL_PATH"

    local model_url="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${model}.bin"
    if ! curl -L -o "$model_file" --fail --show-error "$model_url"; then
        log_error "Failed to download model: $model"
        return 1
    fi

    log_info "Model downloaded: $model_file"
}

# Function for local Whisper transcription
use_local_whisper() {
    local input_file="$1"
    local output_file="$2"

    log_info "Using local Whisper backend"

    # Download model if needed
    if ! download_whisper_model "$WHISPER_MODEL"; then
        return 1
    fi

    local model_file="${WHISPER_MODEL_PATH}/${WHISPER_MODEL}.bin"

    # Try whisper.cpp first (faster)
    if command -v whisper &> /dev/null && whisper --help 2>/dev/null | grep -q whisper.cpp; then
        log_info "Transcribing with whisper.cpp"
        if ! whisper -m "$model_file" -f "$input_file" -otxt "$output_file" 2>/dev/null; then
            log_error "whisper.cpp transcription failed"
            return 1
        fi
    # Try Python whisper
    elif command -v python3 &> /dev/null; then
        log_info "Transcribing with Python whisper"
        if ! python3 -c "
import whisper
model = whisper.load_model('$WHISPER_MODEL')
result = model.transcribe('$input_file')
with open('$output_file', 'w') as f:
    f.write(result['text'])
" 2>/dev/null; then
            log_error "Python whisper transcription failed"
            return 1
        fi
    else
        log_error "No Whisper implementation found"
        return 1
    fi

    log_info "Local transcription completed"
}

# Function for OpenAI API transcription
use_openai_api() {
    local input_file="$1"
    local output_file="$2"

    log_info "Using OpenAI API backend"

    if [[ -z "$OPENAI_API_KEY" ]]; then
        log_error "OpenAI API key not configured"
        return 1
    fi

    log_info "Transcribing with OpenAI API"
    local response
    response=$(curl -X POST "https://api.openai.com/v1/audio/transcriptions" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: multipart/form-data" \
        -F "file=@$input_file" \
        -F "model=whisper-1" \
        -F "response_format=text" \
        --fail --show-error --silent 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        log_error "OpenAI API transcription failed"
        return 1
    fi

    echo "$response" > "$output_file"
    log_info "OpenAI transcription completed"
}

# Function for Router API transcription
use_router_api() {
    local input_file="$1"
    local output_file="$2"

    log_info "Using Router API backend"

    if [[ -z "$ROUTER_API_KEY" ]]; then
        log_error "Router API key not configured"
        return 1
    fi

    log_info "Transcribing with Router API: $ROUTER_MODEL"
    local response
    response=$(curl -X POST "${ROUTER_BASE_URL}/audio/transcriptions" \
        -H "Authorization: Bearer $ROUTER_API_KEY" \
        -H "HTTP-Referer: https://github.com/Khamel83/relayq" \
        -H "X-Title: RelayQ" \
        -H "Content-Type: multipart/form-data" \
        -F "file=@$input_file" \
        -F "model=$ROUTER_MODEL" \
        -F "response_format=text" \
        --fail --show-error --silent 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        log_error "Router API transcription failed"
        return 1
    fi

    echo "$response" > "$output_file"
    log_info "Router transcription completed"
}

# Main transcription function
transcribe_audio() {
    local url="$1"
    local backend="${2:-$ASR_BACKEND}"

    # Validate inputs
    if [[ -z "$url" ]]; then
        log_error "URL is required"
        return 1
    fi

    validate_url "$url"

    # Create temporary directory
    TEMP_DIR=$(mktemp -d -t relayq-transcribe-XXXXXX)
    chmod 700 "$TEMP_DIR"

    log_info "Starting transcription for: $url"
    log_info "Using backend: $backend"

    # Download audio file
    local audio_file
    if ! audio_file=$(download_file "$url" "$TEMP_DIR"); then
        return 1
    fi

    # Convert to required format (WAV for local, MP3 for APIs)
    local converted_file="${TEMP_DIR}/converted.wav"
    if [[ "$backend" == "local" ]]; then
        if ! convert_audio "$audio_file" "$converted_file"; then
            return 1
        fi
        audio_file="$converted_file"
    fi

    # Generate output filename
    local input_basename=$(basename "$url")
    input_basename="${input_basename%.*}"  # Remove extension
    local output_file="${OUTPUT_DIR}/${input_basename}-transcript.txt"

    # Transcribe based on backend
    case "$backend" in
        "local")
            if ! use_local_whisper "$audio_file" "$output_file"; then
                return 1
            fi
            ;;
        "openai")
            if ! use_openai_api "$audio_file" "$output_file"; then
                return 1
            fi
            ;;
        "router")
            if ! use_router_api "$audio_file" "$output_file"; then
                return 1
            fi
            ;;
        *)
            log_error "Unknown backend: $backend"
            return 1
            ;;
    esac

    # Verify output file was created
    if [[ ! -f "$output_file" || ! -s "$output_file" ]]; then
        log_error "Transcription output file is empty or missing: $output_file"
        return 1
    fi

    log_info "Transcription completed successfully"
    echo "$output_file"
}

# Main execution
main() {
    local url="$1"
    local backend="${2:-$ASR_BACKEND}"

    # Check required dependencies
    if ! check_ffmpeg; then
        return 1
    fi

    # Perform transcription
    local output_file
    if output_file=$(transcribe_audio "$url" "$backend"); then
        echo "$output_file"
        exit 0
    else
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        log_error "Usage: $0 <url> [backend]"
        log_error "Backends: local, openai, router"
        exit 1
    fi

    main "$@"
fi