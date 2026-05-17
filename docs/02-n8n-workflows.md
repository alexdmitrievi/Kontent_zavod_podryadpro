# 02 — n8n Automation Architecture

Five workflows make the factory run. They chain together via Supabase row
status changes and a single internal webhook bus. Each workflow has one job
and exits cleanly. No long-running n8n executions.

```
01-INGESTION ─▶ 02-CLASSIFICATION ─▶ 03-EDIT-RENDER ─▶ 04-PUBLISH ─▶ 05-ANALYTICS
   (cron)         (DB trigger)         (DB trigger)      (cron)         (cron)
                                                              ▲              │
                                                              └── 06-WINNERS ┘
                                                                 (weekly)
```

n8n self-hosted on a Hetzner CX22 ($5/mo) is more than enough — typical
factory throughput is < 200 workflow executions / day.

---

## Shared building blocks

Every workflow uses these:

- **Credentials**: `supabase`, `r2`, `gdrive`, `openai`, `anthropic`, `gemini`,
  `whisper-local`, `ayrshare` (or `postiz`), `telegram-owner`.
- **Internal webhook bus**: a single n8n webhook
  `POST /events { workflow, payload }` used for fan-out between workflows.
- **Helper sub-workflows** (callable):
  - `SF/llm-claude` — wraps Anthropic Messages API with retry + token cap
  - `SF/llm-gpt4o` — wraps OpenAI with retry
  - `SF/ffmpeg-exec` — SSH into the render VPS, runs ffmpeg, returns S3 url
  - `SF/notify` — Telegram message to owner, with optional Airtable deep-link

> Convention: every workflow writes its run-id back to a `workflow_runs` row
> on entry and updates `status` on exit. This is your audit log.

---

## Workflow 01 — Ingestion (`workflows/01-ingestion.json`)

**Trigger**: Cron `*/5 * * * *` (every 5 min).
**Purpose**: Pull new raw footage from Drive/iCloud, sort it, register in DB.

### Nodes

| # | Node              | Type                 | Config / logic                                                                       |
| - | ----------------- | -------------------- | ------------------------------------------------------------------------------------ |
| 1 | `cron`            | Schedule Trigger     | `*/5 * * * *`                                                                        |
| 2 | `list_drive_new`  | Google Drive         | List files in `Inbox/`, filter `modifiedTime > {{ $now.minus({minutes:6}) }}`        |
| 3 | `iterate`         | Loop Over Items      | Batch size 1                                                                         |
| 4 | `is_video`        | If                   | `mimeType` ∈ {video/mp4, video/quicktime, video/x-m4v}                              |
| 5 | `download`        | Google Drive         | Download to n8n binary                                                               |
| 6 | `probe`           | Execute Command      | `ffprobe -v error -show_streams -of json {file}` → duration, resolution, codec       |
| 7 | `gen_job_id`      | Function             | Parse Drive folder name or fall back to `{YYYYMMDD}-MISC-{seq}` (seq from Supabase)  |
| 8 | `whisper_slate`   | Execute Command      | `whisper {file} --model large-v3 --language ru --max_duration 6` → grab verbal slate |
| 9 | `parse_slate`     | Function             | Regex address/service/date out of first 6 s of transcript                            |
|10 | `r2_put_raw`      | HTTP / S3            | `PUT raw/{YYYY}/{MM}/{DD}/{job_id}/{clip_id}.mp4`                                    |
|11 | `make_thumb`      | Execute Command      | `ffmpeg -ss 00:00:02 -i in.mp4 -frames:v 1 -q:v 2 out.jpg`                           |
|12 | `r2_put_thumb`    | HTTP / S3            | `PUT thumbs/{clip_id}.jpg`                                                           |
|13 | `insert_clip`     | Supabase             | `clips` upsert: id, job_id, cam, duration, w/h, slate_*, status=`ingested`           |
|14 | `move_drive`      | Google Drive         | Move file `Inbox/` → `Inbox/_archived/{YYYY-MM}/`                                    |
|15 | `notify_first`    | If + Telegram        | If this is the first clip of `job_id` today, send "🎬 New job: {service}, {address}" |
|16 | `enqueue_classify`| HTTP                 | `POST /events { workflow:"02-classification", clip_id }`                             |

