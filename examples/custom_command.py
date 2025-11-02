#!/usr/bin/env python3
"""
Run a custom command on Mac Mini.

Usage: python custom_command.py
"""

from relayq import job

def main():
    # Example: Run any shell command
    print("Running custom command on Mac Mini...")

    result = job.run("uname -a && uptime")
    output = result.get()

    print("\nOutput:")
    print(output)

if __name__ == "__main__":
    main()