# Security Considerations for Tailscale Funnel

## Overview

Tailscale Funnel provides transport security (HTTPS/TLS), but **you are responsible for application-level security**. This document outlines security best practices.

## Threat Model

### What Tailscale Protects Against

✅ **Network eavesdropping:** All traffic is encrypted (TLS + WireGuard)
✅ **Man-in-the-middle attacks:** Certificate validation is automatic
✅ **IP spoofing:** WireGuard authentication prevents this
✅ **DNS hijacking:** MagicDNS is cryptographically secured

### What You Must Protect Against

⚠️ **Unauthorized access:** Anyone with URL can access your app
⚠️ **Application vulnerabilities:** SQLi, XSS, CSRF, etc.
⚠️ **Rate limiting:** No built-in DDoS protection
⚠️ **Data leakage:** Your code must protect sensitive data
⚠️ **Input validation:** Malicious inputs can exploit your app

## Security Checklist

### Required for Production

- [ ] **Implement authentication** (API keys, OAuth, JWT, etc.)
- [ ] **Validate all inputs** (prevent injection attacks)
- [ ] **Rate limit requests** (prevent abuse)
- [ ] **Use HTTPS only** (Funnel does this automatically)
- [ ] **Keep dependencies updated** (security patches)
- [ ] **Enable logging** (audit trail)
- [ ] **Sanitize outputs** (prevent XSS)
- [ ] **Use environment variables for secrets** (never hardcode)

### Recommended

- [ ] **Implement CORS properly** (restrict origins)
- [ ] **Add request timeouts** (prevent resource exhaustion)
- [ ] **Use secure session management** (HttpOnly, Secure cookies)
- [ ] **Implement CSRF protection** (for web forms)
- [ ] **Add security headers** (CSP, X-Frame-Options, etc.)
- [ ] **Monitor for anomalies** (unusual traffic patterns)
- [ ] **Regular security audits** (review code, dependencies)

## Authentication Patterns

### Pattern 1: API Key Authentication

**Use for:** Machine-to-machine communication, APIs

```python
import os
import secrets
from functools import wraps
from flask import Flask, request, jsonify

app = Flask(__name__)

# Generate: python -c "import secrets; print(secrets.token_urlsafe(32))"
API_KEY = os.getenv('API_KEY', 'change-me-in-production')

def require_api_key(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        key = request.headers.get('X-API-Key')
        if not key or key != API_KEY:
            return jsonify({"error": "Unauthorized"}), 401
        return f(*args, **kwargs)
    return decorated

@app.route('/api/data')
@require_api_key
def get_data():
    return jsonify({"data": "secret information"})
```

**Usage:**
```bash
curl https://machine.ts.net/api/data \
  -H "X-API-Key: your-secret-key"
```

### Pattern 2: Bearer Token (JWT)

**Use for:** User authentication, session management

```python
import jwt
from datetime import datetime, timedelta
from functools import wraps
from flask import Flask, request, jsonify

app = Flask(__name__)
SECRET_KEY = os.getenv('JWT_SECRET', 'change-me')

def create_token(user_id):
    payload = {
        'user_id': user_id,
        'exp': datetime.utcnow() + timedelta(hours=24)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm='HS256')

def require_token(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
            request.user_id = payload['user_id']
        except jwt.ExpiredSignatureError:
            return jsonify({"error": "Token expired"}), 401
        except jwt.InvalidTokenError:
            return jsonify({"error": "Invalid token"}), 401
        return f(*args, **kwargs)
    return decorated

@app.route('/login', methods=['POST'])
def login():
    # Validate credentials (check database, etc.)
    user_id = authenticate_user(request.json)
    if user_id:
        token = create_token(user_id)
        return jsonify({"token": token})
    return jsonify({"error": "Invalid credentials"}), 401

@app.route('/api/protected')
@require_token
def protected():
    return jsonify({"user_id": request.user_id, "data": "secret"})
```

### Pattern 3: Basic Authentication

**Use for:** Simple admin interfaces, internal tools

```python
from functools import wraps
from flask import Flask, request
import base64

app = Flask(__name__)

USERS = {
    'admin': 'secure-password-here'  # Use hashed passwords in production!
}

def require_basic_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.headers.get('Authorization')
        if not auth or not auth.startswith('Basic '):
            return 'Unauthorized', 401, {'WWW-Authenticate': 'Basic realm="Login Required"'}

        try:
            credentials = base64.b64decode(auth[6:]).decode('utf-8')
            username, password = credentials.split(':', 1)
            if username in USERS and USERS[username] == password:
                return f(*args, **kwargs)
        except:
            pass

        return 'Unauthorized', 401, {'WWW-Authenticate': 'Basic realm="Login Required"'}
    return decorated

@app.route('/admin')
@require_basic_auth
def admin():
    return "Admin panel"
```

## Input Validation

### Always Validate and Sanitize

```python
from flask import Flask, request, jsonify
import re

app = Flask(__name__)

@app.route('/submit', methods=['POST'])
def submit():
    # Validate required fields
    data = request.json
    if not data or 'url' not in data:
        return jsonify({"error": "Missing required field: url"}), 400

    url = data['url']

    # Validate URL format
    url_pattern = re.compile(
        r'^https?://'  # http:// or https://
        r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|'  # domain
        r'localhost|'  # localhost
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # or IP
        r'(?::\d+)?'  # optional port
        r'(?:/?|[/?]\S+)$', re.IGNORECASE)

    if not url_pattern.match(url):
        return jsonify({"error": "Invalid URL format"}), 400

    # Additional validation: file size limit, type, etc.
    # ...

    return jsonify({"status": "accepted"})
```

