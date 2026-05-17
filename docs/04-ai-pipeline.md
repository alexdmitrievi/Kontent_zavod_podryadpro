# 04 — AI Video Processing Pipeline

This is the brain of the factory. The pipeline turns a 90-second raw clip
into 2–3 viral-ready short candidates with hooks, captions, scores, and a
chosen render template — all under $0.05 / clip and ~90 s of wall time.

```
RAW CLIP
   │
   ├─▶ A. Frame sampler ─────────▶ Gemini Vision  ▶ tags
   │
   ├─▶ B. ASR (Whisper)  ────────▶ SRT + slate parse
   │
   ├─▶ C. Scene detector (ffmpeg) ▶ cut-point list
   │
   ├─▶ D. Moment selector (GPT-4o) ▶ 3–8 candidates with reasons
   │                       ▲
   │                       │ (sees: tags + transcript + scene cuts)
   │
   ├─▶ E. Viral scorer (Claude) ▶ score 0..100 per candidate
   │
   ├─▶ F. Hook generator (Claude) ▶ 5 hooks / candidate
   │
   ├─▶ G. Caption + hashtags + CTA (Claude) ▶ per platform
   │
   └─▶ H. Template selector (rules) ▶ T01..T08
```

---

## A. Frame sampler

Five frames evenly spaced across the clip. For clips > 60 s, sample 8.

```bash
ffmpeg -i in.mp4 \
  -vf "fps=1/$(echo "$DURATION/5" | bc -l),scale=720:-2" \
  -frames:v 5 \
  frame_%02d.jpg
```

Encode to base64 and send to Gemini in a single multimodal request.

**Why Gemini Flash for vision and not GPT-4o vision here?**

| Tool          | Cost / 5 frames | Latency | Notes                          |
| ------------- | --------------: | ------: | ------------------------------ |
| Gemini Flash  |        ~$0.002  |   2–3 s | Best $/image, JSON mode great  |
| GPT-4o        |         ~$0.02  |   3–5 s | Better at reasoning, overkill  |
| Claude Sonnet |        ~$0.015  |   3–4 s | Best for text reasoning, save  |

We use Gemini for **perception** and Claude for **judgment**. Cheapest split.

---

## B. ASR — Whisper local

Self-hosted `faster-whisper` on the render VPS:

```bash
whisper-ctranslate2 \
  --model large-v3 \
  --language auto \
  --output_format srt \
  --vad_filter True \
  --beam_size 1 \
  --temperature 0 \
  --max_chars_per_line 22 \
  in.mp4
```

Result feeds three downstream consumers:

1. Slate parser (workflow 01) — first 8 s only.
2. Moment selector (D) — uses full transcript as semantic context.
3. Subtitle generator — exact timestamps for `.ass` burn-in.

Why local Whisper? **Free**, runs on 4-core CPU at 1.2× real-time, supports
Russian and English perfectly.

---

## C. Scene detector

Plain ffmpeg with the `scene` filter:

```bash
ffmpeg -i in.mp4 \
  -filter:v "select='gt(scene,0.4)',showinfo" \
  -f null - 2>&1 | grep showinfo | awk -F 'pts_time:' '{print $2}' \
  | awk '{print $1}'
```

Output: a list of timestamps where the scene meaningfully changes. We use
these as **candidate cut points** — the LLM is constrained to pick start/end
near a real scene boundary, which keeps cuts clean.

A pure-LLM moment selector without scene info tends to pick mid-pan moments
and the cuts look amateur. With scene info, cuts feel intentional.

---

## D. Moment selector (GPT-4o)

This is the most important LLM call in the whole system. Prompt template:

```text
You are a viral short-form editor specialized in landscaping
transformations. Pick the BEST 3–8 candidate clips inside this source.

INPUT:
- duration: {duration}s
- service: {service} ({service_full_name})
- tags: {tags_json}
- scene_cut_timestamps: [{...}]
- transcript (with timestamps): {srt_text}

RULES:
- Each candidate must be between 6 s and 35 s long.
- Start and end MUST snap to one of the scene_cut_timestamps (±0.4 s ok).
- Prefer moments where movement, contrast, or sound peaks.
- Mark each with a "kind":
    transformation_reveal
    asmr_loop
    chaos_to_order_full
    drone_reveal
    machinery_close
    speed_ramp
    reaction_face
    fast_curiosity
- Give a "reason" ≤ 18 words explaining the dopamine trigger.
- Return strictly JSON array, no prose.

OUTPUT:
[{ "start": 12.4, "end": 27.8, "kind": "...", "reason": "..." }, ...]
```

The LLM returns its candidates; we cap at 5 max to control cost downstream.

---

## E. Viral scorer (Claude Sonnet)

Each candidate is scored via the rubric in `prompts/viral-scoring.md`.
The rubric assigns 0–10 points across **10 axes**, summed for a 0–100 score:

1. Hook strength (would the first 1.5 s stop a scroll?)
2. Contrast magnitude (before vs after, ugly vs beautiful)
3. Curiosity gap (does it raise a question quickly?)
4. ASMR/sensory payoff
5. Pacing potential (will edit feel snappy?)
6. Replayability (will viewers loop?)
7. Comment-bait (will viewers tag a friend / argue / praise?)
8. Local trust signal (looks like a real local, not corporate)
9. Niche specificity (clearly OUR niche, not generic)
10. Risk (no faces/license plates/hazards on display)

Below 55 → discarded. 55–69 → goes to queue, requires human approval.
70–79 → queue, auto-approve after 4 h. 80+ → auto-approve immediately.

The rubric also returns a `weaknesses` array — these are passed to the hook
generator as "things the hook must compensate for".