### Edge cases

- **Multi-segment phones** (iPhone splits long clips): the parser merges by
  filename prefix and treats them as one clip with two segments.
- **Drone DJI .MOV**: `ffmpeg -c:v copy -c:a copy` rewrap to MP4 before R2.
- **Duplicate detection**: sha256 of first 1 MB. If hash exists in `clips`,
  skip and move to `_duplicates/`.

---

## Workflow 02 — Classification & scoring (`workflows/02-classification.json`)

**Trigger**: Webhook `/events` with `{workflow:"02-classification", clip_id}`.
**Purpose**: Tag clip, detect moments, score viral potential.

### Nodes

| #  | Node                  | Type             | Config / logic                                                                                                 |
| -- | --------------------- | ---------------- | -------------------------------------------------------------------------------------------------------------- |
|  1 | `webhook_in`          | Webhook          | Receives `clip_id`                                                                                             |
|  2 | `load_clip`           | Supabase         | Select `clips.*` by id                                                                                         |
|  3 | `r2_get`              | HTTP             | Pre-signed GET url, valid 1 h                                                                                  |
|  4 | `sample_frames`       | Execute Command  | `ffmpeg -i {url} -vf fps=1/(duration/5) -frames:v 5 frame_%02d.jpg`                                            |
|  5 | `classify_gemini`     | HTTP (Gemini)    | Vision call on 5 frames → JSON `{service, scene, time_of_day, weather, mood, overgrowth_level, water_state}`   |
|  6 | `transcribe_whisper`  | Execute Command  | Full clip Whisper → SRT + plain text                                                                           |
|  7 | `scene_split_ffmpeg`  | Execute Command  | `ffmpeg -i in.mp4 -filter:v "select='gt(scene,0.4)',showinfo" -f null -` → list of cut points                  |
|  8 | `pick_candidates_llm` | Sub-WF llm-gpt4o | Feed scene-list + transcript → GPT-4o returns 3–8 `{start, end, kind, reason}` viral candidates                |
|  9 | `viral_score_claude`  | Sub-WF llm-claude| For each candidate, run `prompts/viral-scoring.md` → returns 0–100 score + breakdown                           |
| 10 | `pick_top3`           | Function         | Keep top 3 candidates by score, drop the rest                                                                  |
| 11 | `gen_hooks`           | Sub-WF llm-claude| Per candidate, generate 5 hooks (3 EN + 2 RU) using `prompts/hook-generator.md`                                |
| 12 | `gen_captions`        | Sub-WF llm-claude| Per (candidate × platform) generate caption + hashtags + CTA                                                   |
| 13 | `pick_template`       | Function         | Map `{kind}` → render template T01–T08 (see `docs/08-editing.md`)                                              |
| 14 | `upsert_candidates`   | Supabase         | Insert into `candidates` table: clip_id, start, end, kind, score, template, hooks[], captions[]                |
| 15 | `update_clip_status`  | Supabase         | `clips.status = 'classified'`                                                                                  |
| 16 | `enqueue_edit`        | HTTP             | For each candidate, `POST /events { workflow:"03-edit-render", candidate_id }`                                 |

### Cost & latency budget

| Step           | Cost (per 60 s of source) | Latency        |
| -------------- | ------------------------- | -------------- |
| Gemini Vision  | ~$0.002                   | 2–4 s          |
| Whisper local  | $0 (CPU 4-core)           | 30–60 s        |
| Scene split    | $0                        | 5–10 s         |
| GPT-4o pick    | ~$0.01                    | 3–6 s          |
| Claude score×3 | ~$0.015                   | 4–8 s          |
| Hooks + caps   | ~$0.02                    | 4–8 s          |
| **Total**      | **~$0.05 / clip**         | **~90 s**      |

So ~$1.50 / month of LLM cost at 30 clips/day. Negligible.

