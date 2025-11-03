"""Task definitions"""

import subprocess
import os
from celery import Celery
from .celeryconfig import broker_url

app = Celery("relayq")
app.config_from_object("relayq.celeryconfig")


@app.task(bind=True, name="relayq.run_command")
def run_command(self, command, cwd=None):
    """Execute a shell command"""
    try:
        result = subprocess.run(
            command,
            shell=True,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=3600 * 5,
        )

        if result.returncode != 0:
            raise Exception(f"Command failed: {result.stderr}")

        return result.stdout

    except subprocess.TimeoutExpired:
        raise Exception("Command timed out after 5 hours")
    except Exception as e:
        raise Exception(f"Command execution failed: {str(e)}")


@app.task(bind=True, name="relayq.transcode_video")
def transcode_video(self, input_file, output_file, options=None):
    """Transcode video using ffmpeg"""
    if not os.path.exists(input_file):
        raise FileNotFoundError(f"Input file not found: {input_file}")

    if options is None:
        options = "-c:v libx264 -crf 23 -c:a aac"

    command = f"ffmpeg -i '{input_file}' {options} '{output_file}' -y"

    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=3600 * 5,
        )

        if result.returncode != 0:
            raise Exception(f"ffmpeg failed: {result.stderr}")

        return {"status": "success", "output": output_file}

    except subprocess.TimeoutExpired:
        raise Exception("Transcode timed out after 5 hours")
    except Exception as e:
        raise Exception(f"Transcode failed: {str(e)}")


@app.task(bind=True, name="relayq.transcribe_audio")
def transcribe_audio(self, audio_file, model="base"):
    """Transcribe audio using Whisper"""
    if not os.path.exists(audio_file):
        raise FileNotFoundError(f"Audio file not found: {audio_file}")

    # Check if whisper is installed
    try:
        subprocess.run(["whisper", "--version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        raise Exception("Whisper not installed. Run: pip install openai-whisper")

    output_dir = os.path.dirname(audio_file)
    command = f"whisper '{audio_file}' --model {model} --output_dir '{output_dir}' --output_format txt"

    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=3600 * 5,
        )

        if result.returncode != 0:
            raise Exception(f"Whisper failed: {result.stderr}")

        # Read transcript
        transcript_file = audio_file.rsplit(".", 1)[0] + ".txt"
        with open(transcript_file) as f:
            transcript = f.read()

        return transcript

    except subprocess.TimeoutExpired:
        raise Exception("Transcription timed out after 5 hours")
    except Exception as e:
        raise Exception(f"Transcription failed: {str(e)}")