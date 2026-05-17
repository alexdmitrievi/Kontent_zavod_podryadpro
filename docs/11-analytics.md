# 11 — Analytics & Optimization Engine

The factory is a feedback loop. Without measurement, it's just a slot
machine. This document defines the metrics, formulas, dashboards, A/B
mechanics, and the **automatic viral-cloning** logic.

---

## 1. The five questions the analytics engine answers

1. **Did this post fire?** (viral velocity vs. platform baseline)
2. **Why did it fire / die?** (hook, template, time, music, score)
3. **What should we publish next?** (winners → clones, losers → retire)
4. **Are we converting?** (views → bio → bot → DM → lead → booked)
5. **What are we spending?** (LLM, infra, time per produced video)

Every dashboard ties back to one of these.

---

## 2. The data model

Three core fact tables in Supabase:

### `posts`

```sql
post_id, candidate_id, clip_id, job_id, service,
template, hook_id, hook_text,
platform, variant,
published_at, scheduled_at,
caption, hashtags[], cta_strategy,
viral_score_pre,            -- LLM score before publish
viral_label,                -- dud/ok/hit/viral/mega
viral_velocity,             -- views per hour normalized
recycle,                    -- null / archived / cloned
manual                      -- true if hero edit
```

### `metrics`

```sql
post_id, captured_at, hours_since_publish,
views, likes, comments, shares, saves,
avg_watch_time_seconds, completion_rate,
ret_3s, ret_10s, ret_25s,
profile_visits, link_clicks
```

One row per (post × time window). Time windows: t+1h, t+6h, t+24h, t+72h,
t+7d, t+30d.

### `funnel_events`

```sql
event_id, ts, platform, post_id,
event_type,   -- bio_click | bot_start | sub | quote_start | quote_done | lead | booked
user_hash,    -- hashed Telegram user id
utm_source, utm_medium, utm_campaign
```

### `llm_calls` and `workflow_runs` (already defined in `docs/02-n8n-workflows.md`)

---

## 3. Viral velocity (the core metric)

We don't just look at raw views — we look at **velocity normalized by
platform baseline**:

```
velocity_raw = views / hours_since_publish
baseline     = median(views_at_24h) for last 200 posts on this platform
velocity_pct = views_at_24h / baseline
```

A post with `velocity_pct > 5.0` at t+24h is a `viral`.
A post with `velocity_pct > 25.0` at t+24h is a `mega`.

This **adapts to your account growth**. As baseline grows, the bar grows.

---

## 4. Viral label thresholds

(Seeded, then auto-recalibrated weekly.)

Same table as `docs/02-n8n-workflows.md` §5 — `dud / ok / hit / viral / mega`.

Recalibration formula (workflow 06):

```
For each platform:
   take last 200 posts (excluding manual=true)
   compute percentile bands at p25, p75, p95, p99
   set dud = below p25
   set ok = p25 – p75
   set hit = p75 – p95
   set viral = p95 – p99
   set mega = above p99
```

---

## 5. Hook performance table

Every hook in `docs/06-hooks.md` is tracked:

```
hook_id, uses_count, avg_ret_3s, avg_completion, avg_velocity_pct,
last_used_at, cooling_until, status (active | retired | promoted)
```

A hook is **auto-retired** if:
- used > 10 times, AND
- avg velocity < 0.5× baseline.

A hook is **auto-promoted** to "core" (preferred selection) if:
- used > 5 times, AND
- avg velocity > 2× baseline.

The cooling period is 30 days per platform after each use.

---

## 6. Template performance table

Same idea, per template (T01..T08), per service, per platform:

```
template, service, platform, n_posts,
avg_velocity_pct, avg_completion, avg_ret_3s
```

This produces a 3-dimensional heat-map the operator can review weekly.
Workflow 06 reads this table when generating clone variants — it biases
toward the top-performing template per (service × platform).

---

## 7. A/B testing — automated

Every clip enters the system producing **multiple variants**:

- 2 hook variants × 4 platforms = up to 8 variants per clip.
- Sometimes 2 templates × 2 hooks = up to 4 unique creatives.

These variants are automatic A/B tests. Statistical comparison runs in
workflow 06:

```
H0: variants of the same clip have equal velocity_pct
test: Mann–Whitney U (non-parametric, robust to outliers)
significance: p < 0.10  (we tolerate moderate noise, this isn't pharma)
```

If a variant wins significantly, the system:

- promotes the winning hook (more weight in selection),
- promotes the winning template for that (service × platform),
- retires the losing variant.

---

## 8. Automatic viral cloning

The mechanism that makes this factory **compound**.

