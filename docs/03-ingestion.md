# 03 — Raw Content Ingestion System

This document is for the **operator in the field**. It defines what to shoot,
how to shoot it, and how it lands in the cloud without a single drag-and-drop.

The system's #1 job is to be **invisible**: you point the phone, you do the
job, you go home, your phone Wi-Fi uploads, and 90 minutes later finished
videos are waiting in your Airtable queue.

---

## 1. Shot list — the "Big 6" (every job, every time)

| #  | Shot                     | Camera     | Duration | Why                              |
| -- | ------------------------ | ---------- | -------- | -------------------------------- |
| 1  | Drone top-down BEFORE    | Drone (C)  | 8–15 s   | The hero "before" reveal         |
| 2  | Phone wide BEFORE        | Phone-A    | 10–20 s  | Establishes scale, eye-level     |
| 3  | Handheld walk-through    | Phone-B    | 20–40 s  | Detail shots, mess, problem      |
| 4  | Equipment action         | Action (D) | 30–60 s  | ASMR, "the work happening"       |
| 5  | Drone top-down AFTER     | Drone (C)  | 8–15 s   | Hero "after" reveal              |
| 6  | Phone wide AFTER + slate | Phone-A    | 10–20 s  | Closes the loop. Talk to camera. |

**Total raw footage / job: 1.5–3 min.** Anything more is gravy.

Voice slate at start of shot #1:
> *"Address: Lenina 47. Service: overgrown cleanup. Date: May 17. Before."*

Voice slate at start of shot #6:
> *"After. Time taken: 3 hours. Equipment: brushcutter + tractor."*

Whisper transcribes the slate; the parser auto-fills the DB job metadata.

---

## 2. Camera setup

### Phone — A (wide static)

- Tripod or 5 m painter's pole, locked at chest height.
- 1080p60 (TikTok-native) — **not** 4K (wastes upload).
- Wide lens (0.5×) on iPhone, ultra-wide on Android.
- HDR **off**. Stable lighting only.

### Phone — B (handheld POV)

- Same phone if no second device; switch lens.
- Use stabilization (gimbal if budget allows, otherwise built-in).
- 1080p60.

### Drone — C

- DJI Mini 4 Pro / Mini 3 Pro. Even Mini 2 works.
- Pre-saved waypoint mission for top-down + 30° push-in is ideal.
- 4K30 for drone only — its native compression is good.

### Action cam — D

- GoPro Hero 10/11/12 or Insta360 Ace Pro.
- Mount on:
  - mower deck (front-facing) for grass-spray ASMR,
  - chainsaw arm-strap for stump grinding,
  - pool skimmer pole for pool cleanup.
- 1080p60, narrow FOV, audio on.

### Audio

- Phone-A and Phone-B record built-in.
- Action cam records built-in (engine, blade, water).
- **No external mic needed.** ASMR is the point.
- Lavalier optional for verbal customer reactions ("look at it now!").

---

## 3. Auto-upload pipeline

### iPhone (operator's phone)

```
iCloud Photos → "Shared Album: Job-Inbox"
       │
       └── Mac mini / NUC at home (1 W idle)
              │
              └── Hazel / hammerspoon rule:
                  watch ~/Pictures/SharedAlbum/Job-Inbox
                  rclone copy ./Job-Inbox r2:kontent-raw/inbox/{date}/
                  Telegram ping: "📥 N new files uploaded"
```

### Android

```
DCIM/Camera → FolderSync app → Google Drive /Inbox/
       │
       └── n8n workflow 01 watches /Inbox/ every 5 min
```

### Drone & action cam (SD cards)

- Once a week: pop SD into Mac mini.
- `rclone sync /Volumes/DJI r2:kontent-raw/inbox/{date}/drone/`
- `rclone sync /Volumes/GoPro r2:kontent-raw/inbox/{date}/action/`

### Why R2 directly?

Cloudflare R2 has **$0 egress**. Whisper + FFmpeg on the VPS stream the file
back from R2 without paying twice. With S3 you'd pay egress for every render
attempt.

---

## 4. Folder taxonomy (R2)

```
kontent-raw/
├── inbox/
│   └── 2026-05-17/
│       ├── phone-A/
│       │   ├── IMG_4521.mp4
│       │   └── IMG_4522.mp4
│       ├── phone-B/
│       ├── drone/
│       └── action/
├── raw/
│   └── 2026/
│       └── 05/
│           └── 17/
│               └── 20260517-MOW-03/                ← job_id
│                   ├── 20260517-MOW-03-A-001.mp4  ← clip_id
│                   ├── 20260517-MOW-03-A-002.mp4
│                   ├── 20260517-MOW-03-B-001.mp4
│                   ├── 20260517-MOW-03-C-001.mp4
│                   ├── 20260517-MOW-03-D-001.mp4
│                   └── _meta/
│                       ├── ffprobe.json
│                       ├── transcript.srt
│                       └── classification.json
├── processed/                                       ← rendered shorts
│   └── 2026/05/17/
│       ├── 20260517-MOW-03-A-001-TT-v1.mp4
│       └── ...
└── thumbs/
    └── 20260517-MOW-03-A-001.jpg
```