---

## Workflow 03 — Edit & render (`workflows/03-edit-render.json`)

**Trigger**: Webhook `/events { workflow:"03-edit-render", candidate_id }`.
**Purpose**: Cut, caption, brand, render 9:16 MP4 per platform.

### Nodes

| #  | Node                   | Type             | Config / logic                                                                                                    |
| -- | ---------------------- | ---------------- | ----------------------------------------------------------------------------------------------------------------- |
|  1 | `webhook_in`           | Webhook          | Receives `candidate_id`                                                                                           |
|  2 | `load_cand`            | Supabase         | join `candidates` + `clips` + selected `template`                                                                 |
|  3 | `pick_variants`        | Function         | Build N output specs (default 2 per platform → 8 total; can be reduced)                                           |
|  4 | `loop_variants`        | Split In Batches | Batch 1                                                                                                           |
|  5 | `download_source`      | HTTP             | Stream raw clip from R2 to render VPS                                                                             |
|  6 | `build_ass_subtitles`  | Function         | Convert Whisper segments into `.ass` with per-word pop, style from `docs/08-editing.md`                           |
|  7 | `render_ffmpeg`        | Sub-WF ffmpeg    | See **Render command** below                                                                                      |
|  8 | `qa_check`             | Execute Command  | ffprobe: duration ∈ [7, 60]s, fps ≥ 30, audio non-silent. If fails → flag, skip variant                           |
|  9 | `r2_put_render`        | HTTP / S3        | `processed/{post_id}.mp4`                                                                                         |
| 10 | `r2_put_cover`         | HTTP / S3        | First-frame cover image                                                                                            |
| 11 | `insert_post`          | Supabase         | `posts` insert: post_id, candidate_id, platform, variant, url, cover_url, caption, hashtags, hook, status=`pending`|
| 12 | `airtable_queue`       | Airtable         | Insert row in `Queue` with thumbnail, hook, score, approve checkbox                                                |
| 13 | `auto_approve_high`    | If               | If `viral_score ≥ 80` → mark `status=approved` immediately and enqueue publish                                    |
| 14 | `notify_owner`         | Telegram         | "✂️ 4 new variants ready for {clip_id}. Top score: 87. Open ▶ Airtable"                                            |

### Render command (template T02 — "Chaos → Order")

```bash
ffmpeg -y \
  -ss {start} -to {end} -i source.mp4 \
  -i music_{mood}.mp3 \
  -filter_complex "
    [0:v]scale=1080:-2,crop=1080:1920,setpts=PTS-STARTPTS,
         eq=contrast=1.08:saturation=1.15,
         subtitles=subs.ass:fontsdir=/fonts[v];
    [0:a]volume=0.9,afade=t=in:d=0.3,afade=t=out:st=27:d=0.5[a1];
    [1:a]volume=0.6,atrim=0:{duration},afade=t=in:d=0.3,
         afade=t=out:st={duration-0.5}:d=0.5[a2];
    [a1][a2]amix=inputs=2:duration=longest[a]
  " \
  -map "[v]" -map "[a]" \
  -c:v libx264 -preset veryfast -crf 19 -profile:v high -pix_fmt yuv420p \
  -c:a aac -b:a 192k -ar 48000 \
  -movflags +faststart \
  out.mp4
```

Each platform gets a slightly different bake:

| Platform | Spec               | Notes                                  |
| -------- | ------------------ | -------------------------------------- |
| TikTok   | 1080×1920, 30 fps  | Burn captions. Keep < 35 s for now     |
| Reels    | 1080×1920, 30 fps  | Reduce caption font 10 %               |
| Shorts   | 1080×1920, 30 fps  | Lower-third caption, leave top clear   |
| FB Reels | 1080×1920, 30 fps  | Same as Reels                          |

### Approval gate logic

```
posts.status:
  pending  → awaiting human tap in Airtable
  approved → enters workflow 04 publish queue
  rejected → archived, never published
  auto_ok  → score ≥ 80 + 4h idle, treated as approved
```

---

