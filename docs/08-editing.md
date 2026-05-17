# 08 — Short-Form Editing System

The render layer is a small library of **deterministic FFmpeg templates**.
No NLE involvement in the auto path. Everything below is parameterized and
called by workflow 03.

The goal: optimize for **watch time, completion rate, and replayability** —
in that order.

---

## 1. Eight render templates

| Code | Name                    | Best for kinds                            | Duration | Music   |
| ---- | ----------------------- | ----------------------------------------- | -------- | ------- |
| T01  | Before-After Split      | transformation_reveal (have both shots)   | 10–20 s  | gentle  |
| T02  | Chaos → Order           | chaos_to_order_full                       | 15–30 s  | rising  |
| T03  | Time-Lapse              | speed_ramp                                | 10–15 s  | none/light |
| T04  | Drone Reveal            | drone_reveal                              | 8–14 s   | swell   |
| T05  | Machinery ASMR          | machinery_close, asmr_loop                | 10–20 s  | **none** |
| T06  | Curiosity Loop          | fast_curiosity                            | 7–15 s   | tension |
| T07  | Reaction Split          | reaction_face                             | 10–18 s  | gentle  |
| T08  | Generic Short           | fallback / educational                    | 15–35 s  | varied  |

Each template lives in `workflows/templates/{T0X}.json` as a parameterized
spec. The FFmpeg command is built on the render VPS at runtime.

---

## 2. The hard specs (every template obeys these)

| Spec                        | Value                                |
| --------------------------- | ------------------------------------ |
| Resolution                  | 1080 × 1920 (9:16)                   |
| Frame rate                  | 30 fps                               |
| Container                   | MP4                                  |
| Video codec                 | H.264 (libx264), `+faststart`        |
| CRF                         | 19 (TT), 20 (IG/FB), 21 (YT)         |
| Profile / pix_fmt           | high / yuv420p                       |
| Audio codec                 | AAC, 192 kbps, 48 kHz, stereo        |
| Loudness                    | EBU R128 to **−14 LUFS** (TT/IG/FB), **−16 LUFS** (YT) |
| Color                       | rec709, no HDR                       |
| Metadata                    | stripped (`-map_metadata -1`)        |
| File size                   | ≤ 35 MB (TT and Reels prefer it)     |

A normalization pre-pass runs on every render:

```bash
ffmpeg -i input.mp4 \
  -af "loudnorm=I=-14:TP=-1.5:LRA=11:print_format=json" \
  -f null - 2>loud.json
# Then read measured values and apply a second pass
```

---

## 3. Pacing system

The factory uses a fixed pacing grid per template — the LLM does not control
pacing; it only proposes a `kind` which selects a template.

| Phase         | T02 example pacing (chaos → order)              |
| ------------- | ----------------------------------------------- |
| 0.0–1.5 s     | HOOK: one held shot of the chaos + on-screen text |
| 1.5–4.0 s     | Quick montage 3–4 shots, each ~0.7 s            |
| 4.0–10.0 s    | "Work" sequence — shots avg 1.0 s, ASMR audio   |
| 10.0–22.0 s   | Mid-block: 0.9 s shots, occasional 1.8 s hold   |
| 22.0–26.0 s   | Reveal: one held shot, music drops              |
| 26.0–28.0 s   | Loop trap: slow zoom matching frame 1           |

Constants:

- Average shot length: **0.9 s**
- No shot < 0.35 s (subliminal, hurts retention)
- No shot > 2.5 s except the final reveal
- 1 audio-only beat (no cut) every ~5 s to let the ear breathe

---

## 4. Subtitle / caption system

### Style — `subs.ass`

```
[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920

[V4+ Styles]
Format: Name,Fontname,Fontsize,PrimaryColour,OutlineColour,BackColour,
        Bold,Italic,BorderStyle,Outline,Shadow,Alignment,
        MarginL,MarginR,MarginV,Encoding
Style: Default,Inter,86,&H00FFFFFF,&H00000000,&H80000000,
       -1,0,1,5,0,2,80,80,420,1
Style: Hook,Inter,108,&H00FFFFFF,&H00000000,&H80000000,
       -1,0,1,7,0,5,80,80,860,1
```

Why these defaults:

- **Inter / Roboto Black / system bold** — neutral, reads on any background.
- **Size 86** body, **108** hook — hooks dominate.
- **Alignment 2** body (bottom-center), **5** hook (center).
- **MarginV 420** body — clears bottom UI on TikTok (caption row + buttons).
- **Stroke 5** outline + **shadow** — readable on any frame.
- **Per-word pop** for emphasis words — see ASS `\fad(80,80)` + `\fs+10`.

### Per-word pop builder (Python pseudo-code)

```python
def build_ass_from_whisper(segments):
    events = []
    for seg in segments:
        for w in seg.words:
            start = ms_to_assts(w.start)
            end   = ms_to_assts(w.end)
            text  = w.text.upper() if w.emphasis else w.text
            events.append(
              f"Dialogue: 0,{start},{end},Default,,0,0,0,,"
              f"{{\\fad(40,40)}}{text}"
            )
    return "\n".join(events)
```

Emphasis is set by an LLM pass over the transcript: superlatives, numbers,
and the hook payoff word get `emphasis=True`.

### Hook overlay

Drawn as a separate Hook event for 0.0–1.4 s of the clip. Always two lines
max. Always centered, vertical position at 45 % of screen height. Always
the **highest-contrast** color combo:

