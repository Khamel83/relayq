#!/bin/bash
# RelayQ Job Dispatch Script
# Triggers GitHub Actions workflows from OCI VM

set -euo pipefail

# Default values
WORKFLOW_FILE=".github/workflows/transcribe_audio.yml"
REPO="Khamel83/relayq"
DRY_RUN=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Help function
show_help() {
    cat << EOF
RelayQ Job Dispatch Script

USAGE:
    $0 [OPTIONS] [WORKFLOW_FILE] [KEY=VALUE ...]

OPTIONS:
    -h, --help          Show this help message
    -d, --dry-run       Show command without executing
    -v, --verbose       Enable verbose output
    -r, --repo REPO     Repository name (default: Khamel83/relayq)

EXAMPLES:
    # Basic transcription job
    $0 .github/workflows/transcribe_audio.yml url=https://example.com/audio.mp3

    # Force Mac mini execution
    $0 .github/workflows/transcribe_mac.yml url=https://example.com/large.mp3

    # With additional parameters
    $0 .github/workflows/transcribe_audio.yml url=https://example.com/audio.mp3 backend=local model=base

    # Dry run to preview command
    $0 --dry-run .github/workflows/transcribe_audio.yml url=https://example.com/test.mp3

WORKFLOW FILES:
    .github/workflows/transcribe_audio.yml    # Pooled (Mac or RPi4)
    .github/workflows/transcribe_mac.yml      # Mac mini only
    .github/workflows/transcribe_rpi.yml      # RPi4 only

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -r|--repo)
                REPO="$2"
                shift 2
                ;;
            *.yml|*.yaml)
                WORKFLOW_FILE="$1"
                shift
                ;;
            *=*)
                # Workflow parameters (key=value format)
                PARAMS+=("$1")
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use -h for help"
                exit 1
                ;;
        esac
    done
}

# Validate inputs
validate_inputs() {
    # Check if workflow file exists
    if [[ ! -f "$WORKFLOW_FILE" ]]; then
        log_error "Workflow file not found: $WORKFLOW_FILE"
        exit 1
    fi

    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed or not in PATH"
        log_error "Install with: sudo apt install gh"
        exit 1
    fi

    # Check if authenticated with GitHub
    if ! gh auth status &> /dev/null; then
        log_error "Not authenticated with GitHub"
        log_error "Run: gh auth login"
        exit 1
    fi

    # Validate workflow file format
    if [[ ! "$WORKFLOW_FILE" =~ \.ya?ml$ ]]; then
        log_error "Workflow file must be a YAML file (.yml or .yaml)"
        exit 1
    fi
}

# Build GitHub CLI command
build_command() {
    local cmd="gh workflow run \"$WORKFLOW_FILE\""

    # Add repository if different from default
    if [[ "$REPO" != "Khamel83/relayq" ]]; then
        cmd="$cmd --repo $REPO"
    fi

    # Add parameters
    for param in "${PARAMS[@]}"; do
        if [[ "$param" =~ ^([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            cmd="$cmd -f $key=\"$value\""
        else
            log_error "Invalid parameter format: $param (expected key=value)"
            exit 1
        fi
    done

    echo "$cmd"
}

# Execute workflow
execute_workflow() {
    local cmd=$(build_command)

    if [[ "$VERBOSE" == true ]] || [[ "$DRY_RUN" == true ]]; then
        log_info "Command: $cmd"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "Dry run - not executing workflow"
        return 0
    fi

    log_info "Executing workflow: $WORKFLOW_FILE"
    if [[ ${#PARAMS[@]} -gt 0 ]]; then
        log_info "Parameters: ${PARAMS[*]}"
    fi

    # Execute the command and capture output
    local output
    if output=$(eval "$cmd" 2>&1); then
        log_info "Workflow submitted successfully"

        # Extract run URL from output if available
        local run_url=$(echo "$output" | grep -o 'https://github.com/.*/actions/runs/[0-9]*' | head -1)
        if [[ -n "$run_url" ]]; then
            log_info "Run URL: $run_url"
            echo "$run_url"
        else
            log_warn "Could not extract run URL from output"
            log_info "Check repository Actions tab for job status"
        fi

        return 0
    else
        log_error "Failed to submit workflow"
        log_error "Output: $output"
        return 1
    fi
}

# Main execution
main() {
    local PARAMS=()

    parse_args "$@"
    validate_inputs

    # Change to repository root directory
    cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

    log_info "Repository: $REPO"
    log_info "Workflow: $WORKFLOW_FILE"

    execute_workflow
}

# Run main function with all arguments
main "$@"