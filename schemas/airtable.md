# Airtable base — UI / approval layer

Airtable is the **human interface** over Supabase. The operator never opens
Supabase directly. Every row in Airtable mirrors a row in Supabase via a
2-way sync (n8n syncs both ways with 30-second polling).

## Base name

**Kontent Zavod Ops**

## Tables

### 1) `Jobs`

| Field            | Type           | Notes                                  |
| ---------------- | -------------- | -------------------------------------- |
| Job ID           | Single line    | primary, e.g. 20260517-MOW-03          |
| Service          | Single select  | MOW / OVR / CLR / STM / TRE / POO / ...|
| Address          | Single line    |                                        |
| City             | Single line    |                                        |
| Scheduled for    | Date           |                                        |
| Customer name    | Single line    |                                        |
| Consent ✅       | Checkbox       | Reaction filming allowed?              |
| Status           | Single select  | scheduled / in_progress / done / cancelled |
| Clips count      | Rollup         | from Clips                             |
| Posts count      | Rollup         | from Posts                             |
| Last viral       | Rollup (max)   | from Posts.viral_label                 |
| Notes            | Long text      |                                        |

### 2) `Clips`

| Field            | Type           | Notes                                  |
| ---------------- | -------------- | -------------------------------------- |
| Clip ID          | Single line    | primary                                |
| Job              | Link           | → Jobs                                 |
| Cam              | Single select  | A / B / C / D                          |
| Duration (s)     | Number         |                                        |
| Thumbnail        | Attachment     | R2 thumb URL                           |
| Status           | Single select  | ingested / classified / rendered / rejected |
| Service          | Lookup         | from Job                               |
| Tags             | Multi select   | mood, overgrowth_level, etc.           |
| Slate transcript | Long text      |                                        |

### 3) `Queue`  *(the main approval table)*

| Field             | Type           | Notes                                                          |
| ----------------- | -------------- | -------------------------------------------------------------- |
| Post ID           | Single line    | primary                                                        |
| Thumb             | Attachment     | first frame                                                    |
| Preview MP4       | URL            | R2 pre-signed (30 min expiry)                                  |
| Hook              | Single line    |                                                                |
| Caption           | Long text      |                                                                |
| Hashtags          | Multi select   |                                                                |
| Platform          | Single select  | TT / IG / YT / FB                                              |
| Variant           | Single line    |                                                                |
| Viral score       | Number         | 0–100                                                          |
| Recommended       | Formula        | `IF(score>=80,'🔥', IF(score>=70,'👍','🤔'))`                  |
| **Approve ✅**    | Checkbox       | tap here = greenlight                                          |
| **Reject ❌**     | Checkbox       | tap here = archive                                             |
| **Edit hook**     | Single line    | optional override                                              |
| Scheduled at      | Date+Time      |                                                                |
| Auto-approve at   | Formula        | now() + 4h if score≥80                                         |
| Posted            | Checkbox       | flipped by workflow 04                                         |
| Created           | Created time   |                                                                |

The operator's main loop: open Queue view "Awaiting", scroll, tap ✅
or ❌, done. Approvals propagate to Supabase via n8n within 30 s.

### 4) `Posts`

| Field          | Type           | Notes                                       |
| -------------- | -------------- | ------------------------------------------- |
| Post ID        | Single line    | primary                                     |
| Job            | Link → Jobs    |                                             |
| Platform       | Single select  |                                             |
| Status         | Single select  | pending / approved / published / failed     |
| Published      | Date           |                                             |
| Views @ 24h    | Number         | synced from metrics                         |
| Views @ 7d     | Number         |                                             |
| Velocity ×     | Number         |                                             |
| Label          | Single select  | dud / ok / hit / viral / mega               |
| Permalink      | URL            |                                             |
| Recycle        | Single select  | (none) / cloning / cloned / archived        |

### 5) `Leads`

| Field         | Type           | Notes                                    |
| ------------- | -------------- | ---------------------------------------- |
| Lead ID       | Single line    | uuid                                     |
| Username      | Single line    |                                          |
| Source post   | Link → Posts   |                                          |
| Service       | Single select  |                                          |
| Address       | Single line    |                                          |
| Timeframe     | Single select  |                                          |
| Lead score    | Number         | 0–100                                    |
| Status        | Single select  | new / contacted / quoted / booked / done |
| Quoted price  | Currency       |                                          |
| Booked for    | Date           |                                          |
| Operator note | Long text      |                                          |
| Open chat     | URL            | t.me/c/...                                |

### 6) `Hooks`

| Field             | Type           | Notes                                  |
| ----------------- | -------------- | -------------------------------------- |
| Hook ID           | Single line    | primary                                |
| EN text           | Long text      |                                        |
| RU text           | Long text      |                                        |
| Category          | Single select  |                                        |
| Service tags      | Multi select   |                                        |
| Status            | Single select  | active / retired / promoted / draft    |
| Uses              | Number         |                                        |
| Avg retention 3s  | Number         | %                                      |
| Avg velocity ×    | Number         |                                        |
| Cooling until     | Date+Time      |                                        |

### 7) `Calendar` (view, not a table)

A calendar view over Posts grouped by `Scheduled at`. Use this to spot gaps
or overcrowded slots.

## Views (per table)

### Queue
- **Awaiting** — `Approve ✅ = false AND Reject ❌ = false AND Posted = false`
  sorted by Viral score ↓, limit 50.
- **Today's posts** — `Scheduled at = TODAY()`.
- **Auto-approved** — score ≥ 80.

### Leads
- **🔥 Priority** — score ≥ 70.
- **Awaiting reply** — status = `new`.
- **This week's bookings** — booked_for in next 7 days.

### Hooks
- **Top performers** — sorted by velocity ↓.
- **Retired** — for archival reference.
- **Draft proposals** — generated by workflow 06.

## Automations (Airtable-side, optional)

- When `Approve ✅` is checked → call n8n webhook to bump Supabase status.
- When `Reject ❌` is checked → same.
- Each midnight → email-style daily summary of approvals to operator.

## Sync architecture

n8n workflow `airtable-sync` runs every 30 s:

1. Pulls new Supabase `posts WHERE status='pending'` → creates Airtable Queue rows.
2. Pulls Airtable Queue rows where Approve/Reject were toggled → updates Supabase.
3. Pulls new metrics into Airtable Posts (denormalized for dashboard).

The Airtable base is **derived data**. The source of truth is Supabase.
If Airtable goes down, the factory keeps publishing; only the human UI is
offline.
