# Kontent Zavod — AI Local Viral Content Factory

A production-level blueprint for an AI-driven content engine that turns a local
landscaping / property-services business (mowing, overgrowth cleanup, land
clearing, stump grinding, tree cutting, pool cleaning, equipment rental, soil
plowing, full property cleanup) into a **local media-driven brand**.

The system is built for **one operator**, **low budget**, **organic reach
only**. It is fully orchestrated via **n8n** and outputs daily short-form
videos to TikTok, Instagram Reels, YouTube Shorts and Facebook Reels, with all
traffic funneled to **Telegram** for DMs and leads.

> HeyGen avatars are **out of scope** for this system. They are produced
> manually, in parallel. This factory exists only to push **transformation /
> cleanup / satisfying / before-after** footage at scale.

---

## North-star metrics

| Metric                              | Day 30 | Day 90 | Day 180 |
| ----------------------------------- | -----: | -----: | ------: |
| Posts / day (per platform)          |    1–2 |    2–3 |     3–4 |
| Unique videos / week                |     10 |     20 |      30 |
| Avg. 3s retention                   |   65 % |   75 % |    80 % |
| Avg. completion rate                |   25 % |   35 % |    45 % |
| Telegram subs                       |    100 |  1 000 |   5 000 |
| Inbound DMs / week                  |      5 |     30 |     100 |
| Booked jobs from social / month     |      3 |     15 |      40 |

---

## Repository layout

```
.
├── README.md                       ← you are here
├── docs/
│   ├── 01-architecture.md          ← full system architecture + diagrams
│   ├── 02-n8n-workflows.md         ← every n8n workflow, node-by-node
│   ├── 03-ingestion.md             ← raw footage capture → cloud sorting
│   ├── 04-ai-pipeline.md           ← moment detection, scoring, editing
│   ├── 05-viral-engine.md          ← viral frameworks for this niche
│   ├── 06-hooks.md                 ← 100 hook templates (EN + RU)
│   ├── 07-ai-stack.md              ← tool stack, prices, when to use what
│   ├── 08-editing.md               ← pacing, subtitles, sound, retention
│   ├── 09-platforms.md             ← TikTok / Reels / Shorts / FB Reels
│   ├── 10-telegram-funnel.md       ← viral → Telegram → DM → lead
│   ├── 11-analytics.md             ← KPIs, viral score, A/B, cloning
│   ├── 12-content-matrix.md        ← 12-category content matrix
│   └── 13-low-budget.md            ← 1-person, sub-$300/mo playbook
├── schemas/
│   ├── supabase.sql                ← Postgres schema (clips, posts, metrics)
│   ├── airtable.md                 ← Airtable base structure (UI layer)
│   └── folders.md                  ← Drive/Cloud folder taxonomy
├── prompts/
│   ├── hook-generator.md           ← LLM prompts for hooks
│   ├── caption-generator.md        ← captions / hashtags / CTAs
│   ├── viral-scoring.md            ← 0-100 viral score rubric
│   ├── moment-detection.md         ← prompt for selecting best clips
│   └── transcription-cleanup.md    ← Whisper → on-screen subtitle text
└── workflows/
    ├── 01-ingestion.json           ← n8n: phone/drone upload → sort
    ├── 02-classification.json      ← n8n: AI tag + score raw clips
    ├── 03-edit-render.json         ← n8n: assemble → render → store
    ├── 04-publish.json             ← n8n: schedule + multi-platform post
    ├── 05-analytics.json           ← n8n: pull stats, score, recycle
    └── 06-winners.json             ← n8n: weekly clone + retire + recalibrate
```

---

## How to read this blueprint

1. Start with **docs/01-architecture.md** — the 10-minute mental model.
2. Then **docs/05-viral-engine.md** and **docs/06-hooks.md** — the *why* the
   content works.
3. Then **docs/02-n8n-workflows.md** — the *how* the system runs itself.
4. Use **schemas/** to provision your database and storage.
5. Use **workflows/** as starting points to import into n8n.
6. Use **prompts/** as drop-in templates for OpenAI/Claude/Gemini calls.

---

## Quick-start (week 1)

```
Day 1 — Provision: Supabase project, n8n (self-hosted on $5 VPS),
        Cloudflare R2 (or Backblaze B2), Airtable base, Telegram bot.
Day 2 — Folder structure on Google Drive + iCloud auto-upload from phone.
        Set up FFmpeg + Whisper on the VPS.
Day 3 — Import workflow 01-ingestion.json into n8n; smoke test with
        5 phone clips.
Day 4 — Import 02-classification.json; verify AI tags + viral scores.
Day 5 — Import 03-edit-render.json; render your first 3 shorts.
Day 6 — Import 04-publish.json; connect TikTok / Reels / Shorts / FB
        via Ayrshare or Postiz. Schedule first 5 posts.
Day 7 — Import 05-analytics.json; verify metrics are flowing back to
        Supabase. Set the daily 21:00 review digest to Telegram.
```

By end of week 2, the system should be posting **1 video/day/platform**
without manual editing — only raw footage upload + 30 sec approval tap.

---

## Operating principle

> Shoot **chaos**. Show **order**. Loop **dopamine**. Capture **attention**.
> Convert **locally**.

Everything in this repo is in service of that one loop.
