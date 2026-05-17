# 10 — Telegram Funnel System

Viral reach is worthless without **conversion**. The Telegram funnel is the
factory's single conversion endpoint. It catches viewers who leave the four
platforms and turns them into a) channel followers, b) DM leads, c) booked
jobs.

```
[viewer on TT/IG/YT/FB]
          │ taps bio / pinned-comment link / DM
          ▼
[Telegram bot @KontentZavodBot]
          │ welcome, auto-qualifier
          ▼
[Telegram channel: @kontent_zavod]   ←── pushed every viral
          │
          ▼
[Operator DM inbox]   ←── leads with intent
          │
          ▼
[Booked job + filmed]   ←── feeds back into the factory
```

---

## 1. The funnel in stages

| Stage | Name                | Conversion benchmark                | Mechanism                                |
| ----- | ------------------- | ----------------------------------- | ---------------------------------------- |
| 1     | View                | 100 %                               | TT/IG/YT/FB                              |
| 2     | Profile/bio tap     | 0.5–2 %                             | Profile CTA, "link in bio"               |
| 3     | Bot /start          | 30–50 % of stage 2                  | Bot welcome flow                         |
| 4     | Channel subscribe   | 50–70 % of stage 3                  | Bot prompts subscribe                    |
| 5     | DM intent           | 5–15 % of stage 4                   | "/quote" button                          |
| 6     | Lead (address+date) | 60 % of stage 5                     | 3-step qualifier                         |
| 7     | Booked              | 30–50 % of stage 6                  | Operator manual handoff                  |

Realistic month-3 numbers:

> 600 000 views → 6 000 bio taps → 2 400 /start → 1 700 channel subs →
> 250 DM intents → 150 leads → 60 booked jobs.

---

## 2. Bio / pinned-comment CTAs

Each platform funnels differently — adjust language per platform.

| Platform | Channel link goes where      | CTA line                                  |
| -------- | ----------------------------- | ----------------------------------------- |
| TikTok   | Bio link (Linkpop / Beacons)  | "Free quote in 2 min → DM in bio"         |
| IG       | Bio link tree                 | "Daily transformations → tap link"         |
| YT       | Description + pinned comment  | "Telegram bot in description"             |
| FB       | Bio + pinned comment          | "Tap to message us → Telegram"            |

The bio destination is a tiny page (e.g. on **Linkpop**, free) with two
buttons:

1. **Telegram channel** (passive content viewer)
2. **Telegram bot — Get a quote in 2 min** (active lead)

Both URLs encode UTM tags so analytics knows which platform converted.

---

## 3. The bot — `@KontentZavodBot`

A small bot (Node.js or Python, hosted on the same render VPS, or as an
n8n webhook flow). Architecture:

```
/start  → welcome → ask language → 2-button menu
                                      │
                ┌─────────────────────┴─────────────────────┐
                ▼                                           ▼
        "🎬 Daily videos"                       "📞 Get a free quote"
        subscribe to channel                      3-step qualifier
                │                                           │
                ▼                                           ▼
        Confirm subscribe                          {service, address, date}
                │                                           │
                └──────────────────►  Send to operator DM with deep-link
```

### Welcome message

```
Hi! 👋 You found us through {platform}.

We do mowing, overgrowth cleanup, pool & pond restoration, tree
work, stump grinding, and full property cleanup — in {CITY} and
{NEIGHBORING_REGIONS}.

Pick one:

🎬  Daily transformation videos
📞  Get a free 2-minute quote
```

The `{platform}` is set by a UTM-tagged deep-link
(`https://t.me/KontentZavodBot?start=tt_v12345`) — we know which video
brought them.

### Qualifier flow (3 steps)

```
Step 1: "What's the job?"
        [Mowing] [Overgrown cleanup] [Pool] [Trees] [Stump]
        [Land clearing] [Other → free text]

Step 2: "Where? (street + city is enough)"
        free text

Step 3: "When do you need it done?"
        [This week] [Next 2 weeks] [This month] [Just exploring]

Confirm: "Got it. We'll reply within 1 business hour."
```

The operator receives a Telegram message:

```
🟢 NEW LEAD
Service: OVR (overgrown cleanup)
Where: ул. Ленина 47, Краснодар
When: This week
Source: TikTok / video 20260517-OVR-02-A-001-TT-v2
First seen: 18:14
Reply: 🔗 https://t.me/c/{user_id}
```

Tap the link → directly into the user's DM. The hard part is now over.

---

## 4. Channel content strategy — `@kontent_zavod`

This is the **soft funnel** for viewers who aren't ready to message.

### Content cadence

| Day        | Post type                                                |
| ---------- | -------------------------------------------------------- |
| Mon        | Compilation of the week's best 4 shorts                  |
| Tue        | Behind-the-scenes: a mistake / tool we use               |
| Wed        | Customer reaction (with consent)                         |
| Thu        | Drone before/after as a Telegram round-video             |
| Fri        | "Job of the week" with address, hours, equipment         |
| Sat        | A quick educational tip relevant to the season           |
| Sun        | Operator's "look at this beauty" personal note + photo   |