## Rate Limiting

### Pattern 1: Simple IP-Based Rate Limiting

```python
from flask import Flask, request
from functools import wraps
import time
from collections import defaultdict

app = Flask(__name__)

# Store: {ip: [timestamp1, timestamp2, ...]}
request_history = defaultdict(list)

def rate_limit(max_requests=10, window_seconds=60):
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            ip = request.remote_addr
            now = time.time()

            # Remove old requests outside the window
            request_history[ip] = [
                ts for ts in request_history[ip]
                if now - ts < window_seconds
            ]

            # Check if limit exceeded
            if len(request_history[ip]) >= max_requests:
                return {"error": "Rate limit exceeded"}, 429

            # Record this request
            request_history[ip].append(now)

            return f(*args, **kwargs)
        return decorated
    return decorator

@app.route('/api/data')
@rate_limit(max_requests=100, window_seconds=3600)  # 100 per hour
def get_data():
    return {"data": "result"}
```

### Pattern 2: Using Flask-Limiter

```python
from flask import Flask
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

app = Flask(__name__)
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

@app.route('/api/expensive')
@limiter.limit("10 per minute")
def expensive_operation():
    return {"result": "expensive computation"}
```

## Secrets Management

### Never Hardcode Secrets

❌ **Bad:**
```python
API_KEY = "sk-1234567890abcdef"  # Never do this!
DATABASE_URL = "postgresql://user:password@localhost/db"
```

✅ **Good:**
```python
import os
from dotenv import load_dotenv

load_dotenv('.env.tailscale')

API_KEY = os.getenv('API_KEY')
DATABASE_URL = os.getenv('DATABASE_URL')

if not API_KEY:
    raise ValueError("API_KEY not set in environment")
```

### Secure .env.tailscale

```bash
# Create .env.tailscale
cat > .env.tailscale << EOF
API_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(32))")
JWT_SECRET=$(python -c "import secrets; print(secrets.token_hex(32))")
DATABASE_URL=postgresql://user:pass@localhost/db
EOF

# Secure permissions
chmod 600 .env.tailscale

# Add to .gitignore
echo ".env.tailscale" >> .gitignore
```

## Common Vulnerabilities

### SQL Injection Prevention

❌ **Vulnerable:**
```python
query = f"SELECT * FROM users WHERE id = {user_id}"
cursor.execute(query)
```

✅ **Safe:**
```python
query = "SELECT * FROM users WHERE id = ?"
cursor.execute(query, (user_id,))
```

### XSS Prevention

❌ **Vulnerable:**
```python
return f"<h1>Hello {username}</h1>"
```

✅ **Safe:**
```python
from markupsafe import escape
return f"<h1>Hello {escape(username)}</h1>"
```

### Command Injection Prevention

❌ **Vulnerable:**
```python
os.system(f"ffmpeg -i {input_file} output.mp3")
```

✅ **Safe:**
```python
subprocess.run(['ffmpeg', '-i', input_file, 'output.mp3'], check=True)
```

## Security Headers

```python
from flask import Flask

app = Flask(__name__)

@app.after_request
def set_security_headers(response):
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    response.headers['Content-Security-Policy'] = "default-src 'self'"
    return response
```

## Logging & Monitoring

### Log Security Events

```python
import logging

logging.basicConfig(
    filename='/var/log/myapp-security.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

@app.route('/admin')
@require_auth
def admin():
    logging.info(f"Admin access from {request.remote_addr}")
    return "Admin panel"

@app.before_request
def log_failed_auth():
    if request.endpoint and 'auth' in request.endpoint:
        auth = request.headers.get('Authorization')
        if not verify_auth(auth):
            logging.warning(f"Failed auth attempt from {request.remote_addr} to {request.path}")
```

## Incident Response

### If You Suspect a Breach

1. **Immediately disable Funnel:**
   ```bash
   ./scripts/funnel-stop.sh
   ```

2. **Review logs:**
   ```bash
   tail -n 1000 /var/log/myapp.log
   grep "ERROR\|WARNING" /var/log/myapp.log
   ```

3. **Rotate secrets:**
   ```bash
   # Generate new API key
   python -c "import secrets; print(secrets.token_urlsafe(32))"

   # Update .env.tailscale
   nano .env.tailscale
   ```

4. **Update dependencies:**
   ```bash
   pip install --upgrade -r requirements.txt
   ```

5. **Investigate and patch vulnerability**

6. **Re-enable Funnel only after securing:**
   ```bash
   ./scripts/funnel-start.sh
   ```

## Regular Security Maintenance

### Weekly
- [ ] Review logs for anomalies
- [ ] Check for failed authentication attempts
- [ ] Monitor resource usage

### Monthly
- [ ] Update dependencies (`pip install --upgrade`)
- [ ] Review and rotate API keys
- [ ] Audit user access

### Quarterly
- [ ] Security code review
- [ ] Penetration testing
- [ ] Update security documentation

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Flask Security Best Practices](https://flask.palletsprojects.com/en/2.0.x/security/)
- [Tailscale Security Model](https://tailscale.com/security/)
- [Python Security Best Practices](https://python.readthedocs.io/en/stable/library/security_warnings.html)
