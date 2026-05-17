# 13 — Low-Budget Solo-Operator Playbook

The system was designed for one person, sub-$70/month infra, and 60-90
minutes of human time per day. This document is the survival manual.

> Spend money on equipment, not editors. Spend hours shooting, not editing.

---

## 1. Total monthly budget ceiling

```
Infra + APIs + tools                    ≤ $70 / mo
Music license (optional)                ≤ $15 / mo
Marketing (Telegram bot infra etc.)     ≤ $5 / mo
Reserve for hero-edit time / freelancer ≤ $50 / mo
────────────────────────────────────────────────
                                        ≤ $140 / mo
```

This is the **disciplined cap**. The factory delivers ROI inside this
budget by month 2.

---

## 2. Daily operator time budget

| Task                                  | Avg time / day      |
| ------------------------------------- | ------------------- |
| Shoot the Big-6 per job (3 jobs avg)  |  6 min × 3 = 18 min |
| SD-card sync at home                  |  5 min              |
| Approval taps in Airtable             |  3 min              |
| Telegram DM replies (5–15 leads)      | 20–30 min           |
| Strategy / review (every other day)   | 10 min              |
| **Total**                             | **~60 min / day**   |

The factory does **not** add to your fieldwork time. It piggy-backs on
work you were already doing.

---

## 3. Hardware kit (one-time)

| Item                              | Why                                | Approx. cost |
| --------------------------------- | ---------------------------------- | -----------: |
| Phone (iPhone 13+ or Pixel 7+)    | Main camera                        | already owned|
| Painter's pole / monopod          | High wide-angle static             |   $30        |
| Cheap tripod                      | Wide static + b-roll               |   $25        |
| GoPro Hero 10 (used)              | Equipment ASMR mount               |   $180       |
| DJI Mini 3 (used) or Mini 4 Pro   | Top-down before/after              |   $300–700   |
| Chest harness for phone           | POV walks                          |   $20        |
| 2 spare SD cards (256 GB)         | Reliability                        |   $40        |
| Mac mini / NUC (used)             | Home hub for rclone                |   $250       |
| **Total (used kit)**              |                                    |   **~$850**  |

You probably already have 50 % of this. The drone is the only big-ticket
item — and you can launch without one (start with phone-A wide static for
"before/after").

---

## 4. Software stack (recurring)

| Tool                              | Plan          | Cost / month   |
| --------------------------------- | ------------- | -------------: |
| n8n self-host (Hetzner CX22)      | $5            |  $5            |
| Render VPS (Hetzner CX42)         | $14           | $14            |
| Cloudflare R2 (300 GB)            | $0.015/GB     |  $4.50         |
| Supabase                          | Free          |  $0            |
| Airtable                          | Free (1 base) |  $0            |
| Postiz                            | self-host     |  $0            |
| Telegram bot                      | free          |  $0            |
| Gemini Flash + GPT-4o + Claude    | pay-as-go     | $20            |
| ElevenLabs Starter (optional)     | $5            |  $5            |
| Linkpop / Beacons                 | free          |  $0            |
| **Total**                         |               |  **$48.50**    |

---

## 5. The 7-day cold-start

Day 0: buy/borrow hardware, set up phone Drive auto-upload.
Day 1: provision n8n + render VPS + Supabase + R2 (3 hours).
Day 2: import workflow 01 + workflow 04. Test ingest + manual publish.
Day 3: import workflow 02 + 03. Render your first 5 shorts manually.
Day 4: hand-publish the 5 shorts. Watch what views look like.
Day 5: turn on workflow 04 cron. Let it auto-post.
Day 6: import workflow 05. Confirm metrics flow.
Day 7: import workflow 06. Schedule weekly digest.

**Day 8 onward:** factory runs itself. Operator only shoots and approves.

---

## 6. The 1-person workflow (steady state)