`inbox/` is the **dirty zone** — workflow 01 owns it and moves files out.
`raw/` is the **clean source of truth** — nothing deletes from it ever.

---

## 5. Auto-sorting & classification

When workflow 01 picks up a file from `inbox/`, it runs **3 enrichments**
before insert:

1. **Camera inference** — filename pattern:
   - `IMG_*.MOV`, `IMG_*.MP4` → phone (A or B by aspect + EXIF lens)
   - `DJI_*.MP4` → drone (C)
   - `GH*.MP4`, `GX*.MP4` → GoPro (D)
   - `INS_*.MP4`, `LRV_*.MP4` → Insta360 (D)
2. **Job grouping** — files captured within ±90 min of each other and within
   200 m GPS distance (EXIF) → same `job_id`.
3. **Verbal slate parse** — Whisper transcribes the first 8 s. Regex pulls:
   - service: e.g. "lawn mowing" → `MOW`
   - state: e.g. "before" → `phase=before`
   - address: regex on street names + number

A `clips` row is now ready for downstream classification (workflow 02).

---

## 6. Metadata tagging (post-classification)

After workflow 02, each clip carries this tag bundle:

```json
{
  "service": "OVR",
  "phase": "before",
  "scene": "yard",
  "time_of_day": "afternoon",
  "weather": "clear",
  "mood": "abandoned",
  "overgrowth_level": 8,
  "water_state": null,
  "machinery_visible": false,
  "people_visible": false,
  "best_for_template": ["T02_chaos_to_order", "T05_machinery_asmr"]
}
```

These tags are the joinery between **clips** and **render templates**.
A "T02_chaos_to_order" needs at least one BEFORE clip with overgrowth_level
≥ 6 **and** one AFTER clip from the same `job_id`.

---

## 7. AI classification call (Gemini 1.5 Flash)

Single multimodal call per clip, 5 stills + 1 prompt:

```text
You analyze landscaping/property-services footage for a viral content
factory. Return strict JSON. Schema:

{
  "service": one of [MOW, OVR, CLR, STM, TRE, POO, MNT, RNT, PLW, CLN, OTHER],
  "phase": one of [before, during, after, unknown],
  "scene": short label e.g. "front_yard", "pool_deck", "wooded_lot",
  "time_of_day": one of [morning, midday, afternoon, evening, night],
  "weather": one of [clear, overcast, rain, snow, unknown],
  "mood": one of [abandoned, neglected, normal, polished, dramatic],
  "overgrowth_level": int 0..10,
  "water_state": one of [green, brown, clear, empty, n/a],
  "machinery_visible": bool,
  "people_visible": bool,
  "viral_kind": one of [
     "transformation", "asmr", "drone_reveal",
     "speed_ramp", "reaction", "educational", "none"
  ]
}

If unsure, use "unknown" / null. No prose, JSON only.
```

Cost: ~$0.002 / clip. 5 frames is enough for everything except very dense
overgrowth — where we sample 8 frames.

---

## 8. Quality bar at ingest

A clip is **rejected** (status=`rejected`, archived) if any of:

- duration < 4 s or > 8 min,
- resolution < 720p,
- average brightness < 25/255 (dark),
- audio = pure silence AND it's not a drone shot,
- duplicate sha256 of an existing clip.

Rejections are still logged. The operator sees a daily summary.

---

## 9. Field operator's daily flow (the human side)

```
07:30  Charge drone + action cam + 2 phones. Pack tripod.
08:00  Job 1: shoot Big-6, hit GO on "Job-Inbox" auto-upload.
12:30  Job 2: same.
17:30  Home. Drop SD cards into Mac mini, rclone runs.
17:35  Done. Walk away.
       ─────────────────────────────────────────
       (System runs 90 min in the background.)
20:00  Open Airtable on phone. Approve 5–8 variants in 30 s.
20:30  System publishes overnight + tomorrow.
```

That's the only manual loop. Shoot → sync → tap approvals.

---

## 10. Failure modes (field-level)

| Problem                       | Fix                                                |
| ----------------------------- | -------------------------------------------------- |
| Forgot the verbal slate       | System falls back to filename + GPS for tagging    |
| Drone footage missing         | T01/T02 still render off phone-A wide              |
| Action cam audio clipped      | FFmpeg normalizes; we can also overlay music       |
| Vertical shot when needed wide| `ffmpeg crop=ih*9/16` from center; flag for reshoot|
| Wi-Fi died at the house       | Files queue in iCloud, upload when reconnected     |
| SD card corrupted             | `photorec` recovery; log loss in `incidents` table |
