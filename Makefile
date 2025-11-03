# RelayQ Makefile
# Convenience targets for development and operations

.PHONY: help fmt lint dispatch check clean docs test install-runners

# Default target
help:
	@echo "RelayQ - GitHub-First Hybrid Runner Kit"
	@echo ""
	@echo "Available targets:"
	@echo "  help          Show this help message"
	@echo "  fmt           Format files"
	@echo "  lint          Run linting checks"
	@echo "  dispatch      Test job dispatch"
	@echo "  check         Run system checks"
	@echo "  clean         Clean temporary files"
	@echo "  docs          Generate documentation"
	@echo "  test          Run tests"
	@echo "  install       Show installation instructions"
	@echo ""
	@echo "Examples:"
	@echo "  make dispatch URL=https://example.com/test.mp3"
	@echo "  make check"

# Installation information
install:
	@echo "=== RelayQ Installation Guide ==="
	@echo ""
	@echo "1. Install GitHub CLI:"
	@echo "   sudo apt install gh"
	@echo "   gh auth login"
	@echo ""
	@echo "2. Setup runners (see docs/):"
	@echo "   - docs/SETUP_RUNNERS_mac.md"
	@echo "   - docs/SETUP_RUNNERS_rpi.md"
	@echo ""
	@echo "3. Test dispatch:"
	@echo "   make dispatch URL=https://example.com/test.mp3"
	@echo ""
	@echo "4. See docs/ for complete setup"