- White text + black outline + 35 % black shadow on bright footage
- Yellow text (#FFE45C) + black outline on muted footage
- Never gradient. Never script fonts.

### Captions: when to NOT show

- T05 ASMR: no captions at all (audio carries it) — only the hook for 0–1.4 s.
- T03 time-lapse: only the hook + a single payoff line at the end.

---

## 5. Music & sound design

### Music selection rules

```
template T01 → bed: "gentle_swell"   ducked -18dB under voice/ASMR
template T02 → bed: "rising_tension" rises with cuts, peaks at reveal
template T03 → bed: "minimal_pulse"  4-on-the-floor low BPM
template T04 → bed: "cinematic_swell"
template T05 → no bed  (diegetic only)
template T06 → bed: "anticipation"   short hits + breath drop
template T07 → bed: "soft_warm"      ducked further under speech
template T08 → bed: varied; LLM suggests from a 12-track library
```

**Native trending sounds (TikTok / Reels):** rotate weekly. Maintain a
`trending_sounds` table updated every Monday. When a video is being
published to TikTok or Reels, swap the music track for the platform's
native trending sound 30 % of the time — this is a meaningful retention lift.

### Audio bus

```
1) ASMR / diegetic  → highpass 80Hz, lowpass 14kHz, compress 3:1
2) Voice (slate)    → highpass 100Hz, de-ess at 6kHz
3) Music bed        → sidechain ducked -18 dB to (1)+(2)
4) Final bus        → loudnorm to -14 LUFS, TP -1.5, LRA 11
```

---

## 6. Zoom timing & attention resets

Even within a held shot, an attention reset every ~3 s prevents drop-off.

| Tool                                                          | Frequency  |
| ------------------------------------------------------------- | ---------- |
| Subtle 1.05× zoom in over 1 s                                 | every ~3 s |
| 1-frame flash white (`format=gray,negate`) at major pivots    | 1 per video|
| Center-cut crop on a held shot (1.2×)                         | once       |
| Slight tilt (rotate ±1.5°) at the reveal                      | once       |

These are encoded as parameters in each template's JSON, not hand-tuned.

---

## 7. Hook timing — the 1.5-second rule

The first 1.5 s must contain:

```
0.00 s  frame 1: maximum-contrast still of the problem
0.00 s  hook text fades in (40 ms)
0.30 s  micro-zoom 1.0× → 1.06× starts
1.40 s  hook text fades out (40 ms)
1.50 s  first cut to the work / reveal teaser
```

The hook line is generated by `prompts/hook-generator.md` and pulled from
the bank in `docs/06-hooks.md`. The text is **all caps** if ≤ 6 words,
**title case** otherwise.

---

## 8. Retention editing strategy

Three retention checkpoints exist for every platform:

| Platform | Checkpoint 1 | Checkpoint 2 | Checkpoint 3 |
| -------- | -----------: | -----------: | -----------: |
| TikTok   |       3 s    |       10 s   |       end    |
| Reels    |       3 s    |       8 s    |       end    |
| Shorts   |       5 s    |       15 s   |       end    |
| FB Reels |       3 s    |       10 s   |       end    |

Each template is tuned so that **a payoff lands ≤ 0.8 s before each
checkpoint** — that's how you nudge "saves" and re-watches.

The render plan logs the planned payoff timestamps; analytics later checks
whether retention actually peaks where we planned.

---

## 9. Cover frame strategy

Every post gets a cover image (R2 `thumbs/{post_id}.jpg`) used as:

- Shorts thumbnail (visible on YT search)
- Reel cover (appears in profile grid)
- Facebook Reels thumbnail
- TikTok cover (less visible but indexed for search)

Rules:

- Cover = the **frame at the moment of the after** (not before).
- The hook text is **NOT** burned into the cover (it kills the algorithm's
  CTR boost by signaling "ad").
- Add a tiny corner watermark (logo, 4 % screen height, 80 % opacity).

If footage cover quality is poor (motion blur, awkward face), Flux generates
a stylized cover from the description, cached in R2.

---

## 10. Quality assurance gate

Every render must pass automated checks before insert into `posts`:

```
✓ duration ∈ [7, 60] s
✓ fps ≥ 30 and ≤ 60
✓ audio not silent (RMS > -50 dB)
✓ no static frame > 2.5 s (except final hold)
✓ loudness within ±0.5 LUFS of target
✓ hook overlay present in first 1.6 s
✓ no caption overlap with bottom 380 px (platform UI zone)
```

If any check fails: re-render with a fallback template (T08 generic).

If T08 also fails: row marked `failed`, Telegram alert, operator reviews.

---

## 11. Replayability — the loop trap recipe

The factory's signature trick. Used on ~50 % of videos.

1. Save frame 1 (after hook overlay clears) as `frame_open.png`.
2. Save the last frame of the body as `frame_close.png`.
3. Render template ensures `frame_close ≈ frame_open` (same crop, similar
   composition).
4. On the last 0.3 s, crossfade `frame_close → frame_open`.
5. Net effect: when TikTok loops the video, the seam is invisible. Viewers
   watch 1.4–1.8 loops on average before realizing they've re-watched.

This single trick contributes ~+12 % avg watch time on T01, T02, T04.

---

## 12. Manual hero edits (the 1–2x/week exception)

Some footage deserves more love. Once or twice a week, send the best raw
clip to CapCut for a manual edit. Rules:

- 60–90 minutes max editing time.
- Must still obey the 1.5-second rule.
- Output is uploaded to R2 `manual/` and a `posts` row is created with
  `status=approved` and `manual=true`.
- Tag `hero=true` for analytics — these often become anchor content for
  the Telegram channel.
