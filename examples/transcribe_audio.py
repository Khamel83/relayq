#!/usr/bin/env python3
"""
Transcribe audio file using Whisper.

Usage: python transcribe_audio.py audio.mp3
"""

import sys
from pathlib import Path
from relayq import job

def main():
    if len(sys.argv) < 2:
        print("Usage: python transcribe_audio.py audio.mp3")
        sys.exit(1)

    audio_file = sys.argv[1]

    if not Path(audio_file).exists():
        print(f"Error: {audio_file} not found")
        sys.exit(1)

    print(f"Transcribing: {audio_file}")
    print("This may take several minutes...\n")

    result = job.transcribe(audio_file)
    transcript = result.get()

    output_file = Path(audio_file).stem + "_transcript.txt"
    with open(output_file, "w") as f:
        f.write(transcript)

    print(f"✓ Transcript saved to: {output_file}")
    print(f"\nPreview:\n{transcript[:500]}...")

if __name__ == "__main__":
    main()