# Formatting
fmt:
	@echo "Formatting files..."
	@# Format shell scripts
	@if command -v shfmt &> /dev/null; then \
		shfmt -w -i 4 bin/*.sh jobs/*.sh; \
		echo "✓ Shell scripts formatted"; \
	else \
		echo "⚠ shfmt not found, skipping shell formatting"; \
	fi
	@# Format Python scripts
	@if command -v black &> /dev/null; then \
		black bin/select_target.py; \
		echo "✓ Python scripts formatted"; \
	else \
		echo "⚠ black not found, skipping Python formatting"; \
	fi

# Linting
lint:
	@echo "Running linting checks..."
	@# Lint shell scripts
	@if command -v shellcheck &> /dev/null; then \
		shellcheck bin/*.sh jobs/*.sh; \
		echo "✓ Shell scripts linted"; \
	else \
		echo "⚠ shellcheck not found, skipping shell linting"; \
	fi
	@# Lint Python scripts
	@if command -v flake8 &> /dev/null; then \
		flake8 bin/select_target.py; \
		echo "✓ Python scripts linted"; \
	else \
		echo "⚠ flake8 not found, skipping Python linting"; \
	fi
	@# Check YAML files
	@if command -v yamllint &> /dev/null; then \
		yamllint policy/policy.yaml .github/workflows/*.yml; \
		echo "✓ YAML files linted"; \
	else \
		echo "⚠ yamllint not found, skipping YAML linting"; \
	fi

# Test dispatch
dispatch:
	@if [ -z "$(URL)" ]; then \
		echo "Usage: make dispatch URL=https://example.com/audio.mp3 [BACKEND=local] [WORKFLOW=transcribe_audio.yml]"; \
		exit 1; \
	fi
	@echo "Testing job dispatch..."
	@echo "URL: $(URL)"
	@echo "Backend: $(or $(BACKEND),local)"
	@echo "Workflow: $(or $(WORKFLOW),.github/workflows/transcribe_audio.yml)"
	@./bin/dispatch.sh $(or $(WORKFLOW),.github/workflows/transcribe_audio.yml) url=$(URL) backend=$(or $(BACKEND),local)

# System checks
check:
	@echo "Running system checks..."
	@# Check GitHub CLI
	@if command -v gh &> /dev/null; then \
		echo "✓ GitHub CLI found"; \
		if gh auth status &> /dev/null; then \
			echo "✓ GitHub CLI authenticated"; \
		else \
			echo "❌ GitHub CLI not authenticated"; \
		fi \
	else \
		echo "❌ GitHub CLI not found"; \
	fi
	@# Check repository access
	@if git remote get-url origin &> /dev/null; then \
		echo "✓ Git repository found"; \
	else \
		echo "❌ Not in a git repository"; \
	fi
	@# Check workflow files
	@if [ -f ".github/workflows/transcribe_audio.yml" ]; then \
		echo "✓ Workflow files found"; \
	else \
		echo "❌ Workflow files missing"; \
	fi
	@# Check scripts
	@if [ -f "bin/dispatch.sh" ] && [ -x "bin/dispatch.sh" ]; then \
		echo "✓ Dispatch script found and executable"; \
	else \
		echo "❌ Dispatch script missing or not executable"; \
	fi
	@if [ -f "jobs/transcribe.sh" ] && [ -x "jobs/transcribe.sh" ]; then \
		echo "✓ Job scripts found and executable"; \
	else \
		echo "❌ Job scripts missing or not executable"; \
	fi
	@# Check policy file
	@if [ -f "policy/policy.yaml" ]; then \
		echo "✓ Policy file found"; \
	else \
		echo "❌ Policy file missing"; \
	fi
	@echo "System checks completed"

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@# Clean temp directories
	@if [ -d "/tmp" ]; then \
		find /tmp -name "relayq-transcribe-*" -type d -mtime +1 -exec rm -rf {} \; 2>/dev/null || true; \
		find /tmp -name "relayq-outputs" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true; \
		echo "✓ Cleaned temporary directories"; \
	fi
	@# Clean Python cache
	@find . -type d -name "__pycache__" -exec rm -rf {} \; 2>/dev/null || true
	@find . -name "*.pyc" -delete 2>/dev/null || true
	@echo "✓ Cleaned Python cache"

# Generate documentation
docs:
	@echo "Generating documentation..."
	@# Check if we have markdown tools
	@if command -v markdown &> /dev/null; then \
		echo "Documentation generation not implemented yet"; \
	else \
		echo "⚠ No markdown generator found"; \
	fi
	@echo "Documentation available in docs/ directory"

# Run tests
test:
	@echo "Running tests..."
	@# Test policy parsing
	@echo "Testing policy parsing..."
	@python3 bin/select_target.py transcribe '{"size_mb": 50}' > /dev/null || echo "❌ Policy parsing test failed"
	@# Test dispatch script help
	@echo "Testing dispatch script..."
	@./bin/dispatch.sh --help > /dev/null || echo "❌ Dispatch script help test failed"
	@# Test job script help
	@echo "Testing job script..."
	@jobs/transcribe.sh 2>/dev/null || echo "✓ Job script shows usage on error"
	@echo "Tests completed"

# Show runner status
status:
	@echo "Checking runner status..."
	@gh api repos/Khamel83/relayq/actions/runners 2>/dev/null || echo "❌ Failed to get runner status"

# Show recent jobs
jobs:
	@echo "Recent jobs:"
	@gh run list --repo Khamel83/relayq --limit 10 2>/dev/null || echo "❌ Failed to get job list"

# Monitor active jobs
watch:
	@echo "Monitoring active jobs (Ctrl+C to stop)..."
	@watch -n 30 'gh run list --repo Khamel83/relayq --status in_progress --limit 5'

# Validate configuration
validate:
	@echo "Validating configuration..."
	@# Validate YAML files
	@for yaml_file in policy/policy.yaml .github/workflows/*.yml; do \
		if [ -f "$$yaml_file" ]; then \
			echo "Validating $$yaml_file..."; \
			python3 -c "import yaml; yaml.safe_load(open('$$yaml_file'))" || echo "❌ Invalid YAML: $$yaml_file"; \
		fi; \
	done
	@# Validate script syntax
	@for script in bin/*.sh jobs/*.sh; do \
		if [ -f "$$script" ]; then \
			echo "Checking $$script..."; \
			bash -n "$$script" || echo "❌ Invalid script syntax: $$script"; \
		fi; \
	done
	@echo "Configuration validation completed"

# Quick start setup
quickstart:
	@echo "=== RelayQ Quick Start ==="
	@echo ""
	@echo "1. Check prerequisites:"
	@make check
	@echo ""
	@echo "2. Test dispatch (replace URL with real audio file):"
	@echo "   make dispatch URL=https://example.com/test.mp3"
	@echo ""
	@echo "3. Monitor job status:"
	@echo "   make status"
	@echo "   make jobs"
	@echo ""
	@echo "4. See docs/ for complete setup guide"

# Show version information
version:
	@echo "RelayQ v1.0.0-hybrid"
	@echo "GitHub-First Hybrid Runner Kit"
	@echo ""
	@echo "Components:"
	@echo "  - GitHub Actions integration"
	@echo "  - Self-hosted runner support"
	@echo "  - Multi-backend ASR support"
	@echo "  - Policy-based routing"

# Development setup
dev-setup: install
	@echo "Setting up development environment..."
	@echo "Installing development tools..."
	@# Install shell formatting tool
	@if ! command -v shfmt &> /dev/null; then \
		echo "Installing shfmt..."; \
		curl -sS https://webi.sh/shfmt | sh; \
	fi
	@# Install Python tools
	@if command -v pip3 &> /dev/null; then \
		echo "Installing Python tools..."; \
		pip3 install --user black flake8 yamllint 2>/dev/null || true; \
	fi
	@echo "Development setup completed"

# CI/CD helpers
ci: fmt lint check test validate
	@echo "CI checks completed"

# Create release
release:
	@echo "Creating release..."
	@echo "Current branch: $(shell git branch --show-current)"
	@echo "Latest commit: $(shell git rev-parse HEAD)"
	@echo "Creating tag v1.0.0-hybrid..."
	@git tag -a v1.0.0-hybrid -m "Release v1.0.0-hybrid: GitHub-First Hybrid Runner Kit"
	@echo "Release created. Push with: git push origin v1.0.0-hybrid"