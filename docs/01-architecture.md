# 01 — System Architecture

This document is the **mental model** of the entire factory. Everything else
in the repo is an implementation of one of the boxes below.

## 1. The eight layers

```
┌──────────────────────────────────────────────────────────────────────┐
│  L8  OPTIMIZATION LAYER     A/B variants, viral cloning, recycling   │
├──────────────────────────────────────────────────────────────────────┤
│  L7  ANALYTICS LAYER        per-platform stats, viral score, KPIs    │
├──────────────────────────────────────────────────────────────────────┤
│  L6  PUBLISHING LAYER       multi-platform schedule + auto-post      │
├──────────────────────────────────────────────────────────────────────┤
│  L5  EDITING LAYER          cut, caption, music, render (FFmpeg)     │
├──────────────────────────────────────────────────────────────────────┤
│  L4  AI PROCESSING LAYER    moment detect, transcribe, score, hook   │
├──────────────────────────────────────────────────────────────────────┤
│  L3  STORAGE LAYER          R2/B2 cold + Drive hot + DB metadata     │
├──────────────────────────────────────────────────────────────────────┤
│  L2  INGESTION LAYER        phone, drone, GoPro → cloud → queue      │
├──────────────────────────────────────────────────────────────────────┤
│  L1  CAPTURE LAYER          field operator, phone holders, action    │
└──────────────────────────────────────────────────────────────────────┘
                    ▲                                ▼
              raw footage                       finished posts
```

Each layer has one job and one job only. Everything that flows up the stack
becomes more curated, more compressed, more "viral-ready". Everything that
flows down the stack becomes more actionable: which clip to capture more of,
which format to repeat, which hook to retire.

---

## 2. End-to-end data flow

```
┌─────────────┐   ┌─────────────┐   ┌──────────────┐   ┌────────────────┐
│  PHONE/DRONE│──▶│  AUTO-UPLOAD│──▶│  R2 RAW      │──▶│  N8N: INGEST   │
│  in field   │   │  iCloud/Drv │   │  bucket      │   │  workflow 01   │
└─────────────┘   └─────────────┘   └──────────────┘   └────────┬───────┘
                                                                 │
                                              metadata + thumbs  ▼
                                                       ┌────────────────┐
                                                       │  SUPABASE      │
                                                       │  clips table   │
                                                       └────────┬───────┘
                                                                ▼
┌────────────────────┐   ┌────────────────────┐   ┌────────────────────┐
│ AI CLASSIFICATION  │   │ AI MOMENT DETECT   │   │ AI VIRAL SCORE     │
│ Gemini Vision/GPT  │◀──│ Twelve Labs / GPT  │◀──│ Claude / GPT       │
│ (workflow 02)      │   │ + ffmpeg scenes    │   │ rubric → 0..100    │
└─────────┬──────────┘   └─────────┬──────────┘   └─────────┬──────────┘
          │                        │                        │
          └────────────┬───────────┴────────────┬───────────┘
                       ▼                        ▼
                ┌────────────────┐    ┌────────────────┐
                │ HOOK GENERATOR │    │ EDIT TEMPLATE  │
                │ Claude / GPT   │───▶│ selector       │
                └────────────────┘    └────────┬───────┘
                                               ▼
                                      ┌────────────────┐
                                      │ FFMPEG RENDER  │
                                      │ (workflow 03)  │
                                      └────────┬───────┘
                                               ▼
                                      ┌────────────────┐
                                      │ AIRTABLE QUEUE │
                                      │ approval (30s) │
                                      └────────┬───────┘
                                               ▼
       ┌───────────────────────────────────────┴───────────────────────┐
       ▼                  ▼                  ▼                          ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐         ┌─────────────┐
│  TIKTOK     │   │  REELS (IG) │   │  SHORTS (YT)│         │  FB REELS   │
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘         └──────┬──────┘
       │                 │                 │                       │
       └─────────────────┴───────┬─────────┴───────────────────────┘
                                 ▼
                        ┌────────────────┐
                        │ STATS POLLERS  │
                        │ workflow 05    │
                        └────────┬───────┘
                                 ▼
                        ┌────────────────┐
                        │ SUPABASE       │
                        │ metrics table  │
                        └────────┬───────┘
                                 ▼
                        ┌────────────────┐         ┌────────────────┐
                        │ DAILY DIGEST   │────────▶│ TELEGRAM BOT   │
                        │ + RECYCLE      │         │ owner channel  │
                        └────────────────┘         └────────────────┘
```

