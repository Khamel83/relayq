"""Celery configuration"""

from .config import get_broker_url

# Broker
broker_url = get_broker_url()
result_backend = broker_url

# Task settings
task_serializer = "json"
accept_content = ["json"]
result_serializer = "json"
timezone = "UTC"
enable_utc = True

# Task execution
task_track_started = True
task_time_limit = 3600 * 6  # 6 hours max
task_soft_time_limit = 3600 * 5  # 5 hours soft limit

# Worker settings
worker_prefetch_multiplier = 1
worker_max_tasks_per_child = 50

# Retry settings
task_acks_late = True
task_reject_on_worker_lost = True

# Result backend
result_expires = 3600 * 24  # Results expire after 24 hours