## Workflow 04 — Publish (`workflows/04-publish.json`)

**Trigger**: Cron `*/10 * * * *` (every 10 min).
**Purpose**: Send approved posts to the right platform at the right time.

### Nodes

| #  | Node                | Type            | Config / logic                                                                                |
| -- | ------------------- | --------------- | --------------------------------------------------------------------------------------------- |
|  1 | `cron`              | Schedule        | every 10 min                                                                                  |
|  2 | `due_posts`         | Supabase        | `select * from posts where status in ('approved','auto_ok') and scheduled_at <= now()`        |
|  3 | `loop`              | Split In Batches| batch 1                                                                                       |
|  4 | `presign_video`     | HTTP            | R2 GET signed URL, valid 1 h                                                                  |
|  5 | `route_platform`    | Switch          | TT / IG / YT / FB                                                                              |
|  6 | `post_tiktok`       | HTTP (Ayrshare) | `POST /post` with `platforms:["tiktok"]`, video_url, caption, hashtags                        |
|  6'| `post_reels`        | HTTP (Ayrshare) | Same, `platforms:["instagram"]`                                                                |
|  6"| `post_shorts`       | HTTP (Ayrshare) | Same, `platforms:["youtube"]` + `title`                                                       |
|  6"'| `post_fb`          | HTTP (Ayrshare) | Same, `platforms:["facebook"]`                                                                |
|  7 | `handle_response`   | If              | success → save `external_id`. error → exponential backoff, max 3 tries                        |
|  8 | `update_post`       | Supabase        | `posts.status='published', published_at=now(), external_id=...`                                |
|  9 | `notify`            | Telegram        | "🚀 Posted {post_id} on {platform} — {permalink}"                                              |
| 10 | `seed_metrics_row`  | Supabase        | Insert empty `metrics` rows at t+1h, t+6h, t+24h, t+72h, t+7d for scheduler to fill           |

### Scheduling logic (`scheduled_at`)

When workflow 03 inserts a post, `scheduled_at` is computed:

```
slot = next available slot ≥ now() + 30 min
      within preferred window per platform per service
```

Preferred windows (local time, default; tune per market):

| Service        | TikTok       | Reels        | Shorts | FB Reels |
| -------------- | ------------ | ------------ | ------ | -------- |
| MOW / OVR      | 18:00, 21:00 | 12:00, 19:00 | 17:00  | 20:00    |
| POO            | 12:00, 21:00 | 11:00, 20:00 | 16:00  | 19:00    |
| TRE / STM      | 19:00        | 18:00        | 18:00  | 21:00    |
| CLR / CLN      | 18:00, 21:00 | 19:00        | 17:00  | 20:00    |

No two posts on the same platform within 90 min.

### Shadowban prevention

- Rotate captions: never publish identical caption across two platforms.
- Strip metadata before upload (`ffmpeg -map_metadata -1`).
- Re-encode subtly for each platform (CRF 19/20/21).
- Different cover frame per platform.
- Different first 0.6 s (vary intro tail by 100 ms).

---

## Workflow 05 — Analytics (`workflows/05-analytics.json`)

**Trigger**: Cron `0 */1 * * *` (hourly).
**Purpose**: Pull stats per platform, compute viral velocity, mark winners/dead.

### Nodes

| #  | Node              | Type            | Config / logic                                                                          |
| -- | ----------------- | --------------- | --------------------------------------------------------------------------------------- |
|  1 | `cron`            | Schedule        | hourly                                                                                  |
|  2 | `due_polls`       | Supabase        | rows in `metrics` where `captured_at IS NULL AND scheduled_for <= now()`                |
|  3 | `loop`            | Split In Batches| batch 5                                                                                 |
|  4 | `pull_stats`      | HTTP (Ayrshare) | `GET /analytics/post?id=...`                                                            |
|  5 | `store_metrics`   | Supabase        | update metrics row                                                                      |
|  6 | `compute_velocity`| Function        | views_per_hour = views / hours_since_publish; engagement = (likes+shares*5+comments*3)/views |
|  7 | `viral_label`     | Function        | label ∈ {dud, ok, hit, viral, mega} based on platform-percentile thresholds             |
|  8 | `update_post`     | Supabase        | `posts.viral_label`, `posts.viral_velocity`                                             |
|  9 | `daily_digest`    | If cron == 21:00| Aggregate last 24h → markdown summary → Telegram                                        |

