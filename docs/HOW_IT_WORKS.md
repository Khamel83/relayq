# How RelayQ Actually Works

## 🎯 The Complete Data Flow

This is the **exact step-by-step process** of what happens when you submit a job.

## 📋 Current Architecture (Clean Version)

```
You (OCI VM) ──→ GitHub Actions (Queue) ──→ Self-Hosted Runner (Mac Mini) ──→ Your API (Optional)
       │                      │                      │                           │
       │                      │                      │                           │
    Command                Job Queue           Local Processing          Cloud API
  (dispatch.sh)             (Free)              (Your Hardware)            (Paid)
```

## 🔄 Step-by-Step Job Execution

### Step 1: You Submit a Job
```bash
# You run this on your OCI VM:
./bin/dispatch.sh .github/workflows/transcribe_audio.yml url=https://your-audio.mp3
```

**What happens:**
- `dispatch.sh` calls GitHub CLI (`gh`)
- GitHub CLI creates a workflow run
- Job gets added to GitHub's queue
- **Cost:** 0.1 GitHub minutes

### Step 2: GitHub Manages the Queue
- GitHub stores the job in their system
- GitHub checks for available runners
- GitHub sends job to first matching runner
- **Your audio file URL is stored, but not the audio itself**
- **Cost:** 0.1 GitHub minutes

### Step 3: Your Runner Picks Up the Job
- Your Mac mini runner polls GitHub every 5 seconds
- GitHub says: "Here's a job for you"
- Runner downloads the workflow file
- **Cost:** 0.1 GitHub minutes

### Step 4: Your Runner Downloads Audio
- **Your Mac mini downloads the audio file** from the URL
- **The audio file goes directly to your Mac mini**
- **The audio file NEVER goes through GitHub**
- **Cost:** Free (your bandwidth)

### Step 5: Local Processing
Your Mac mini runs the transcription:

#### Option A: Local Whisper (Free)
```bash
# Your Mac mini processes audio locally
whisper audio.mp3 > transcript.txt
```
- **Cost:** Free (just electricity)

#### Option B: OpenAI API (Paid)
```bash
# Your Mac mini sends to OpenAI
curl -X POST "https://api.openai.com/v1/audio/transcriptions" \
  -H "Authorization: Bearer $AI_API_KEY" \
  -F "file=@audio.mp3" \
  -F "model=whisper-1"
```
- **Cost:** ~$0.006 per minute of audio

#### Option C: Router API (Paid)
```bash
# Your Mac mini sends to OpenRouter
curl -X POST "https://openrouter.ai/api/v1/audio/transcriptions" \
  -H "Authorization: Bearer $AI_API_KEY" \
  -F "file=@audio.mp3" \
  -F "model=openai/whisper-1"
```
- **Cost:** Variable (usually cheaper than OpenAI)

### Step 6: Results Upload
- **Only the TEXT transcript** goes back to GitHub
- Upload is done via GitHub's artifact system
- **No audio files go to GitHub**
- **Cost:** 0.2 GitHub minutes

### Step 7: You Get Results
- You can download transcript from GitHub UI
- Or access via GitHub CLI
- Or read from your local filesystem
- **Cost:** Free

## 💰 Cost Breakdown for 5-Minute Audio

| Component | Cost | Who Pays |
|-----------|------|----------|
| GitHub Orchestration | ~0.5 GitHub minutes | Free (within 2,000 limit) |
| Your Bandwidth | $0 | Your ISP |
| Local Processing | $0 | Your electricity |
| API (if used) | $0.03 | You (to OpenAI/OpenRouter) |
| **Total** | **$0.03** | **~$0.03/month** |

## 🔒 Security & Privacy

### What Goes to GitHub
- ✅ Job instructions (workflow files)
- ✅ Transcript text results
- ✅ Job metadata and logs
- ✅ Your API key (stored as GitHub secret)

### What Stays Local
- ✅ Your audio files
- ✅ Local processing
- ✅ Your personal data
- ✅ Your file system

### No Inbound Ports
- Your Mac mini connects TO GitHub (outbound)
- GitHub never connects TO your Mac mini
- No need to open ports on your router
- Your network remains secure

## 📊 Real-World Examples

### Voice Memo Workflow
```bash
# You record a 5-minute voice memo on your phone
# Upload to your local server
# Submit job:
./bin/dispatch.sh .github/workflows/transcribe_audio.yml \
  url=https://your-nas/voice/2025-11-03-shopping.mp3 \
  backend=local
```

**Result:** 5-minute audio transcribed locally, cost = $0

### Meeting Transcription Workflow
```bash
# You have a 2-hour meeting recording
# Submit job with high-quality API:
./bin/dispatch.sh .github/workflows/transcribe_mac.yml \
  url=https://your-nas/meetings/board-meeting.mp3 \
  backend=openai
```

**Result:** 2-hour audio transcribed by OpenAI, cost = $0.72

### Home Assistant Integration
```python
# Home Assistant automation script
def voice_to_text(audio_path):
    subprocess.run([
        "./bin/dispatch.sh",
        ".github/workflows/transcribe_audio.yml",
        f"url={audio_path}",
        "backend=router"
    ])
```

**Result:** Voice memos automatically transcribed, cost = $0.02 per minute

## 🎯 The Bottom Line

**What you have is a personal cloud:**
- **GitHub** = Your free job scheduling and management
- **Your Mac mini** = Your free processing powerhouse
- **APIs** = Optional premium features when needed

**Total monthly cost for typical use:**
- **Light user (voice memos, grocery lists):** $0/month
- **Heavy user (meeting transcription):** $5-20/month
- **Business user:** $20-100/month (still way cheaper than alternatives)

**Why this is revolutionary:** You're getting enterprise-level job orchestration for free by leveraging GitHub's existing infrastructure instead of building your own.