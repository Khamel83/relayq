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

    def run(self, command, cwd=None, worker=None):
        """Run a shell command on any available worker

        Args:
            command: Shell command to run
            cwd: Working directory (optional)
            worker: Specific worker to target (optional)
        """
        kwargs = {"cwd": cwd}
        if worker:
            kwargs["routing_key"] = worker

        result = app.send_task(
            "relayq.run_command",
            args=[command],
            kwargs=kwargs,
            routing_key=worker if worker else None
        )
        return JobResult(result)

    def run_on_mac(self, command, cwd=None):
        """Run command specifically on Mac Mini"""
        return self.run(command, cwd=cwd, worker="mac-mini")

    def run_on_rpi(self, command, cwd=None):
        """Run command specifically on RPi4"""
        return self.run(command, cwd=cwd, worker="rpi4-worker")

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
    """Get detailed multi-worker status"""
    try:
        inspect = app.control.inspect()
        active = inspect.active() or {}
        scheduled = inspect.scheduled() or {}
        stats = inspect.stats() or {}

        workers = {}
        total_active = 0
        total_scheduled = 0

        for worker_name in active.keys():
            worker_active = len(active.get(worker_name, []))
            worker_scheduled = len(scheduled.get(worker_name, []))
            worker_stats = stats.get(worker_name, {})

            # Determine worker type from hostname
            worker_type = "unknown"
            if "mac" in worker_name.lower() or "macmini" in worker_name.lower():
                worker_type = "mac-mini"
            elif "rpi" in worker_name.lower():
                worker_type = "rpi4"

            workers[worker_name] = {
                "type": worker_type,
                "active_jobs": worker_active,
                "queued_jobs": worker_scheduled,
                "total_jobs": worker_stats.get("total", {}).get("relayq.run_command", 0),
                "online": True
            }

            total_active += worker_active
            total_scheduled += worker_scheduled

        return {
            "online": len(workers) > 0,
            "total_workers": len(workers),
            "total_active": total_active,
            "total_queued": total_scheduled,
            "workers": workers
        }
    except Exception as e:
        return {
            "online": False,
            "error": str(e),
            "workers": {}
        }