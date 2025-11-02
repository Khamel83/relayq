# Examples

Copy-paste these complete scripts. They just work.

## Example 1: Transcode All Videos in Folder

```python
#!/usr/bin/env python3
"""
Transcode all MP4 files in a folder to H.264 with lower bitrate.

Usage: python transcode_all_videos.py /path/to/videos/
"""

import sys
import glob
from pathlib import Path
from relayq import job

def main():
    if len(sys.argv) < 2:
        print("Usage: python transcode_all_videos.py /path/to/videos/")
        sys.exit(1)

    folder = sys.argv[1]
    videos = glob.glob(f"{folder}/*.mp4")

    if not videos:
        print(f"No MP4 files found in {folder}")
        sys.exit(1)

    print(f"Found {len(videos)} videos. Starting transcode...")

    jobs = []
    for video in videos:
        output = video.replace(".mp4", "_compressed.mp4")
        print(f"Submitting: {Path(video).name}")
        j = job.transcode(video, output=output, options="-c:v libx264 -crf 23")
        jobs.append((video, j))

    print(f"\n{len(jobs)} jobs submitted. Waiting for completion...")

    for video, j in jobs:
        print(f"Processing: {Path(video).name}...", end=" ")
        j.wait()
        print("✓")

    print("\nAll done!")

if __name__ == "__main__":
    main()
```

## Example 2: Transcribe Podcast

```python
#!/usr/bin/env python3
"""
Transcribe an audio file using Whisper on Mac Mini.

Usage: python transcribe_podcast.py podcast.mp3
"""

import sys
from pathlib import Path
from relayq import job

def main():
    if len(sys.argv) < 2:
        print("Usage: python transcribe_podcast.py audio.mp3")
        sys.exit(1)

    audio_file = sys.argv[1]

    if not Path(audio_file).exists():
        print(f"Error: {audio_file} not found")
        sys.exit(1)

    print(f"Transcribing: {audio_file}")
    print("This may take a while...\n")

    result = job.transcribe(audio_file)
    transcript = result.get()

    # Save transcript
    output_file = Path(audio_file).stem + "_transcript.txt"
    with open(output_file, "w") as f:
        f.write(transcript)

    print(f"✓ Transcript saved to: {output_file}")

if __name__ == "__main__":
    main()
```

## Example 3: Batch Process with Progress

```python
#!/usr/bin/env python3
"""
Process multiple files with progress tracking.

Usage: python batch_process.py /path/to/files/*.mp4
"""

import sys
import time
from pathlib import Path
from relayq import job

def main():
    if len(sys.argv) < 2:
        print("Usage: python batch_process.py file1.mp4 file2.mp4 ...")
        sys.exit(1)

    files = sys.argv[1:]

    print(f"Submitting {len(files)} jobs...")
    jobs = []

    for f in files:
        j = job.transcode(f, output=f.replace(".mp4", "_processed.mp4"))
        jobs.append((Path(f).name, j))

    print("\nProcessing (checking every 10 seconds)...\n")

    while True:
        completed = sum(1 for _, j in jobs if j.ready())
        failed = sum(1 for _, j in jobs if j.failed())
        running = len(jobs) - completed - failed

        print(f"Completed: {completed}/{len(jobs)} | Running: {running} | Failed: {failed}")

        if completed + failed == len(jobs):
            break

        time.sleep(10)

    print("\n" + "="*50)
    if failed > 0:
        print("Some jobs failed:")
        for name, j in jobs:
            if j.failed():
                print(f"  ✗ {name}")
    else:
        print("✓ All jobs completed successfully!")

if __name__ == "__main__":
    main()
```

## Example 4: Custom Command

```python
#!/usr/bin/env python3
"""
Run a custom command on Mac Mini.

Usage: python custom_command.py
"""

from relayq import job

def main():
    # Run any shell command
    result = job.run("python my_script.py --input data.csv")

    # Wait and get output
    output = result.get()
    print(output)

if __name__ == "__main__":
    main()
```

## Example 5: Check If Worker Is Available

```python
#!/usr/bin/env python3
"""
Check if Mac Mini worker is online before submitting jobs.
"""

from relayq import worker_status

def main():
    status = worker_status()

    if status['online']:
        print(f"✓ Worker online")
        print(f"  Active jobs: {status['active']}")
        print(f"  Queued jobs: {status['queued']}")
    else:
        print("✗ Worker offline")
        print("  Jobs will queue until worker comes online")

if __name__ == "__main__":
    main()
```

## Copy These

These are complete, working scripts. Copy the entire file and run it.

All examples assume files are on Mac Mini. If files are on OCI VM, you'll need to copy them first (or mount Mac Mini's filesystem).