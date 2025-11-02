#!/usr/bin/env python3
"""
Transcode a single video file.

Usage: python transcode_video.py input.mp4
"""

import sys
from pathlib import Path
from relayq import job

def main():
    if len(sys.argv) < 2:
        print("Usage: python transcode_video.py input.mp4")
        sys.exit(1)

    input_file = sys.argv[1]

    if not Path(input_file).exists():
        print(f"Error: {input_file} not found")
        sys.exit(1)

    output_file = input_file.replace(".mp4", "_compressed.mp4")

    print(f"Transcoding: {input_file}")
    print(f"Output will be: {output_file}")
    print("This will run on Mac Mini...\n")

    result = job.transcode(input_file, output=output_file)

    print("Job submitted. Waiting for completion...")
    result.wait()

    print(f"✓ Done! Output: {output_file}")

if __name__ == "__main__":
    main()