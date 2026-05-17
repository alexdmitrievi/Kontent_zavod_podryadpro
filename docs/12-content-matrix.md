# 12 — Content Matrix

The matrix defines **what kinds of videos** the factory produces, in what
ratio, with what emotional payload, with what algorithmic purpose, and with
what conversion purpose. The factory should never sit in any single
category — diversity itself is an algorithm signal.

Twelve categories. Each is a row in the matrix.

---

## 1. The twelve categories

| #  | Category                | % of weekly output | Emotion        | Algo purpose              | Conversion purpose            |
| -- | ----------------------- | -----------------: | -------------- | ------------------------- | ----------------------------- |
| C1 | Hero transformations    |              25 %  | awe + contrast | viral spike               | first impression              |
| C2 | ASMR / sensory          |              15 %  | calm + payoff  | replays, completion       | retention, brand vibe         |
| C3 | Educational tips        |              10 %  | curiosity      | saves, comments           | authority, trust              |
| C4 | Funny / outtakes        |              10 %  | joy            | shares                    | humanization                  |
| C5 | Local authority         |               8 %  | pride          | local distribution        | "they're our guys"            |
| C6 | Machinery beauty        |               8 %  | mastery        | replays                   | high-margin services teaser   |
| C7 | Time-lapse              |               7 %  | productivity   | completion                | "they get it done fast"       |
| C8 | Dramatic deep cleans    |               7 %  | shock          | viral spike               | high-ticket services          |
| C9 | Customer reactions      |               5 %  | empathy        | shares, comments          | social proof                  |
| C10| "Day in the life"       |               3 %  | parasocial     | follows                   | channel subscribe             |
| C11| Hyper-satisfying loops  |               1 %  | satisfaction   | replays                   | nothing direct (brand vibe)   |
| C12| Seasonal & topical      |               1 %  | timely         | discoverability via trends| timely service offers         |

Volumes auto-balanced by workflow 03: if a category is over-represented in
the last 14 days, the candidate selector deprioritizes it.

---

## 2. C1 — Hero transformations (25 %)

The backbone of the channel. Big before, work montage, big after.

- Services: OVR, CLR, POO, MNT, PLW
- Templates: T01, T02, T04
- Hooks: H001–H020, H041, H100
- Duration: 18–30 s
- Audio: rising tension → release
- Captions: numbers + scale ("4 years, 3 hours")
- Posting time: prime evening slot (20:00–21:00)

These are your **trailer**. Every new viewer should hit one within their
first 3 videos discovered.

---

## 3. C2 — ASMR / sensory (15 %)

Pure texture videos. No narrative.

- Services: MOW, POO (skim), STM, CLR (chipping)
- Templates: T05 only
- Hooks: H021–H030
- Duration: 10–18 s
- Audio: diegetic, boosted, no music
- Captions: minimal, often only the hook

Won't viral as hard as C1 but **disproportionately** boosts completion rate
and replays. The algorithm uses these to validate your account quality.

---

## 4. C3 — Educational tips (10 %)

Short authority bursts.

- Services: any
- Templates: T08 (educational variant)
- Hooks: H056, H052, H092 (and custom expert hooks)
- Duration: 25–40 s
- Audio: voice + light bed
- Captions: full-text "3 things to check on a 20-year-old tree" lists

Saved more than they're liked. Build up over months. Drive Telegram subs
because viewers want a "useful" channel.

---

## 5. C4 — Funny / outtakes (10 %)

Equipment fails, mud splatters, surprise wildlife, operator's stunned face.

- Templates: T07, T08
- Hooks: free-form, often improvised on shoot
- Duration: 10–20 s

These videos **share** like crazy on FB Reels especially. They humanize
the brand. Run them once or twice a week to keep the algorithm from
locking you into a "serious worker" niche.

---

## 6. C5 — Local authority (8 %)

City name + landmark + crew at work.

- Services: any
- Templates: T08, T04
- Hooks: H081–H090
- Duration: 15–25 s

Carefully crafted to look like a local news segment without being one.
Best posted on FB Reels and IG Reels — TT cares less about local cues.

---

## 7. C6 — Machinery beauty (8 %)

Worship-shot equipment. Slow camera moves. ASMR-adjacent but with narrative.

- Services: STM, TRE, MOW (industrial), CLR
- Templates: T05, T06
- Hooks: H083, H058, custom
- Duration: 12–22 s