### Viral label thresholds (per platform, per 24 h)

| Label  | TikTok views | Reels views | Shorts views | FB Reels views |
| ------ | -----------: | ----------: | -----------: | -------------: |
| dud    |        < 500 |       < 300 |        < 400 |          < 300 |
| ok     |        < 5k  |       < 3k  |        < 4k  |          < 3k  |
| hit    |       < 50k  |      < 30k  |       < 40k  |         < 30k  |
| viral  |      < 500k  |     < 300k  |      < 400k  |        < 300k  |
| mega   |       ≥ 500k |     ≥ 300k  |      ≥ 400k  |        ≥ 300k  |

These thresholds are seeded; the system **auto-recalibrates** weekly using
your last 200 posts (workflow 06).

---

## Workflow 06 — Winners & recycling (`workflows/06-winners.json`)

**Trigger**: Cron `0 22 * * 0` (Sunday 22:00).
**Purpose**: Clone winners, retire losers, recalibrate thresholds.

### Nodes

|  # | Node                  | Type             | Logic                                                                                       |
| -- | --------------------- | ---------------- | ------------------------------------------------------------------------------------------- |
|  1 | `cron`                | Schedule         | weekly                                                                                      |
|  2 | `pull_winners`        | Supabase         | top 10 % by velocity, viewed > 24h, not yet cloned                                          |
|  3 | `loop_winners`        | Split In Batches | batch 1                                                                                     |
|  4 | `gen_clone_specs`     | Sub-WF llm-claude| Ask Claude to produce 3 variant specs (see prompt below)                                    |
|  5 | `enqueue_each_variant`| HTTP             | Each variant → `03-edit-render` with overridden hook + template                             |
|  6 | `pull_losers`         | Supabase         | bottom 25 % at day 7                                                                        |
|  7 | `archive`             | Supabase         | `posts.recycle = 'archived'`                                                                |
|  8 | `recalibrate`         | Function         | Recompute label thresholds as percentiles of last 200 posts per platform                    |
|  9 | `digest`              | Telegram         | "📊 Week: {N} winners cloned, {M} losers archived. Thresholds updated. Avg score: ..."       |

### Variant-spec prompt (excerpt)

```
You are optimizing a viral landscaping short.
Original: hook="{hook}", template="{template}", duration={dur}s,
views_24h={v24}, completion={cr}%, engagement={er}%.

Produce 3 variants:
1. Same footage, NEW hook (more curiosity, different angle).
2. New edit template ({suggest one of T01..T08 not equal to current}),
   same hook.
3. Same footage + same hook, but different first 1.5s (pattern interrupt).

Respond JSON: [{variant, hook, template, first_frame_strategy, reason}].
```

---

## Cross-cutting concerns

### Idempotency

Every workflow checks `workflow_runs` for `(workflow, entity_id, status='done')`
before doing work. Re-firing a webhook never duplicates outputs.

### Backpressure

- If `posts` table has more than 20 `pending` rows → workflow 03 pauses new
  candidates and sends a Telegram nudge to clear approvals.
- If Ayrshare returns `429` → pause workflow 04 for 30 min.

### Audit log

`workflow_runs` table stores:
`(id, workflow, entity_id, started_at, finished_at, status, cost_usd, error)`.

Telegram digest reads this to compute total daily LLM spend.

### Secrets

All credentials live in n8n's encrypted credential store. Nothing in the DB
or in Airtable. Service-account JSON for GDrive lives only in n8n.

### Manual override

The operator can bypass the entire chain by uploading a finished MP4 to a
special Drive folder `Manual/`. Workflow 01 detects this prefix and routes
straight to a row in `posts` with `status=approved`, skipping classification
and edit.
