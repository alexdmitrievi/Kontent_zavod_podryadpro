# 09 — Multi-Platform Strategy

The factory publishes to four platforms. They look the same — they aren't.
This document is the **per-platform spec sheet** the workflow uses to bake
different variants of the same content.

---

## 1. Platform comparison at a glance

|                          | TikTok                  | Instagram Reels         | YouTube Shorts          | Facebook Reels          |
| ------------------------ | ----------------------- | ----------------------- | ----------------------- | ----------------------- |
| Algorithm weight: 3 s ret| **Critical**            | High                    | Medium                  | High                    |
| Algorithm weight: complete rate | High             | High                    | **Critical**            | High                    |
| Algorithm weight: shares | High                    | High                    | Medium                  | **Critical**            |
| Algorithm weight: saves  | Medium                  | **Critical**            | Medium                  | Low                     |
| Algorithm weight: comments | High                  | Medium                  | Medium                  | High                    |
| Caption character limit  | 2 200 (only 70 shown)   | 2 200 (truncates ~125)  | 100 in title + 5 000 desc | 2 200 (truncates ~125)|
| Hashtag tolerance        | 3–5 ideal               | 3–5 ideal               | 2–3 in title            | 3–5 ideal               |
| Native music boost       | **Yes (strong)**        | Yes                     | No                      | Yes                     |
| Ideal duration           | 15–34 s                 | 15–30 s                 | 30–60 s                 | 15–34 s                 |
| Posting frequency cap    | 3–5/day                 | 2–3/day                 | 1–2/day                 | 2–3/day                 |
| Reposting risk           | Watermark = bad         | Repost OK if no logo    | Strict, original only   | OK                      |
| Best CTA channel         | Bio link + comment      | Bio link                | Pinned comment + desc   | Bio + comment           |
| 24h scoring window       | Days 0–3 decide it      | Days 0–7 decide it      | Days 0–14 decide it     | Days 0–3 decide it      |

---

## 2. TikTok — the volume engine

### Algorithm priorities

3-second retention > completion rate > share rate > comment rate.

### Hook timing

- 0.0–0.4 s: visual chaos peak
- 0.4–1.2 s: hook text legible
- 1.2–1.5 s: first cut
- **Never** brand intro

### Captions

- Keep ≤ 100 chars to be fully visible above the play bar.
- 1 emoji max in the first line.
- Hashtags: 3 niche + 1 local + 1 trend.
  - Niche: `#cleantok #satisfying #lawncare #poolclean #treework`
  - Local: `#{CityName} #{Region}`
  - Trend: pull from the weekly `trending_hashtags` table

### Music

- 30 % of videos: use a TikTok native trending sound (algorithm boost).
- 70 % of videos: original sound (we own and can repurpose).

### Reposting

- **Never** repost a video with a watermark from another platform.
- Re-render from the source for TikTok-specific specs.
- Wait minimum 14 days before re-publishing the same idea.

### Shadowban prevention

- No links in caption (TikTok deboosts these).
- Don't tag a competitor's username.
- Vary CRF and metadata between posts.
- Don't post 4+ videos within 3 hours.

### Posting times (default)

18:00 + 21:00 local. Best second slot: 12:00 lunch break.

---

## 3. Instagram Reels — the saves engine

### Algorithm priorities

Saves > completion rate > shares > 3 s retention > comments.

> Saves matter most on Reels because IG uses them as a "this is worth
> returning to" signal. Make the content **save-worthy**: visible numbers,
> useful info, before-after pairs that people screenshot.

### Hook timing

Same as TikTok but a tiny bit more polish acceptable.

### Captions

- First 125 chars visible — front-load the hook.
- 3–5 hashtags placed at the end on a separate line.
- One CTA: **save** is a high-value signal here.

### Music

- IG Music library is huge but copyright-tight for business accounts.
- Use original audio + a tiny licensed bed (Epidemic Sound).
- For business accounts in some regions, IG silently mutes copyrighted
  trending tracks — fall back to originals.

### Reposting

- Reposting TikTok content is **OK** if no TikTok watermark.
- Reels has different aspect ratio cropping on profile grid (1:1 crop) —
  ensure the hook is centered, not at the edges.

### Posting times

12:00 lunch + 19:00 evening. IG is calmer in the morning.

---

## 4. YouTube Shorts — the long-tail engine

### Algorithm priorities

Completion rate > avg view duration > swipe-away rate > likes > comments.

> Shorts has a 14-day discovery window — content that flops in 24 h can
> still hit 30 days later. Patience.

### Hook timing

You can be slightly slower (1.8–2.0 s) and still convert — YouTube viewers
are warmer to "wait for it" framing.

### Title

- ≤ 100 chars. This is the *primary* CTR lever (Shorts shows the title).
- Include the niche keyword: "lawn cleanup", "pool restoration",
  "stump grinding".
- 1–2 hashtags inside the title (counts towards SEO).

### Description (5 000 chars available)

- 200 chars of SEO-rich description.
- 5–8 keyword-targeted hashtags.
- **Link to Telegram channel** — Shorts allows this and rewards it less
  harshly than TikTok.