Useful for high-margin services where the equipment itself is the
differentiator (stump grinders, mulchers, brushcutters).

---

## 8. C7 — Time-lapse (7 %)

6 hours in 12 seconds.

- Services: MOW (large), OVR, CLR, PLW
- Templates: T03 only
- Hooks: H011, H093, H098
- Duration: 10–15 s

Algorithm gold for completion rate because the viewer is locked into
"watch till the end". A few of these per month should hit viral easily.

---

## 9. C8 — Dramatic deep cleans (7 %)

The "Niagara Falls of grossness" category. Green pools, sewage backups,
trash-yards.

- Services: POO, OVR
- Templates: T01, T02, T06
- Hooks: H061–H070, H034, H038
- Duration: 18–35 s

Use sparingly — they drive views but can rub some viewers the wrong way.
Especially powerful on TikTok and FB Reels. Tone caption non-judgmental
("the owner was overseas for 3 years; we got the call yesterday") to
avoid mockery.

---

## 10. C9 — Customer reactions (5 %)

Real reactions. Always with consent.

- Templates: T07
- Duration: 12–20 s

Lowest volume, highest conversion. Even 1 customer-reaction video per week
can produce 10× the leads per view of a transformation video.

---

## 11. C10 — Day in the life (3 %)

The operator's POV: morning prep, the drive, the lunch, the rough job.

- Templates: T08, casual
- Duration: 30–60 s
- Hooks: free-form

Lowest views per post but **highest** Telegram-subscribe conversion.
These videos are not trying to viral; they're trying to retain.

---

## 12. C11 — Hyper-satisfying loops (1 %)

The 7-second flawless loop. No narrative.

- Templates: T05, T06
- Duration: 7–10 s

One every 1–2 weeks is enough. The system uses these to top up replay
metrics platform-wide.

---

## 13. C12 — Seasonal & topical (1 %)

Storm coming → "book a tree assessment". Spring → "first mow checklist".
Heat wave → "yard fire risk". Always timely.

- Duration: 25–40 s
- Hooks: timeliness-based

These get posted as soon as the trigger event happens. The factory keeps a
small list of seasonal cues in `seasonal_triggers` and the LLM checks it
weekly.

---

## 14. The matrix in practice — a sample week

```
Mon  C1 (hero, OVR)              TT 21:00  IG 19:00
     C2 (ASMR, MOW)              TT 18:00
     C3 (educational, TRE)       YT 17:00
Tue  C1 (hero, POO)              TT 21:00  IG 19:00  FB 20:00
     C6 (machinery, STM)         TT 18:00
Wed  C9 (reaction, OVR)          TT 21:00  FB 20:00
     C2 (ASMR, POO skim)         IG 12:00
     C8 (deep clean, POO)        TT 18:00  IG 19:00
Thu  C1 (hero, CLR)              TT 21:00  IG 19:00  YT 17:00
     C4 (funny, MOW + bee)       FB 20:00
Fri  C7 (time-lapse, MOW big)    TT 21:00  IG 19:00
     C5 (local authority)        FB 20:00  IG 12:00
Sat  C1 (hero, STM)              TT 21:00  IG 19:00
     C2 (ASMR, CLR chip)         TT 18:00
Sun  C10 (day in life)           IG 12:00  Telegram channel
     C12 (seasonal: storm tip)   FB 20:00  YT 17:00
```

Across the week: 23 posts, 9 unique videos, hits all 12 categories at
least once a month with this weekly cadence.

---

## 15. How the matrix is enforced

Workflow 03's candidate selector reads two tables:

- `category_targets` — the % per category from §1.
- `category_actuals` — rolling 14-day actual %.

For each new clip, candidates are scored not only by viral score but by
**category gap**: a category 3 % below target gets a +5 score bonus, a
category 3 % above target gets a −5 penalty. This keeps the diet balanced
without ever shipping a low-quality post just to hit a quota.

---

## 16. Hidden rule — the "personality" thread

One out of every ~25 videos should be **uncategorizable**:

- A weird shot from a job.
- The operator's dog in the truck.
- A 7-second video of mud sliding off a tire.
- A polaroid of a sunset over a finished property.

These videos confuse the algorithm in a useful way (broaden distribution)
and remind viewers there's a real person behind the brand.

The system flags these as `category=PERSONALITY` and they bypass the
viral-score gate. They are limited to 4 per month max.