---

## 3. Component responsibilities

### L1 — Capture (humans + hardware)

- **Field operator** (you or a worker) wears a chest harness + bike-mount phone.
- **Two angles minimum** per job: wide static (tripod / pole) + handheld.
- **Drone** (DJI Mini 4 Pro or older) for top-down before/after.
- **GoPro / action cam** strapped to equipment for ASMR cuts.
- Operator follows a 6-shot shot list (see `docs/03-ingestion.md`).
- **Verbal slate**: at start of shoot say _"Address, service, date, before"_
  — Whisper picks this up for auto-tagging.

### L2 — Ingestion

- Phones auto-upload to **Google Drive / iCloud** over Wi-Fi at home base.
- A watcher (n8n cron every 5 min) detects new files and pushes them to
  **Cloudflare R2** under `raw/YYYY/MM/DD/{job_id}/`.
- Each new file gets an entry in `clips` with `status = ingested`.

### L3 — Storage

| Tier      | Bucket / store        | Lifetime | Purpose                                  |
| --------- | --------------------- | -------- | ---------------------------------------- |
| Hot       | Google Drive          |   7 days | Editing scratch, manual review           |
| Warm      | R2 `processed/`       |  90 days | Rendered shorts, ready to re-publish     |
| Cold      | R2 `raw/`             |  ∞       | Original 4K footage, source of truth     |
| Meta      | Supabase Postgres     |  ∞       | Clips, posts, metrics, hooks, scores     |
| UI / Ops  | Airtable              |  ∞       | Human approval, calendar, dashboards     |

### L4 — AI processing

Six subsystems, all stateless, each fired by n8n:

1. **Classifier** — Gemini 1.5 Flash on a 5-frame strip → tags
   `{service, scene_type, time_of_day, weather, mood}`.
2. **Moment detector** — Twelve Labs `analyze` or ffmpeg scene-change +
   GPT-4o vision sweep → returns 3–8 timestamped "viral candidates" per clip.
3. **Transcriber** — Whisper-large-v3 → SRT + speaker-cleaned text. Also
   used to find verbal slates.
4. **Viral scorer** — Claude Sonnet rubric (see `prompts/viral-scoring.md`).
5. **Hook generator** — Claude / GPT-4o → 5 hook variants per candidate.
6. **Caption + hashtag generator** — same LLM call, 3 platform variants.

### L5 — Editing

- **FFmpeg** is the render engine. No CapCut for the automated path —
  CapCut is reserved for manual hero edits 1-2x/week.
- Render templates in `workflows/templates/`:
  - `T01_before_after_split.json` — 50/50 wipe
  - `T02_chaos_to_order.json` — full clip + ASMR
  - `T03_time_lapse.json` — speed ramp 8x → 1x
  - `T04_drone_reveal.json` — top-down hold → push-in
  - `T05_machinery_asmr.json` — close-up sound design
- Subtitles burned in via FFmpeg `subtitles=` filter with custom `.ass` style
  (see `docs/08-editing.md`).

### L6 — Publishing

- One scheduler: **Ayrshare** (paid, $24/mo) **or** **Postiz** (self-host,
  free). Both have n8n nodes.
- Each post object: `{platform, asset_url, caption, hashtags, schedule_at,
  variant_id}`.
- Posting cadence per platform (defaults, override per video):
  - TikTok: 18:00 + 21:00 local
  - Reels: 12:00 + 19:00 local
  - Shorts: 17:00 local
  - FB Reels: 20:00 local
- Manual approval gate: a row in Airtable `Queue`. Operator taps a checkbox;
  n8n proceeds. Auto-approve after 4 hours if viral_score ≥ 80.

### L7 — Analytics

- Stats pollers per platform, every 1h for the first 48h, then every 6h to
  day 7, then daily to day 30.
- Stored in `metrics` table with `(post_id, captured_at, views, likes,
  comments, shares, saves, avg_watch_time, completion_rate)`.
- A **viral score (post-hoc)** is recomputed at 24h/72h/7d using a velocity
  formula (see `docs/11-analytics.md`).

### L8 — Optimization

- Every Sunday 22:00, n8n runs the **Winners workflow**:
  - Top 10 % posts by 72h velocity become "winners".
  - For each winner, LLM generates **3 variants**: same footage / new hook,
    new footage / same hook, new edit pacing / same hook+footage.
  - Variants enter the queue automatically; operator only sees the Airtable
    approval row.
