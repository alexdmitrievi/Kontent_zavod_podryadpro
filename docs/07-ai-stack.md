# 07 — AI Tool Stack

The canonical answer to "which AI for which job" — with prices, latencies,
and explicit reasons. Updated for the 2026 landscape.

> **Bias of this stack:** lowest cost-per-decision, best multilingual
> (Russian + English), and zero vendor lock-in at the orchestration layer
> (n8n + FFmpeg). Every component is replaceable.

> **Rule:** HeyGen and any other talking-head avatar tools are explicitly
> **out of scope**. They are used manually, outside this factory.

---

## At a glance — final picks

| Job                             | Pick                              | $ / unit       | Alt (cheaper)              | Alt (premium)        |
| ------------------------------- | --------------------------------- | -------------- | -------------------------- | -------------------- |
| Orchestration                   | n8n (self-host)                   | $5/mo VPS      | n8n cloud Starter $20      | Make.com $9          |
| LLM — reasoning / scoring       | Claude Sonnet 4.6                 | ~$3 / 1M in    | Gemini 2.5 Pro             | Claude Opus 4.7      |
| LLM — vision frames             | Gemini 1.5 Flash                  | $0.075 / 1M in | Llama 3.2 Vision (self)    | GPT-4o vision        |
| LLM — moment selection          | GPT-4o                            | ~$2.5 / 1M in  | Gemini 2.5 Pro             | Claude Sonnet 4.6    |
| Video understanding (long)      | Twelve Labs Pegasus               | ~$0.05 / min   | Skip → ffmpeg + GPT-4o     | Twelve Labs Marengo  |
| ASR (transcription)             | faster-whisper-large-v3 (local)   | $0             | OpenAI Whisper API         | AssemblyAI Universal |
| TTS (voiceover, rarely needed)  | ElevenLabs Turbo v2.5             | $0.10 / 1k chr | Google TTS Standard        | ElevenLabs Multilingual v2 |
| Music                           | Suno v4 / Udio                    | $10/mo         | TikTok native sounds       | Epidemic Sound $15   |
| Image generation (thumbs)       | Flux 1.1 [pro] via Replicate      | $0.04 / img    | Flux schnell self-hosted   | Midjourney v7 $10/mo |
| Generative image + video (rare) | **Higgsfield MCP** (Veo/Kling/Sora/Soul) | OAuth, 150 free credits/mo + paid | Self-host SD/Flux schnell | Kling 3.0 / Runway Gen-3 direct |
| Editor (automated)              | FFmpeg                            | $0             | —                          | —                    |
| Editor (manual hero)            | CapCut Pro                        | $7.99/mo       | DaVinci Resolve free       | Premiere Pro $22.99  |
| DB / metadata                   | Supabase                          | free → $25/mo  | Self-host Postgres         | Neon $19/mo          |
| Object storage                  | Cloudflare R2                     | $0.015/GB-mo   | Backblaze B2 $0.006/GB-mo  | AWS S3 (egress $$)   |
| UI / approval                   | Airtable                          | free → $20/mo  | NocoDB self-host           | Notion $10/mo        |
| Multi-platform scheduler        | Postiz (self-host)                | $0             | Buffer $10/mo              | Ayrshare $24/mo      |
| Notifier                        | Telegram Bot                      | $0             | —                          | —                    |

Total: **$28–62 / month** for the full stack at 30 unique videos/week.

---

## Why each pick

### Claude Sonnet — for **judgment**

- Sharpest at nuanced rubrics (the 10-axis viral scorer).
- Best at not "vibing positively" — it actually penalizes weak candidates.
- JSON-output mode is reliable.
- Russian-language quality is on par with GPT-4o.
- Used for: viral scoring, hook generation, caption packs, weekly winner
  variant specs.

### GPT-4o — for **moment selection**

- Best at "look at this list of timestamps + transcript + tags and pick
  the 5 viral candidates" — its reasoning over heterogeneous inputs wins.
- Also used as a fallback for Claude when Anthropic rate-limits.

### Gemini 1.5 Flash — for **vision perception**

- Cheapest per image by ~10×.
- Multimodal JSON-mode is reliable.
- Excellent at "label this frame" but weak at value judgments.

### Twelve Labs — **optional upgrade**

