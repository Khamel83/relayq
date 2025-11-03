#!/usr/bin/env python3
"""
RelayQ Target Selection Script

Selects the appropriate workflow file based on policy.yaml and job parameters.
"""

import sys
import json
import yaml
import os
from typing import Dict, List, Optional, Any

def load_policy(policy_path: str = "policy/policy.yaml") -> Dict[str, Any]:
    """Load routing policy from YAML file"""
    try:
        with open(policy_path, 'r') as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        print(f"Error: Policy file not found: {policy_path}", file=sys.stderr)
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"Error parsing policy file: {e}", file=sys.stderr)
        sys.exit(1)

def evaluate_constraints(constraints: Dict[str, Any], job_params: Dict[str, Any]) -> bool:
    """Check if job meets all constraints"""

    # Check file size constraint
    if 'max_size_mb' in constraints:
        job_size = job_params.get('size_mb', 0)
        if job_size > constraints['max_size_mb']:
            return False

    # Check memory constraint (would need runner info in real implementation)
    if 'min_memory_gb' in constraints:
        # For now, assume we meet memory requirements
        pass

    # Check FFmpeg requirement
    if 'needs_ffmpeg' in constraints and constraints['needs_ffmpeg']:
        # Assume runners have FFmpeg installed per setup docs
        pass

    return True

def select_workflow(job_type: str, job_params: Dict[str, Any], policy: Dict[str, Any]) -> Optional[str]:
    """Select appropriate workflow based on policy"""

    if job_type not in policy.get('routes', {}):
        print(f"Error: Unknown job type: {job_type}", file=sys.stderr)
        return None

    route = policy['routes'][job_type]

    # First, check if job meets constraints
    if not evaluate_constraints(route.get('constraints', {}), job_params):
        print(f"Error: Job does not meet route constraints for {job_type}", file=sys.stderr)
        return None

    # Determine workflow based on preferences and fallbacks
    prefer = route.get('prefer', [])
    fallback = route.get('fallback', [])

    # If no specific preferences, use pooled workflow
    if not prefer and not fallback:
        return ".github/workflows/transcribe_audio.yml"

    # Check preferences for specific runner targeting
    if prefer:
        for runner in prefer:
            if runner == 'macmini':
                return ".github/workflows/transcribe_mac.yml"
            elif runner == 'rpi4':
                return ".github/workflows/transcribe_rpi.yml"
            elif runner == 'rpi3':
                # RPi3 would use a very light workflow if we had one
                return ".github/workflows/transcribe_rpi.yml"  # Fallback to RPi4 workflow

    # Check fallbacks
    if fallback:
        for runner in fallback:
            if runner == 'rpi4':
                return ".github/workflows/transcribe_rpi.yml"
            elif runner == 'macmini':
                return ".github/workflows/transcribe_mac.yml"

    # Default to pooled workflow
    return ".github/workflows/transcribe_audio.yml"

def main():
    """Main entry point"""

    if len(sys.argv) < 2:
        print("Usage: select_target.py <job_type> [job_params_json]", file=sys.stderr)
        print("Example: select_target.py transcribe '{\"url\": \"https://example.com/file.mp3\", \"size_mb\": 50}'", file=sys.stderr)
        sys.exit(1)

    job_type = sys.argv[1]
    job_params = {}

    # Parse job parameters if provided
    if len(sys.argv) > 2:
        try:
            job_params = json.loads(sys.argv[2])
        except json.JSONDecodeError as e:
            print(f"Error parsing job parameters: {e}", file=sys.stderr)
            sys.exit(1)

    # Load policy
    policy_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'policy', 'policy.yaml')
    policy = load_policy(policy_path)

    # Select workflow
    workflow = select_workflow(job_type, job_params, policy)

    if workflow:
        print(workflow)
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()