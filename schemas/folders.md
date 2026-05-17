# Storage folder taxonomy

The factory uses three storage tiers. Everything in this repo references
exactly these paths.

## Tier 1 — Hot scratch (Google Drive)

```
KontentZavod/                              ← Google Drive root
├── Inbox/                                 ← ALL phone uploads land here
│   ├── _archived/                         ← moved after ingest
│   │   └── 2026-05/
│   └── _duplicates/                       ← sha256 collisions
├── Manual/                                ← bypass auto pipeline; publishes as-is
├── Hero/                                  ← raw clips chosen for hand edits
│   └── 20260517-OVR-02/
└── _ops/
    ├── checklists/                        ← printable shot lists
    └── consent_forms/
```

- Quota: 15 GB free; upgrade to 100 GB at $2/mo when needed.
- Retention: ingest workflow moves files to `_archived/` after success.
  Hard-delete `_archived/` files after 7 days (separate weekly workflow).

## Tier 2 — Cold (Cloudflare R2)

Bucket: `kontent-zavod`

```
kontent-zavod/
├── inbox/                                 ← optional mirror of Drive Inbox
│   └── 2026-05-17/
├── raw/                                   ← canonical source of truth
│   └── 2026/05/17/20260517-MOW-03/
│       ├── 20260517-MOW-03-A-001.mp4
│       ├── 20260517-MOW-03-A-002.mp4
│       ├── 20260517-MOW-03-B-001.mp4
│       ├── 20260517-MOW-03-C-001.mp4
│       ├── 20260517-MOW-03-D-001.mp4
│       └── _meta/
│           ├── ffprobe.json
│           ├── transcript.srt
│           ├── classification.json
│           └── consents.json
├── processed/                             ← rendered, ready-to-post
│   └── 2026/05/17/
│       ├── 20260517-MOW-03-A-001-TT-v1.mp4
│       ├── 20260517-MOW-03-A-001-TT-v2.mp4
│       └── 20260517-MOW-03-A-001-IG-v1.mp4
├── thumbs/                                ← cover frames
│   ├── 20260517-MOW-03-A-001.jpg
│   └── covers/
│       └── 20260517-MOW-03-A-001-TT-v2.jpg
├── manual/                                ← hand-edited finals
└── exports/                               ← weekly backups + analytics CSVs
    └── 2026-W20/
        ├── posts.csv
        ├── metrics.csv
        └── leads.csv
```

- Egress cost: $0.
- Storage cost: $0.015/GB-month.
- Estimated steady state: 300 GB → ~$4.50/mo.

## Tier 3 — Metadata (Supabase)

See `schemas/supabase.sql` for the full schema.

## Naming conventions (single source of truth)

```
JOB_ID    = {YYYYMMDD}-{SERVICE}-{SEQ}             e.g. 20260517-MOW-03
CLIP_ID   = {JOB_ID}-{CAM}-{SHOT}                  e.g. 20260517-MOW-03-A-001
RENDER_ID = {CLIP_ID}-{PLATFORM}-{VARIANT}         e.g. 20260517-MOW-03-A-001-TT-v2
COVER_ID  = same as RENDER_ID, with .jpg

SERVICE  ∈ {MOW, OVR, CLR, STM, TRE, POO, MNT, RNT, PLW, CLN, OTHER}
SEQ      = zero-padded counter per day per service (01..99)
CAM      ∈ {A, B, C, D}
SHOT     = zero-padded counter (001..999)
PLATFORM ∈ {TT, IG, YT, FB}
VARIANT  ∈ {v1, v2, v3, ...}
```

## Rules

- **Never rename**. The whole system depends on these IDs being stable.
- **Never delete from `raw/`**. The future viral-clone pipeline reads it.
- **Never put non-MP4 video in `processed/`**. The publisher only accepts MP4.
- **Always write a `_meta/` JSON** alongside every raw clip. It's the
  audit trail.

## Lifecycle

| Tier         | What it holds                | Lifetime         | Auto-action                   |
| ------------ | ---------------------------- | ---------------- | ----------------------------- |
| Drive Inbox  | new phone/SD uploads         | hours            | moved to R2 by workflow 01    |
| Drive _arch  | already-ingested originals   | 7 days           | hard-deleted weekly           |
| Drive Manual | operator's hand-edits        | 14 days          | moved to R2 manual/           |
| R2 raw       | source of truth              | ∞                | never deleted                 |
| R2 processed | rendered shorts              | 90 days          | cold-tier after 90 days       |
| R2 thumbs    | covers                       | 90 days          | regenerable from raw          |
| R2 exports   | weekly metrics backup        | 1 year           | cold-tier after 30 days       |

## Backup

Every Sunday 23:00:

```bash
# Supabase logical backup
supabase db dump --file backups/$(date +%Y-W%V).sql
rclone copy backups/ r2:kontent-zavod-backups/db/

# Airtable CSV export (per table)
n8n workflow: airtable-export → R2 exports/...

# n8n workflow JSON export
n8n export:workflow --all > backups/n8n-$(date +%Y-W%V).json
rclone copy backups/ r2:kontent-zavod-backups/n8n/
```

Restore drills: every 90 days, restore on a fresh Hetzner VPS and confirm
all workflows fire correctly against the restored Supabase.