- Real video understanding model trained on raw video, not stitched frames.
- Worth the ~$0.05/min when:
  - clips are > 3 min,
  - you process > 50 clips/day,
  - you want to query video (e.g. "find all clips where a stump grinder
    is in frame and the angle is low").
- Skip in month 1.

### faster-whisper — local

- 4-core VPS does 1.2× real-time on `large-v3`. Free forever.
- Russian + English seamless.
- The OpenAI Whisper API is faster but costs $0.006/min — for our volume
  the savings vs. local are zero, but you trade away privacy.

### ElevenLabs — only when you NEED voiceover

- 90 % of factory output uses **diegetic audio only** (engine, water).
- Reserve voiceover for educational shorts (F7) and the weekly digest.
- Turbo v2.5 is fast (~0.4 s for 5 s of speech) and cheap.

### Flux 1.1 [pro] — for thumbnails / static covers

- 9:16 cover frames sometimes need a "wow" still that isn't in the footage
  (e.g. for Shorts thumbnail or pinned Reel cover).
- Generated on demand via Replicate, ~$0.04 each, cached in R2.

### Higgsfield MCP — for **rare** synthetic b-roll

- One hosted MCP server exposes 30+ image and video models (Veo 3.1,
  Kling 3.0, Sora 2, Seedance 2.0, Flux 2, Nano Banana Pro, Soul V2).
- Used when raw footage is missing a key shot (e.g. a perfect drone
  reveal you forgot to fly).
- 99 % of videos do not need this.
- Free tier: 150 credits/month. Budget cap: $25/month if you exceed.
- Setup: `claude mcp add --transport http --scope user higgsfield https://mcp.higgsfield.ai/mcp`
- See `docs/14-mcp-setup.md`.

### FFmpeg — the render engine

- Open-source, deterministic, scriptable.
- Every render template is a single FFmpeg command (with light Python
  templating).
- No paid editor in the auto path.

### Cloudflare R2 — storage

- $0 egress is the killer feature: Whisper, FFmpeg and platform uploaders
  all pull from R2 dozens of times per asset.
- S3 would cost ~10× more for the same workload.

### Postiz — scheduling

- Open-source, self-host, has TikTok, Reels, Shorts, FB Reels connectors.
- ~3 GB RAM, $5 VPS.
- If you'd rather pay for managed: Ayrshare ($24/mo) has a built-in n8n
  community node.

### Telegram — the notifier and the funnel

- Owner alerts (job uploaded, approval needed, viral fired, error).
- Public channel where viral viewers convert into followers.
- Bot for inbound lead handling.

---

## Cost simulation — 30 unique videos/week, 4 platforms

| Item                       | Volume/month            | Cost/month      |
| -------------------------- | ----------------------- | --------------- |
| n8n VPS (Hetzner CX22)     | 1                       | $5              |
| Render VPS (Hetzner CX42)  | 1                       | $14             |
| R2 storage                 | ~300 GB                 | $4.5            |
| Gemini Flash               | ~600 calls × 5 frames   | ~$1.2           |
| GPT-4o                     | ~600 candidates         | ~$5             |
| Claude Sonnet              | ~1800 calls             | ~$14            |
| ElevenLabs                 | ~10k chars              | ~$1             |
| Flux 1.1 (covers)          | ~80 imgs                | ~$3             |
| Postiz (self-host)         | runs on render VPS      | $0              |
| Supabase                   | free tier                | $0              |
| Airtable                   | free tier                | $0              |
| **Total**                  |                         | **~$48 / mo**   |

If you swap Postiz for Ayrshare → **~$72/mo**.
If you swap local Whisper for Whisper API → +$5/mo.

---

## Model-choice reasoning — when to upgrade

| Situation                                                  | Upgrade                          |
| ---------------------------------------------------------- | -------------------------------- |
| You're posting >120 videos/week                            | Move scoring to Claude Opus      |
| Your captions feel formulaic across platforms              | Two-pass: GPT-4o + Claude review |
| Whisper is missing rural Russian dialects                  | AssemblyAI Universal             |
| You start getting client testimonials                      | Add diarization (Pyannote)       |
| You need synthetic shots (e.g. competitor B-roll)          | Kling 2.0 ($20/mo budget)        |
| You want predictive views per candidate before posting     | Add a model like ViralVision API |

---

## Self-host vs. SaaS trade-off

Self-host everything except LLMs and Replicate. That gives you:

- one VPS for n8n ($5),
- one VPS for render + Whisper + Postiz ($14),
- LLM APIs pay-as-you-go,
- no vendor can shut you down,
- backup is `pg_dump` + `rclone sync`.

The only "lock-in" risks are:

- **Telegram bot** — backed up via export.
- **Airtable** — backed up nightly via n8n to a CSV in R2.
- **Platform OAuth tokens** — re-authenticatable, but rotate quarterly.

---

## Anti-patterns (what NOT to put in the stack)

- ❌ **HeyGen / D-ID** in the auto pipeline. Out of scope. Talking-head
  avatars are produced manually.
- ❌ **GPT-3.5 / Haiku** for viral scoring — they are too "agreeable" and
  inflate scores, ruining the auto-approve gate.
- ❌ **A second LLM provider in the same workflow** — adds 5–10 % failure
  surface. Pick one per node, fallback to the second only on error.
- ❌ **A custom fine-tuned model** at this scale. Not enough data, not
  worth the time.
- ❌ **AWS** for storage. The egress will eat you alive.
- ❌ **A heavyweight video editor like Adobe Premiere** in the auto path.
  Manual hero edits only.
- ❌ **TikTok scheduler aggregators that don't actually post natively** —
  they cause shadowbans. Always use platforms' official partner APIs.

---

## Stack diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                          n8n (CX22)                              │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────────┐  │
│  │  W01   │─▶│  W02   │─▶│  W03   │─▶│  W04   │  │   W05      │  │
│  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘  └─────┬──────┘  │
│      │           │            │           │              │       │
└──────┼───────────┼────────────┼───────────┼──────────────┼───────┘
       │           │            │           │              │
       ▼           ▼            ▼           ▼              ▼
   ┌────────┐  ┌──────────┐ ┌────────┐  ┌────────┐    ┌────────┐
   │ GDrive │  │ Gemini   │ │ FFmpeg │  │ Ayrshare│   │ Stats  │
   │ R2     │  │ + GPT-4o │ │ Whisper│  │  /Postiz│   │ APIs   │
   │        │  │ + Claude │ │ on VPS │  │         │   │        │
   └────┬───┘  └────┬─────┘ └────┬───┘  └────┬────┘   └───┬────┘
        │           │            │           │             │
        └───────────┴────────────┼───────────┴─────────────┘
                                 ▼
                         ┌─────────────────┐
                         │   Supabase      │
                         │   Airtable      │
                         │   Telegram bot  │
                         └─────────────────┘
```