### Music

- Audio Library or YouTube's licensed tracks.
- Don't use copyright music — instant strike risk.

### Reposting

- YT is **strict** on duplicate content. If you re-render, change at least
  20 % of pixels and use a different audio bed.

### Posting times

17:00 local. Avoid mornings.

### A weird thing about Shorts

YouTube's algorithm cares about the **first 5 seconds**, not the first 3.
Tune the hook for 5-s retention specifically here, not 3.

---

## 5. Facebook Reels — the share engine

### Algorithm priorities

Shares > comments > completion rate > 3 s retention.

> FB Reels lives on a much older audience that **shares to messenger /
> family groups**. Content that resonates with parents and homeowners ages
> 35–65 over-performs. Lean into "look at this" wonder, not "trending sound".

### Captions

- Conversational, slightly longer than IG.
- Include question prompts: "Have you seen one this bad? Tag a neighbor."
- Hashtags less important here — comments and shares matter more.

### Music

- FB has a usable music library.
- Original audio works fine — FB doesn't penalize quiet videos.

### Posting times

20:00 local. The peak. FB Reels gets less weekend lift than TikTok.

### Reposting

- OK to repost from IG (same parent company).
- Strip the IG logo if any.

---

## 6. Caption rotation policy

The factory NEVER posts the same caption across two platforms. The LLM
produces a **per-platform pack** at workflow 02 (see `prompts/caption-generator.md`).

Example pack from a single OVR transformation:

| Platform | Caption                                                                                                              |
| -------- | -------------------------------------------------------------------------------------------------------------------- |
| TikTok   | Nobody had touched this in 4 years. 3 hours later. 🤯 #cleantok #yardwork #satisfying #KrasnodarLawn                    |
| Reels    | This used to be a yard. The save button is for transformations like this. 👇 ▪️ #lawncare #yardgoals #beforeandafter   |
| Shorts   | We Cleared 1200m² Of 4-Year Overgrowth In One Day (full job)  #lawncare #cleanup                                       |
| FB Reels | We pulled up to this yesterday and almost turned around. Three hours later — full reveal. Have you seen one this bad? |

---

## 7. Shadowban / deboost prevention (cross-platform)

Same content has different fingerprints — different bytes — for each platform:

- Re-encode at platform-specific CRF (19/20/21).
- Strip metadata.
- Slightly trim intro (first 80 ms vary) and outro tail.
- Different cover frame.
- Different caption + hashtag set.

Behavioral rules:

- Don't post the same idea on all 4 platforms within 6 hours.
- Stagger by 1–4 hours.
- Never link to Telegram from TikTok captions (use bio).
- Never tag competitors.
- Don't run "follow trains" or engagement pods.
- Reply to comments within 24 h on every platform — signals active account.

---

## 8. Repost strategy (the second-life loop)

Every video gets a second life after **30 days**:

- If the first run was a **hit/viral/mega**: re-render with a new hook +
  new music → republish on the same platform that performed best.
- If the first run was a **dud**: re-render with a different template
  (e.g. T02 → T06) and a different hook → try on a different platform.

The Winners workflow (W06) handles the first case automatically. The
"dud rescue" is opt-in — operator taps "rescue" in Airtable.

---

## 9. Cross-platform calendar

The publishing scheduler builds a per-day calendar that respects:

- Per-platform daily caps (TT 3, IG 2, YT 1, FB 2 by default).
- Service rotation: never two same-service posts back-to-back per platform.
- Time-of-day windows (see workflow 04 table).
- Minimum 90 min spacing per platform.

A typical day:

```
12:00  IG Reels   MOW    T01    H011
17:00  YT Shorts  OVR    T02    H007
18:00  TikTok     STM    T05    H058
19:00  IG Reels   POO    T06    H062
20:00  FB Reels   CLR    T04    H082
21:00  TikTok     OVR    T01    H001
21:30  TikTok     POO    T07    H067
```

8 posts/day across 4 platforms = ~3 unique videos × 2–3 variants each.

---

## 10. Platform-specific KPIs

| KPI                        | TT goal | IG goal | YT goal | FB goal |
| -------------------------- | ------: | ------: | ------: | ------: |
| 3 s retention              |   80 %  |   75 %  |   65 %  |   75 %  |
| Avg watch time (% of len)  |   55 %  |   50 %  |   45 %  |   50 %  |
| Completion rate            |   25 %  |   25 %  |   35 %  |   25 %  |
| Like rate (likes / views)  |    5 %  |    4 %  |    3 %  |    4 %  |
| Share rate                 |   1.5 % |   1.0 % |   0.5 % |   2.0 % |
| Save rate (IG)             |    —    |   2.0 % |    —    |    —    |
| Comments per 1k views      |    8    |    5    |    4    |    7    |
| CTR to bio link            |   1 %   |   1 %   |   2 %   |   1 %   |
| Telegram joiner per 1k vws |  0.5    |  0.4    |  0.8    |  0.3    |

Any post hitting all 3 platform-critical KPIs is auto-tagged `winner` and
sent to the Winners workflow for cloning.