```
TRIGGER: a post hits viral_label ∈ {viral, mega} at t+24h
ACTION (workflow 06, but also immediate):
  - mark post.recycle = 'cloning'
  - dispatch 3 clone specs to workflow 03:
      Spec A: same footage, NEW hook (different category)
      Spec B: new edit template, same hook
      Spec C: same hook + footage, different first 1.5 s pacing
  - publishes clones over the next 7 days, max 1/day same platform
```

Why 3 not 10:
- More than 3 variants of the same idea = obvious recycle to the algorithm.
- Different angle, different template, different pacing is enough.

Clone results re-enter the loop. If a clone outperforms the original,
the operator gets a Telegram nudge:

> "🔁 Clone {post_id}-c2 outperformed original by 1.8×. Want to clone
> the clone? [Yes] [No]"

---

## 9. Hook + template heat-map (the operator's weekly review)

Generated every Sunday at 22:30, posted as a Markdown table to the
operator's Telegram. Example:

```
Top 5 (last 7 days, all platforms)
1. H007  "Grass was taller than I am."        velocity 6.2× | 4 posts
2. H062  "The water was BLACK."               velocity 5.4× | 3 posts
3. T05   ASMR template (POO + STM)            velocity 3.9× | 11 posts
4. H037  "The reveal at 0:15 is wild."        velocity 3.6× | 2 posts
5. T01   Before-After Split (OVR)             velocity 3.1× | 14 posts

Bottom 5
1. H049  "Pay once. Look at this for a decade." velocity 0.3×
2. T08   Generic (no service tag)              velocity 0.4×
...

Action proposed (auto-queued for your approval):
- Retire H049 from active bank
- Cool H062 for 2 weeks (over-used)
- Generate 4 new variants of H007 for next week
- Promote T01 OVR to "always available"
```

---

## 10. Funnel attribution dashboard

The operator's daily Telegram digest at 21:00:

```
📊 24h FACTORY DIGEST — May 17, 2026

PUBLISHED       9 posts (TT 4, IG 3, YT 1, FB 1)
VIEWS           184k total
TOP POST        20260517-OVR-02-A-001-TT-v2   86k views | 8.4× baseline 🔥
WORST           20260516-MOW-04-B-002-YT-v1   140 views | 0.1× baseline

FUNNEL
  Bio clicks         412
  /start events      183  (44%)
  Channel subs       127  (69%)
  Quote starts        38  (21%)
  Quotes completed    23  (61%)
  New leads           23  (booked: 0 so far)

SPEND
  LLM today       $1.27
  Storage today   $0.18
  VPS prorated    $0.63
  ────────────
  TOTAL TODAY     $2.08

ALERTS  (none)
ACTIONS NEEDED
  - 6 queue items pending approval (4h SLA)
  - 1 lead waiting > 35 min: tap → t.me/c/...
```

---

## 11. Long-tail tracking

Some videos peak weeks later. The metrics scheduler keeps polling for
**60 days**, with reducing frequency:

```
t+1h, t+6h, t+24h, t+48h, t+72h, t+7d, t+14d, t+30d, t+60d
```

Posts that suddenly spike on day 12 (common on YT Shorts) get re-classified
into `mega` and trigger the same cloning pipeline.

---

## 12. Lead-quality scoring

Not every DM is equal. The bot assigns a lead score 0–100:

```
+30   service matches a high-margin job (TRE, POO, STM)
+25   timeframe = "this week"
+20   address in core service area
+15   answered all 3 qualifier questions
+10   subscribed to channel before quote
+5    came from a "viral" post (engagement signal)
-20   answered "just exploring"
-10   address outside service area
```

Leads ≥ 70 get auto-tagged `priority` and surfaced first to the operator.
This becomes the operator's pin-board in `@KontentZavodOps`.

---

## 13. Operator KPIs (weekly card)

Every Monday morning, the operator gets a one-card weekly summary:

```
WEEK OF May 11 – May 17, 2026

Unique videos produced       18  (target 20)
Total posts published        52
Average viral_score_pre      71.4
Average velocity_pct          1.34×
Winners (auto-cloned)         3
Losers (auto-archived)        9
Leads                         62
Booked jobs (manual)          9
Estimated revenue (booked)    127 000 ₽
Cost (infra + LLM + tools)    3 600 ₽
────────────────────────────────────────
ROI multiple                  35.3×
```

When ROI multiple drops below 5× for two consecutive weeks, the factory
auto-throttles posting volume by 30 % and Telegram alerts the operator to
investigate (this prevents drowning a fatigued account).

---

## 14. What the operator does with this data

Twice a week, 20 minutes total:

- **Mon 09:00 — review weekly card.** Adjust shoot plan if a service
  category is over- or under-represented.
- **Sun 22:30 — read winners & retire list.** Approve hook retirements
  and any borderline-quality auto-clones.

That's it. The rest is automated.
