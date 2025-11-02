"""Client interface for submitting jobs"""

from celery import Celery
from .celeryconfig import broker_url

app = Celery("relayq", broker=broker_url)
app.config_from_object("relayq.celeryconfig")


class JobResult:
    """Wrapper for Celery AsyncResult"""

    def __init__(self, async_result):
        self.result = async_result

    def ready(self):
        """Check if job is complete"""
        return self.result.ready()

    def failed(self):
        """Check if job failed"""
        return self.result.failed()

    def wait(self, timeout=None):
        """Wait for job to complete"""
        return self.result.get(timeout=timeout)

    def get(self, timeout=None):
        """Get result (blocks until complete)"""
        return self.result.get(timeout=timeout)

    @property
    def info(self):
        """Get job info/progress"""
        return self.result.info

    @property
    def traceback(self):
        """Get traceback if job failed"""
        return self.result.traceback


class Job:
    """Job submission interface"""

    def run(self, command, cwd=None):
        """Run a shell command on Mac Mini"""
        result = app.send_task(
            "relayq.run_command",
            args=[command],
            kwargs={"cwd": cwd}
        )
        return JobResult(result)

    def transcode(self, input_file, output=None, options=None):
        """Transcode video on Mac Mini"""
        if output is None:
            output = input_file.replace(".mp4", "_transcoded.mp4")

        result = app.send_task(
            "relayq.transcode_video",
            args=[input_file, output],
            kwargs={"options": options}
        )
        return JobResult(result)

    def transcribe(self, audio_file, model="base"):
        """Transcribe audio using Whisper on Mac Mini"""
        result = app.send_task(
            "relayq.transcribe_audio",
            args=[audio_file],
            kwargs={"model": model}
        )
        return JobResult(result)


# Global job instance
job = Job()


def worker_status():
    """Get worker status"""
    try:
        inspect = app.control.inspect()
        active = inspect.active()
        scheduled = inspect.scheduled()

        if active is None:
            return {"online": False}

        total_active = sum(len(tasks) for tasks in active.values())
        total_scheduled = sum(len(tasks) for tasks in (scheduled or {}).values())

        return {
            "online": True,
            "active": total_active,
            "queued": total_scheduled,
        }
    except Exception:
        return {"online": False}