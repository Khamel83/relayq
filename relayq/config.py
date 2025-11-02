"""Configuration management"""

import os
import yaml
from pathlib import Path

CONFIG_DIR = Path.home() / ".relayq"
CONFIG_FILE = CONFIG_DIR / "config.yml"

DEFAULT_CONFIG = {
    "broker": {
        "host": "127.0.0.1",
        "port": 6379,
        "db": 0,
    },
    "worker": {
        "priority": "low",
        "max_concurrent": 2,
        "cpu_threshold": 80,
    },
    "logging": {
        "level": "INFO",
        "file": str(CONFIG_DIR / "worker.log"),
    },
}


def load_config():
    """Load config from file or return defaults"""
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE) as f:
            return yaml.safe_load(f)
    return DEFAULT_CONFIG


def get_broker_url():
    """Get Redis broker URL"""
    config = load_config()
    broker = config["broker"]
    return f"redis://{broker['host']}:{broker['port']}/{broker['db']}"