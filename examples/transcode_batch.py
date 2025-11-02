#!/usr/bin/env python3
"""
Transcode all MP4 files in a folder.

Usage: python transcode_batch.py /path/to/videos/
"""

import sys
import glob
from pathlib import Path
from relayq import job

def main():
    if len(sys.argv) < 2:
        print("Usage: python transcode_batch.py /path/to/videos/")
        sys.exit(1)

    folder = sys.argv[1]
    videos = glob.glob(f"{folder}/*.mp4")

    if not videos:
        print(f"No MP4 files found in {folder}")
        sys.exit(1)

    print(f"Found {len(videos)} videos")
    print("Submitting jobs...\n")

    jobs = []
    for video in videos:
        output = video.replace(".mp4", "_compressed.mp4")
        print(f"  → {Path(video).name}")
        j = job.transcode(video, output=output)
        jobs.append((video, j))

    print(f"\n{len(jobs)} jobs submitted. Waiting...\n")

    for i, (video, j) in enumerate(jobs, 1):
        print(f"[{i}/{len(jobs)}] Processing {Path(video).name}...", end=" ", flush=True)
        j.wait()
        print("✓")

    print("\n✓ All videos transcoded!")

if __name__ == "__main__":
    main()