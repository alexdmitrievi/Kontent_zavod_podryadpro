# Prompt — Transcription Cleanup & Emphasis Tagging

**Model:** Claude Sonnet 4.6 (or Gemini 1.5 Flash for cost saving)
**Output:** JSON
**Temperature:** 0.2
**Max tokens:** 2000

Cleans Whisper output for **on-screen subtitle generation**. Whisper is
accurate at words but its punctuation/casing and segmentation can hurt
the burned-in subtitle look. This pass:

1. Re-segments into 2–4-word "captions chunks" with start/end times.
2. Capitalizes for impact (numbers, hooks).
3. Marks emphasis words (`*WORD*`) that the renderer will pop-up.
4. Strips filler ("um", "uh", false starts).

---

## System

```
You convert raw Whisper transcripts into short-form social caption chunks.

The output is consumed by an ASS subtitle generator: each chunk becomes
one on-screen caption that pops in for 0.8–1.6 seconds.

RULES
1. Each chunk is 2–4 words. Never more than 4 words per chunk.
2. Chunk timing must come directly from the Whisper word-level timestamps.
   If word-level timestamps are missing, distribute proportionally inside
   the segment.
3. Remove filler: "um", "uh", "так", "ну", "э-э", false starts.
4. Numbers stay as DIGITS, not words ("3 hours", not "three hours").
5. Mark ONE emphasis word per chunk by wrapping with asterisks: *WORD*.
   Pick the word with the highest information density. NEVER emphasize
   articles / particles.
6. NEVER add words that weren't said.
7. Preserve language of the original (RU → RU caption, EN → EN caption).
8. ALL_CAPS only on hook lines (we pass a `hook_line_window_s` to mark).
9. Strict JSON only.
```

## User

```
WHISPER OUTPUT (word-level if available, else segment-level)
{
  "language": "ru" | "en",
  "segments": [
    { "start": 0.12, "end": 4.85, "text": "...",
      "words": [{"word":"...","start":0.12,"end":0.35}, ...] },
    ...
  ]
}

HOOK_LINE_WINDOW_S (start, end) — first 1.5 s is the hook overlay.
{hook_window}                   ← e.g. [0.0, 1.5]

OUTPUT
{
  "chunks": [
    { "start": 0.12, "end": 0.65, "text": "Look at *THIS*", "all_caps": true, "is_hook": true },
    { "start": 0.66, "end": 1.40, "text": "front *YARD*",   "all_caps": true, "is_hook": true },
    { "start": 1.50, "end": 2.10, "text": "4 *YEARS*",       "all_caps": false,"is_hook": false },
    ...
  ]
}
```

## Example (RU)

Input segment:
> "Ну вот эта трава, она тут уже года четыре стояла."
> (timing 0.0–4.6 s)

Output:

```json
{
  "chunks": [
    { "start": 0.20, "end": 0.85, "text": "Эта *ТРАВА*",       "all_caps": true,  "is_hook": true },
    { "start": 0.95, "end": 1.50, "text": "стояла *ТУТ*",      "all_caps": true,  "is_hook": true },
    { "start": 1.60, "end": 2.40, "text": "4 *года*",           "all_caps": false, "is_hook": false },
    { "start": 2.50, "end": 3.40, "text": "без *ухода*",        "all_caps": false, "is_hook": false }
  ]
}
```

The filler "Ну вот" is removed. The numeral "4" stays as a digit.
"ТРАВА" is emphasized (information-dense). The hook window is 0–1.5 s,
so the first two chunks are flagged `is_hook=true` and rendered in the
large hook style.

## Workflow side

After the LLM returns:

1. Sanity-check chunks: end_s > start_s, total duration ≤ source duration.
2. Render `.ass` (one Dialogue line per chunk).
3. Embed the resulting `.ass` into the video via FFmpeg `subtitles=` filter.

## Latency / cost

For a 30-second clip with ~12 chunks: ~$0.002 (Gemini Flash) or
~$0.006 (Claude Sonnet), both < 2 s wall-clock.

We default to **Gemini Flash here** because the task is mechanical, not
judgment-heavy.

## Fallback path

If LLM fails twice, fall back to a deterministic Python implementation:

```python
def naive_chunks(segments, hook_window):
    chunks = []
    for seg in segments:
        words = seg.get('words') or distribute_words(seg)
        for i in range(0, len(words), 3):           # 3 words per chunk
            group = words[i:i+3]
            text = ' '.join(w['word'] for w in group)
            chunks.append({
                'start': group[0]['start'],
                'end':   group[-1]['end'],
                'text':  text.upper() if group[0]['start'] < hook_window[1] else text,
                'all_caps': group[0]['start'] < hook_window[1],
                'is_hook': group[0]['start'] < hook_window[1],
            })
    return chunks
```

The deterministic path loses emphasis tagging but is bulletproof.