```
07:00  Drone + cameras charge (passive, while you make coffee)
07:30  Drive to job site
08:00  JOB 1 — Big-6 shoot (8 min), then work
12:00  JOB 2 — Big-6 shoot, then work
17:00  Drive home, SD cards sync as you walk in the door
17:30  Open Airtable on phone: tap-approve 5–8 variants (3 min)
17:35  Walk away
20:00  Open Telegram bot: reply to 10 inbound DMs (20–30 min)
21:00  Factory publishes auto-scheduled posts
21:30  Operator gets daily digest
22:00  Done. Phone down.
```

You can run the factory for a full year on this schedule.

---

## 7. What to outsource (in priority order)

When ROI allows (≥ 20 leads/week consistently):

1. **DM replies + qualification** — VA, $300/mo, 20h/week.
2. **Manual hero edits** — freelance editor on Upwork, $80–150 per hero,
   1 per week.
3. **Field shooter assistant** — local helper, $20/job, 5 jobs/week.
4. **Channel management** — VA expands to 30h/week.
5. **Lead booking** — VA takes ownership.

DO NOT outsource:

- ❌ The strategy review (Sunday).
- ❌ The shoot list quality.
- ❌ The Telegram persona (must remain the operator's voice).

---

## 8. Fail-safes for a solo operator

| Failure                                      | Mitigation                                       |
| -------------------------------------------- | ------------------------------------------------ |
| Operator sick for a week                     | Pre-queue 14 posts every Sunday; factory keeps publishing |
| VPS dies                                     | Hetzner snapshot weekly; restore in 20 min       |
| LLM provider outage                          | Pipeline pauses; queue resumes when restored     |
| Phone breaks                                 | Spare cheap Android, $150; reconfigure in 1 h    |
| Drone crashed                                | Skip C5 + C7 categories for that week            |
| Operator burned out                          | Factory has a `pause` flag → halts publishing    |

The single `system_state` row in Supabase has a boolean `paused` — flip it,
everything stops gracefully (no half-rendered videos).

---

## 9. Common pitfalls (and the cheap fix)

| Pitfall                                                   | Cheap fix                                      |
| --------------------------------------------------------- | ---------------------------------------------- |
| Over-editing — losing the "authentic" feel                 | Limit hero edits to 1/week                    |
| Shooting too much footage per job                          | Hard 5-minute shoot cap                        |
| Caption overthinking                                       | LLM-only captions for 90% of posts            |
| Posting same idea on all 4 platforms simultaneously        | Stagger 1–4 h, different hooks                 |
| Buying every new AI tool that launches                     | Lock the stack for 90 days at a time           |
| Ignoring DMs > 1 h                                         | Bot SLA alert at 30 min                        |
| Posting on holidays without adjusting                      | Seasonal triggers automate this                |
| Replying generically to comments                           | Use Telegram for relationship, comments are SEO|

---

## 10. The escape-velocity moment

You'll know the factory has hit escape velocity when:

- A single Sunday review takes 15 min instead of 60 min.
- A viral post hits without surprising you (you predicted the score).
- Inbound DMs become more about pricing than discovery.
- Strangers reference your videos in DM ("saw the swamp pool one").
- You can take a 2-day weekend and the factory doesn't notice.

Typical: month 4–6 with disciplined shooting.

---

## 11. ROI math (conservative)

Assume month-3 numbers:

- 600 000 views/month → 60 leads → 18 booked jobs.
- Avg ticket = 8 000 ₽ (~$85).
- Revenue: ~$1 500/mo.
- Cost: ~$50/mo infra + ~$0 (you do the work).
- **Net: ~$1 450/mo from the social channel alone.**

At month-6 with a VA + hero editor:

- 2.5M views/month → 250 leads → 90 booked jobs.
- Revenue: ~$7 600/mo.
- Cost: ~$450/mo (infra + VA + editor + ads-free).
- **Net: ~$7 150/mo.**

These numbers assume zero paid ads and zero email marketing — both of
which you can layer on top once cash is healthy.

---

## 12. The single rule

> Every day the factory runs without you touching it is a small win.
> Every day you have to "fix something" is a sign you over-engineered.
> When in doubt, do less, post more, and let the loop run.