- Posts in bottom 25 % at day 7 are flagged `archive` and excluded from
  recycling.

---

## 4. Tech-stack reference (canonical choices)

| Concern              | Pick                          | Why                                    |
| -------------------- | ----------------------------- | -------------------------------------- |
| Orchestrator         | **n8n** (self-host, Hetzner)  | Free, flexible, has every node we need |
| DB                   | **Supabase Postgres**         | Free tier covers us to ~1 GB metadata  |
| Object storage       | **Cloudflare R2**             | $0 egress; cheap cold storage          |
| Hot scratch          | **Google Drive**              | iCloud / Android sync work natively    |
| LLM (text)           | **Claude Sonnet** + GPT-4o    | Sonnet for scoring, GPT-4o for vision  |
| Vision               | **Gemini 1.5 Flash**          | Cheapest per video frame               |
| Video understanding  | **Twelve Labs** (optional)    | Real moment detection, ~$0.05/min      |
| ASR                  | **Whisper-large-v3** (local)  | Free on the VPS, multilingual          |
| TTS (voiceovers)     | **ElevenLabs Turbo v2.5**     | Cheapest natural voice, RU support     |
| Image (thumbs)       | **Flux 1.1 [pro]** via Replicate | Best photoreal at low cost          |
| Generative b-roll    | **Runway Gen-3 / Kling 2.0**  | Only when you need synthetic shots     |
| Video editor (auto)  | **FFmpeg**                    | The render engine, scriptable          |
| Video editor (hero)  | **CapCut Pro** (manual)       | 1–2x/week heavy edits only             |
| Scheduler            | **Postiz** (self-host)        | Free; Ayrshare if you want managed     |
| Approval UI          | **Airtable**                  | Phone-friendly tap-to-approve          |
| Notifier             | **Telegram Bot API**          | Owner inbox + lead funnel              |
| Observability        | **Grafana + Loki** (optional) | When the system grows past 1k posts    |

Total recurring infra cost (target): **$28–62 / month**. Full breakdown in
`docs/13-low-budget.md`.

---

## 5. Folder + naming convention (single source of truth)

```
{job_id} = {YYYYMMDD}-{service_code}-{seq}     e.g. 20260517-MOW-03
{clip_id} = {job_id}-{cam}-{shot_seq}          e.g. 20260517-MOW-03-A-007
{post_id} = {clip_id}-{platform}-{variant}     e.g. 20260517-MOW-03-A-007-TT-v2

service_code ∈ {MOW, OVR, CLR, STM, TRE, POO, MNT, RNT, PLW, CLN}
cam          ∈ {A=phone-wide, B=phone-hand, C=drone, D=action}
platform     ∈ {TT, IG, YT, FB}
variant      ∈ {v1, v2, ...} (A/B variants)
```

Every artifact in the system carries one of these IDs. No exceptions.

---

## 6. Failure modes & retries

| Failure                               | Detection                  | Auto-action                           |
| ------------------------------------- | -------------------------- | ------------------------------------- |
| Upload stalls > 30 min                | n8n cron checks file size  | Re-trigger upload, alert if 3rd fail  |
| LLM call timeouts                     | n8n built-in retry         | 3 retries, exponential back-off       |
| FFmpeg render error                   | Non-zero exit code         | Re-try with fallback template T01     |
| Platform API rate-limit / reject      | API error code             | Pause queue 30 min, ping Telegram     |
| Stats poll returns 0 after 48h        | Sanity check               | Mark post `dead`, exclude from recycle|
| Approval row idle > 4h, score ≥ 80    | Cron                       | Auto-approve                          |
| Approval row idle > 24h, score < 80   | Cron                       | Auto-archive                          |

All failures emit a Telegram alert to the operator with deep-links to the
offending row in Airtable.

---

## 7. Mental model in one paragraph

The factory is a **conveyor belt**. The operator drops raw chaos in at the
front (phone footage of dirty pools and 2-meter grass). Eight automated
stations along the belt classify it, score it, pick the best 10 seconds, cut
it, caption it, and post it on four platforms. Two days later the belt loops
back: winning videos are cloned into 3 variants and re-enter the queue;
losers are archived. The only human touch points are (a) shooting, (b)
30-second daily approval, (c) replying to inbound Telegram DMs. Everything
else is automated.
