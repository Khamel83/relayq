from setuptools import setup, find_packages

setup(
    name="relayq",
    version="1.0.0",
    description="Personal compute orchestrator for OCI VM + Mac Mini",
    author="Omar Zoheri",
    packages=find_packages(),
    install_requires=[
        "celery[redis]>=5.3.0",
        "redis>=5.0.0",
    ],
    entry_points={
        "console_scripts": [
            "relayq-worker=relayq.worker:main",
        ],
    },
    python_requires=">=3.8",
)