7 posts/week, designed to look like a friendly local channel, not a brand.

### Format mix

- 60 % short videos (re-uploaded directly, no platform watermark)
- 20 % photo carousels (before / after)
- 10 % text-only ("Heads up: storm next week → call early")
- 10 % polls ("Most satisfying — Mowing or Pool?")

### Pinned message — always-on

```
👋 Hi! We're Kontent Zavod.
We do {service list} in {CITY}.

🎯 To get a free quote in 2 minutes:
👉 @KontentZavodBot

⏱ Reply window: ~1 hour (Mon-Sat).
📍 Service area: {CITY} + {30 km}
```

### Trust signals embedded in channel content

- Real photos of crew + equipment (faces blurred if required)
- Job addresses (with owner consent)
- Operator's name + voice
- Before-and-after grids
- Customer reaction videos with name + neighborhood

---

## 5. Soft conversion principles

Most viewers aren't buying today. The channel is a 30–90 day relationship.

- **Never sell from the first message.** The 3-step qualifier is the
  earliest you ever ask for an address.
- **Be useful before you sell.** Seasonal tips, "how to spot dying tree
  roots", "is your pool too far gone?" — these build trust.
- **Show the real human.** Operator's name in pinned. Operator's voice
  in DM. No "Hello, I am the Kontent Zavod team".
- **Reply fast.** Set a 1-business-hour SLA; the bot warns the operator
  if a DM has been idle > 30 min.

---

## 6. Lead-capture flow inside the bot

After the 3-step qualifier, the bot inserts a row into `leads`:

```sql
INSERT INTO leads (
  user_id, username, source_platform, source_post_id,
  service, address, timeframe, created_at, status
) VALUES (...);
```

`status` lifecycle:

```
new → contacted → quoted → booked → completed → reviewed
                                  ↘ no_show / cancelled
```

When `status=booked`, the bot **automatically opens a `jobs` row** with the
service code, prefilling the shoot list for the field operator.

When `status=completed`, the bot DMs the customer 24 h later:

> "Thanks! If you have 30 seconds: would you mind sending us a quick
> reaction video on what you think of the result? We use it on our
> channel (and we'll send you a small thank-you)."

This closes the loop: each completed job feeds back into F6 reaction
content for the factory.

---

## 7. Owner inbox (operator's side)

The operator works one Telegram chat — a private bot called
`@KontentZavodOps` — that aggregates:

- New leads (real-time)
- New approval queue items (every 30 min digest)
- Render failures
- Viral fire alerts ("🔥 TT post +200k in 4 h")
- Daily 21:00 summary

Inline buttons let the operator:

- ✅ Approve / ❌ Reject a queue item
- 📲 Open a lead DM
- 🔁 Recycle a winning post
- ⏸ Pause publishing

---

## 8. Trust scaffolding (the slow build)

Until you have ~50 reviews + 2 000 channel subs, viral reach won't convert
optimally. Use these to fast-track local trust:

- **Map pin**: a single-page Notion site with a Google Map of every job
  done, addresses approximated to neighborhood.
- **"Caught on camera"**: occasionally show the channel members
  themselves recognized in the videos ("you've seen us on Tverskaya").
- **Channel exclusives**: a 30-s clip per week that does NOT go to
  TT/IG/YT/FB. Followers feel they have inside access.
- **Off-camera operator content**: weekly photo + 2-line note from the
  operator. "Today was rough. 5 jobs. Slept in the truck for 20 min.
  Saw a fox. Here's a sunset."

---

## 9. Metrics — funnel observability

| Metric                            | Source             | Cadence  |
| --------------------------------- | ------------------ | -------- |
| Bio link clicks per platform      | Linkpop / Beacons  | daily    |
| /start events by UTM source       | Bot logs           | real-time|
| Channel subscribers (per day)     | Telegram API       | daily    |
| /quote starts vs completed        | Bot logs           | daily    |
| DM response time (median)         | Bot logs           | weekly   |
| Lead → booked conversion %        | Supabase           | weekly   |
| Booked → revenue (manual entry)   | Airtable           | weekly   |

These feed the daily Telegram digest in workflow 05 — so the operator can
see "did 3 viral videos actually bring DMs this week?"

---

## 10. CTA strategy — soft / soft / hard rotation

The same hard CTA every video burns out fast. The factory rotates:

| Day type   | CTA emphasis                                            |
| ---------- | ------------------------------------------------------- |
| Default    | **Soft**: "We post these every day → bio"              |
| Every 4th  | **Soft**: "Telegram channel in bio, no sales pitch"    |
| Every 7th  | **Hard**: "Free quote in 2 min — bio link"             |
| Saturday   | **Soft**: "Send this to a friend with a swampy pool"   |
| Sunday     | **Hard**: "Booking next week. DM us before slots fill" |

The LLM in `prompts/caption-generator.md` enforces this rotation by
reading the post's `cta_strategy` flag set by workflow 03.
