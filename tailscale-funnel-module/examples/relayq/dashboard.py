#!/usr/bin/env python3
"""
RelayQ Public Dashboard
Shows job status, runner health, and recent completions via public URL

Usage:
    python dashboard.py

Access:
    Local: http://localhost:8000
    Public: https://machine.ts.net:8000 (after enabling Funnel)
"""

import os
import subprocess
import json
from datetime import datetime
from flask import Flask, jsonify, render_template_string
from dotenv import load_dotenv

# Load environment variables from unified RelayQ config
ENV_FILE = os.path.expanduser('~/.config/relayq/env')
load_dotenv(ENV_FILE)

app = Flask(__name__)
BASE_URL = os.getenv('TAILSCALE_FUNNEL_BASE_URL', 'http://localhost:8000')
PORT = int(os.getenv('RELAYQ_DASHBOARD_PORT', 8000))

# HTML Template
HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>RelayQ Dashboard</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        h1 {
            color: #333;
        }
        .card {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .status-ok {
            color: #22c55e;
            font-weight: bold;
        }
        .status-error {
            color: #ef4444;
            font-weight: bold;
        }
        .job-item {
            border-bottom: 1px solid #eee;
            padding: 10px 0;
        }
        .job-item:last-child {
            border-bottom: none;
        }
        .runner-item {
            display: inline-block;
            margin: 10px;
            padding: 10px 20px;
            background: #e5e7eb;
            border-radius: 4px;
        }
        .runner-online {
            background: #d1fae5;
        }
        .runner-offline {
            background: #fee2e2;
        }
        pre {
            background: #1e293b;
            color: #e2e8f0;
            padding: 15px;
            border-radius: 4px;
            overflow-x: auto;
        }
        .refresh {
            float: right;
            padding: 8px 16px;
            background: #3b82f6;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }
        .refresh:hover {
            background: #2563eb;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 RelayQ Dashboard</h1>
        <p>Public URL: <strong>{{ base_url }}</strong></p>
        <button class="refresh" onclick="location.reload()">Refresh</button>

        <div class="card">
            <h2>System Status</h2>
            <p>Status: <span class="status-ok">✓ Online</span></p>
            <p>Last Updated: <span id="timestamp">{{ timestamp }}</span></p>
        </div>

        <div class="card">
            <h2>Active Runners</h2>
            <div id="runners">
                <p>Loading...</p>
            </div>
        </div>

        <div class="card">
            <h2>Recent Jobs</h2>
            <div id="jobs">
                <p>Loading...</p>
            </div>
        </div>

        <div class="card">
            <h2>API Endpoints</h2>
            <ul>
                <li><a href="/api/health">/api/health</a> - Health check</li>
                <li><a href="/api/runners">/api/runners</a> - Runner status (JSON)</li>
                <li><a href="/api/jobs">/api/jobs</a> - Recent jobs (JSON)</li>
            </ul>
        </div>
    </div>

    <script>
        // Auto-refresh every 30 seconds
        setTimeout(() => location.reload(), 30000);

        // Load runners
        fetch('/api/runners')
            .then(r => r.json())
            .then(data => {
                const html = data.runners.map(r =>
                    `<div class="runner-item runner-${r.status}">
                        ${r.name} - ${r.status}
                    </div>`
                ).join('');
                document.getElementById('runners').innerHTML = html || '<p>No runners found</p>';
            })
            .catch(e => {
                document.getElementById('runners').innerHTML = '<p class="status-error">Error loading runners</p>';
            });

        // Load jobs
        fetch('/api/jobs')
            .then(r => r.json())
            .then(data => {
                const html = data.jobs.map(j =>
                    `<div class="job-item">
                        <strong>${j.name}</strong> - ${j.status}<br>
                        <small>${j.updated_at}</small>
                    </div>`
                ).join('');
                document.getElementById('jobs').innerHTML = html || '<p>No recent jobs</p>';
            })
            .catch(e => {
                document.getElementById('jobs').innerHTML = '<p class="status-error">Error loading jobs</p>';
            });
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    """Dashboard homepage"""
    return render_template_string(
        HTML_TEMPLATE,
        base_url=BASE_URL,
        timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    )

@app.route('/health')
@app.route('/api/health')
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
        "base_url": BASE_URL
    })

@app.route('/api/runners')
def runners():
    """Get runner status from GitHub API"""
    try:
        result = subprocess.run(
            ['gh', 'api', 'repos/Khamel83/relayq/actions/runners'],
            capture_output=True,
            text=True,
            timeout=10
        )

        if result.returncode == 0:
            data = json.loads(result.stdout)
            runners_list = [
                {
                    "name": r.get('name', 'Unknown'),
                    "status": "online" if r.get('status') == 'online' else "offline",
                    "busy": r.get('busy', False),
                    "labels": [l['name'] for l in r.get('labels', [])]
                }
                for r in data.get('runners', [])
            ]
            return jsonify({"runners": runners_list})
        else:
            return jsonify({"error": "Failed to fetch runners", "runners": []}), 500
    except subprocess.TimeoutExpired:
        return jsonify({"error": "Request timeout", "runners": []}), 504
    except Exception as e:
        return jsonify({"error": str(e), "runners": []}), 500

@app.route('/api/jobs')
def jobs():
    """Get recent workflow runs from GitHub API"""
    try:
        result = subprocess.run(
            ['gh', 'api', 'repos/Khamel83/relayq/actions/runs', '--paginate', '-q', '.workflow_runs[:10]'],
            capture_output=True,
            text=True,
            timeout=10
        )

        if result.returncode == 0:
            data = json.loads(result.stdout)
            jobs_list = [
                {
                    "id": j.get('id'),
                    "name": j.get('name', 'Unknown'),
                    "status": j.get('status', 'unknown'),
                    "conclusion": j.get('conclusion'),
                    "created_at": j.get('created_at'),
                    "updated_at": j.get('updated_at'),
                    "html_url": j.get('html_url')
                }
                for j in (data if isinstance(data, list) else [])
            ]
            return jsonify({"jobs": jobs_list})
        else:
            return jsonify({"error": "Failed to fetch jobs", "jobs": []}), 500
    except subprocess.TimeoutExpired:
        return jsonify({"error": "Request timeout", "jobs": []}), 504
    except Exception as e:
        return jsonify({"error": str(e), "jobs": []}), 500

@app.route('/api/submit', methods=['POST'])
def submit_job():
    """
    Submit a transcription job

    Example:
        curl -X POST https://machine.ts.net:8000/api/submit \
          -H "Content-Type: application/json" \
          -d '{"url": "https://example.com/audio.mp3", "backend": "local"}'
    """
    from flask import request

    data = request.json
    if not data or 'url' not in data:
        return jsonify({"error": "Missing required field: url"}), 400

    url = data['url']
    backend = data.get('backend', 'local')

    try:
        result = subprocess.run(
            ['./bin/dispatch.sh', '.github/workflows/transcribe_audio.yml',
             f'url={url}', f'backend={backend}'],
            capture_output=True,
            text=True,
            cwd=os.path.expanduser('~/relayq'),
            timeout=30
        )

        if result.returncode == 0:
            return jsonify({
                "status": "submitted",
                "url": url,
                "backend": backend,
                "output": result.stdout
            })
        else:
            return jsonify({
                "error": "Job submission failed",
                "stderr": result.stderr
            }), 500
    except subprocess.TimeoutExpired:
        return jsonify({"error": "Submission timeout"}), 504
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    print(f"Starting RelayQ Dashboard on port {PORT}")
    print(f"Base URL: {BASE_URL}")
    print(f"Config file: {ENV_FILE}")
    print(f"Health check: http://0.0.0.0:{PORT}/health")
    print(f"\nIMPORTANT: Make sure 'gh' CLI is authenticated!")
    print(f"Run: gh auth login\n")

    app.run(host='0.0.0.0', port=PORT, debug=True)
