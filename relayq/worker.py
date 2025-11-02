"""Worker entry point"""

import sys
from celery import Celery
from celery.bin import worker

def main():
    """Start worker"""
    app = Celery("relayq")
    app.config_from_object("relayq.celeryconfig")

    # Import tasks to register them
    from . import tasks

    # Start worker
    worker_instance = worker.worker(app=app)
    worker_instance.run(
        loglevel="info",
        concurrency=2,
        hostname="macmini@%h",
    )

if __name__ == "__main__":
    main()