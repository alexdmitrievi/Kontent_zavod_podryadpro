# 05 — Viral Content Engine

This document is the **strategy DNA** of the factory. Every hook, every edit,
every caption derives from the seven viral frameworks below — all tuned to
this exact niche (landscaping / property cleanup / pool / trees / land).

The frameworks aren't decoration. They are encoded into prompts and into the
edit-template selector, so the AI cannot generate "generic" content — every
output maps to one of these structures.

---

## 1. The seven viral frameworks

### F1 — **Chaos → Order**

> Open on extreme mess. Pay off with extreme tidiness.

- Duration: 15–30 s
- Best for: OVR, CLR, CLN, PLW
- Trigger: contrast magnitude
- Psychology: pattern completion, dopamine on resolution
- Template: T02_chaos_to_order

Open frame: visceral overgrowth, garbage, weeds. Middle: 60 % of the clip
is the WORK happening (machinery sounds). Last 3 s: the after, locked-off
on the SAME camera angle as the open.

### F2 — **Forbidden Reveal**

> Open on something the viewer "shouldn't" see — abandonment, decay.

- Duration: 7–12 s
- Best for: POO (green pool), TRE (dangerous trees), OVR (jungle yards)
- Trigger: curiosity gap + mild taboo
- Psychology: voyeurism, "I have to see what's under that"
- Template: T06_curiosity_loop

The hook explicitly *promises* a reveal: *"Watch what we found under
this pool cover."* The reveal lands at 80–90 % of the clip, not at the end —
viewers tend to loop after the reveal.

### F3 — **ASMR Loop**

> No narrative. Just texture, sound, rhythm.

- Duration: 10–20 s
- Best for: MOW, STM, POO (skim), CLR (chipping)
- Trigger: sensory satisfaction, parasympathetic response
- Psychology: low-effort dopamine, infinite replay
- Template: T05_machinery_asmr

Tight close-up on the cutting interface (blade meeting grass, skimmer
meeting water, grinder eating wood). Audio is 80 % of the value — boost
mids, gentle compression, no music.

### F4 — **Drone Reveal**

> Wide aerial frames the scale of the problem and the resolution.

- Duration: 8–14 s
- Best for: OVR, CLR, MNT, PLW
- Trigger: scale shock, "I didn't realize how big this is"
- Psychology: god-view, mastery
- Template: T04_drone_reveal

Open: top-down on chaos, holds 3 s. Middle: push-in or pan-down to ground.
End: top-down on order, holds 3 s on the same frame composition as opening.

### F5 — **Speed Ramp Time-Lapse**

> Show 6 hours of work in 12 seconds.

- Duration: 10–15 s
- Best for: MOW (big yards), OVR, CLR
- Trigger: time compression, productivity
- Psychology: "feels like I accomplished something just watching"
- Template: T03_time_lapse

Static or hyperlapse camera. Speed ramps from 8× → 1× at the moment of
the final reveal. Adds a "phew" beat at the end.

### F6 — **Reaction / Reveal-to-customer**

> Camera on the customer's face when they first see the result.

- Duration: 10–18 s
- Best for: any service
- Trigger: emotional contagion (we copy the reaction)
- Psychology: parasocial trust, "they're crying so it must be that good"
- Template: T07_reaction_split

Split-screen: left = the after, right = the customer's face. Audio is
their reaction. Captions translate / amplify what they say.

> ⚠️ Always get explicit verbal consent on-camera before publishing
> a reaction shot. We store consent in the `consents` table per job.

### F7 — **Educational Pattern Interrupt**

> Drop a sharp local-pro fact in the first 1.5 s, prove it with footage.

- Duration: 20–35 s
- Best for: TRE (safety), POO (chemistry), STM (root depth)
- Trigger: status / authority
- Psychology: "this person actually knows what they're doing"
- Template: T08_generic_short with overlay variant

Useful for building **trust** so the F1–F6 transformation videos convert.
Even if low-view, they massively lift the funnel.

---

## 2. The six dopamine triggers

Every viral candidate is scored against how many of these it activates.

| Trigger          | What it is                                | Activated by                  |
| ---------------- | ----------------------------------------- | ----------------------------- |
| **Contrast**     | Big visual delta in short time            | F1, F4, F5                    |
| **Curiosity**    | Open loop the viewer has to close         | F2, F7                        |
| **Sensory**      | ASMR, satisfying texture/sound            | F3, F5                        |
| **Status**       | "I have insider knowledge" feeling        | F7                            |
| **Emotion**      | Smile, cry, jaw-drop                      | F6                            |
| **Mastery**      | Watching skill executed cleanly           | F3, F5, F7                    |

A score of 3+ triggers → viral candidate. 4+ triggers → likely auto-approve.

---

## 3. The first 1.5 seconds — the only thing that matters at scale

Everything in this factory is over-engineered around the first 1.5 s.

### What MUST be there

1. **Visual chaos** (frame 1 must show the problem at maximum intensity)
2. **On-screen text hook** (one of `docs/06-hooks.md` templates)
3. **Sound that signals the niche** (chainsaw rev, mower hum, water sloshing)
4. **No logo, no intro card, no "Hey guys"**

### What's banned in 0.0–1.5s

- Talking-head intros ("Today we're going to...")
- Branding bumpers (kills retention 20–40 %)
- Slow fade-ins
- Empty sky / pavement (low-info frames)