---

## F. Hook generator (Claude Sonnet)

Per candidate, 5 hooks: **3 English + 2 Russian**, taken from the bank in
`docs/06-hooks.md`. Prompt instructs Claude to:

- choose hook templates whose triggers match the candidate's `kind`,
- vary emotional register: 1 shock, 1 curiosity, 1 satisfying-tease, 1 local,
  1 numbers-driven,
- never repeat a hook used in the last 30 days for that platform,
- output `{ hook_id, hook_text, predicted_retention_seconds }`.

The hook gets **burned into the first 1.5 s** of the video as on-screen text
AND is the first line of the platform caption.

---

## G. Caption + hashtags + CTA (Claude Sonnet)

Single call returns the full per-platform package:

```json
{
  "tiktok": {
    "caption": "...",
    "hashtags": ["#cleantok","#satisfying","#mowing","#YourCity"],
    "cta": "Save this if you'd hire us 👇 — Telegram in bio"
  },
  "instagram": { ... },
  "youtube": { ... },
  "facebook": { ... }
}
```

Caption rules:

- TikTok / Reels: ≤ 150 chars, emoji ok, 3–5 hashtags + 1 location hashtag.
- Shorts: ≤ 90 chars on first line (truncation), 2–3 hashtags inside title.
- FB Reels: ≤ 200 chars, more conversational.

CTA pattern: **soft → soft → hard** in rotation. Never the same hard CTA on
all four platforms on the same day.

---

## H. Template selector (rule-based)

A simple decision tree, no LLM, deterministic and explainable:

```
if candidate.kind == "transformation_reveal" and has_before_and_after:
    T01_before_after_split
elif candidate.kind == "chaos_to_order_full":
    T02_chaos_to_order
elif candidate.kind == "speed_ramp":
    T03_time_lapse
elif candidate.kind == "drone_reveal":
    T04_drone_reveal
elif candidate.kind == "machinery_close" and asmr_audio_quality_ok:
    T05_machinery_asmr
elif candidate.kind == "fast_curiosity":
    T06_curiosity_loop
elif candidate.kind == "reaction_face":
    T07_reaction_split
else:
    T08_generic_short
```

Templates are detailed in `docs/08-editing.md`.

---

## Putting it together — example trace

Input clip: `20260517-OVR-02-A-001.mp4`, 96 s, front yard, 2 m grass, brushcutter sound.

```
A. Gemini → {service:OVR, phase:before+during, mood:abandoned,
             overgrowth_level:9, machinery_visible:true,
             viral_kind:"transformation"}

B. Whisper → "Look at this. Hasn't been mowed in two years.
              Let's see what we can do..." (slate at 0–6s)
             ... full SRT ...

C. ffmpeg → cut points at [0.0, 5.8, 27.3, 41.0, 58.6, 72.4, 89.1, 96.0]

D. GPT-4o → 4 candidates:
   - 0.0..27.3   kind=transformation_reveal   reason="opens on chest-high grass"
   - 27.3..58.6  kind=machinery_close          reason="brushcutter ASMR + spray"
   - 58.6..89.1  kind=chaos_to_order_full      reason="reveals tidy lawn"
   - 0.0..89.1   kind=transformation_reveal   reason="full job, time-lapse-able"

E. Claude scores → 88, 71, 84, 79
   → 1 auto-approves, 2 wait 4h for approval, 1 enters queue with rejection
     risk flag.

F. Hooks generated for top 3 candidates (each gets 5).

G. Captions generated for top 3 × 4 platforms = 12 packages.

H. Templates → T01 split, T05 ASMR, T02 chaos-to-order.

Net: 3 candidates × 2 variants/platform × 4 platforms = up to 24 posts.
We cap at 8 posts/job/day by default to avoid platform spam.
```

Total LLM spend on this trace: **$0.046**.

---

## Cost & quality tradeoffs

If budget is tight you can flatten the stack:

| Mode      | What it cuts                                        | Monthly LLM cost |
| --------- | --------------------------------------------------- | ---------------: |
| Premium   | Everything above as-is                              |   $20–40         |
| Standard  | Skip Twelve Labs, use only ffmpeg scenes + GPT-4o   |   $10–20         |
| Minimal   | Gemini for both perception **and** moments + hooks  |    $3–8          |
| Survival  | One Gemini call returns tags + 1 candidate + 1 hook |    $1–2          |

Recommendation: start in **Standard**, switch to **Premium** once the first
viral video pays for 3 months of API spend.

---

## Tooling notes & alternatives

- **Twelve Labs** (`https://twelvelabs.io`) — purpose-built video LLM,
  excellent at "find me the most exciting 8-second moment". ~$0.05/min.
  Drop-in replacement for steps C+D when you outgrow ffmpeg+GPT-4o.
- **Pyannote / WhisperX** — for diarization if you ever shoot client
  testimonials. Out of scope for v1.
- **OpenCV / scenedetect** — local Python lib for scene detection if you
  want richer cut detection than the ffmpeg filter. Worth swapping in once
  you process > 50 clips/day.
- **CLIP embeddings** (open-source, free) — used for **dedup** on the
  candidate side: if two candidates from different jobs have cosine
  similarity > 0.92 → flag duplicate.

---

## Observability

Every LLM call writes to `llm_calls`:

```
(id, provider, model, prompt_tokens, completion_tokens,
 latency_ms, cost_usd, workflow, entity_id, ok, error_text)
```

The daily Telegram digest reports:

> 🤖 LLM today: 247 calls, $1.42, p95 latency 3.8 s, errors 2 (re-tried, ok).

If errors > 5 % over an hour, n8n sends a Telegram alert and pauses
classification.