### Pattern interrupts at 0.0 s

The hook is allowed to be **deliberately confusing for 0.4 s** to weaponize
the curiosity reflex:

> "Why is this pool BLACK?"
> "We weren't supposed to find THIS."
> "They told us it was a yard."

These pattern interrupts work best for F2 and F6.

---

## 4. Retention mechanics (the 0–10 s, 10–25 s, 25 s+ phases)

### Phase 1 — 0–1.5 s: HOOK
*Job: stop the scroll.*

- Burned-in text hook
- Maximum-contrast frame
- Diegetic sound, no music intro

### Phase 2 — 1.5–4 s: PAYOFF PROMISE
*Job: convince the viewer there's a reward coming.*

- Show a glimpse of the after (0.3 s flash) for F1/F2/F4
- Or accelerate the ASMR for F3
- Caption changes (cut + animate)

### Phase 3 — 4–10 s: TENSION BUILD
*Job: deepen investment.*

- The work happening — machinery, water, dust
- 1 micro-cut every 0.8–1.2 s to avoid pacing flatlines
- Subtle music ramp (if music used)

### Phase 4 — 10–25 s: RESOLUTION
*Job: deliver the payoff.*

- The reveal
- Same camera angle as the hook (the brain compares frames)
- Music drops or audio releases

### Phase 5 — 25–35 s: LOOP TRAP
*Job: trick the algorithm into a replay.*

- End on a slow zoom out
- The very last 0.5 s **visually matches the very first 0.5 s** —
  this creates a seamless loop where viewers re-watch unintentionally.
- No "subscribe!" outro. The CTA is in the caption, not the video.

---

## 5. The local-trust layer

Viral views without local trust = no leads.

Embed these signals in EVERY video without making them obvious:

- **Truck / equipment in frame** with your logo (small, top-corner sticker
  on the equipment, not a graphic overlay)
- **Local landmark in 1 frame** (a recognizable street sign, regional tree,
  local architecture)
- **Operator's hand visible** at least once — a hand looks human; a
  faceless drone shot does not
- **Local accent in captions** if you use language tokens ("in Krasnodar")
- **A real address in the pinned comment** ("Cleaned this in Lenina 47,
  May 17") — Telegram bot picks these up to publish a "we worked here
  this week" digest

Each of these adds ~3 % to lead-conversion on viral views.

---

## 6. Replay & comment-bait triggers

To push retention > 100 % (replay rate), do at least one of these per video:

| Trigger                            | How                                                |
| ---------------------------------- | -------------------------------------------------- |
| Hidden detail                      | Tiny object in corner: "did you see the snake?"    |
| Loop trap                          | End-frame == open-frame                            |
| Numbers debate-bait                | "We charged $200 for this" → comment wars          |
| Tool curiosity                     | Show unusual tool briefly                          |
| "Wrong way" tease                  | Use uncommon technique → "experts" will comment    |
| Mystery off-camera sound           | Strange sound never explained                      |
| Imperfect after-shot               | One weed left → comments find it                   |

Pick **one** per video. Stacking these dilutes the effect.

---

## 7. Avoiding the "corporate" smell

The algorithm and viewers both punish anything that smells brand-y.

| Do                                       | Don't                                  |
| ---------------------------------------- | -------------------------------------- |
| Phone-shot wide angle, slight wobble     | Polished gimbal sweeps                 |
| Diegetic equipment audio                 | Stock corporate background music       |
| One imperfect cut per video              | Frame-perfect cinematic edit           |
| First-person language in captions        | Third-person "Our company..."          |
| Show mistakes (machine struggle, sweat)  | Hide all friction                      |
| Casual local language                    | Marketing slogans                      |
| Real customer audio                      | Voiceover narration in 60 % of videos  |

---

## 8. Volume & longevity

The factory aims for **30 unique videos / week**, not 90. Quality of
candidates and editing is held above raw volume.

| Phase     | Unique videos / week | Variants / unique | Total posts / week |
| --------- | -------------------: | ----------------: | -----------------: |
| Month 1   |                   10 |                 2 |             20–40  |
| Month 2-3 |                   20 |                 3 |            60–120  |
| Month 4+  |                   30 |                 4 |            ~480    |

A "variant" is the same idea, recut differently (template, hook, pacing).
Always cross-platform: the same variant is **never** posted on two
platforms within 36 hours.

---

## 9. Anti-fatigue rules (so the format doesn't die)

- No same template more than 3 days in a row on the same platform.
- No same hook within 30 days per platform.
- No same opening visual within 14 days per platform.
- Audio: rotate trending sounds weekly (TikTok / Reels) — use a manual
  trending-sound table refreshed every Monday.

These rules are enforced inside workflow 03 by a deterministic check
before render. Failing the check selects the next-highest-scoring variant.

---

## 10. The summary heuristic

> If a viewer can summarize your video in one sentence after watching it,
> and that sentence makes them want to tell a friend — it will travel.

Every video gets a one-line "would-they-say" check:

> *"This guy turned a literal swamp into a swimming pool in 4 hours."*
> *"He found a sofa buried under 6 feet of grass."*
> *"Watch this thing eat a 100-year-old stump."*

If the LLM can't produce a strong one-liner from the candidate, the score
gets penalized by -10.
