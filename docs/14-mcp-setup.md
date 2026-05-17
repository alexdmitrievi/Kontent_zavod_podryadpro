# 14 — MCP Setup (Higgsfield + Publishers)

This document is the setup guide for the **Model Context Protocol** servers
the factory uses *interactively* with Claude — separate from the *automated*
n8n + HTTP API path that handles daily publishing.

## Two paths, not one

The factory has two parallel paths to the social platforms:

```
┌────────────────────────┐        ┌──────────────────────────┐
│  AUTOMATED (default)   │        │  INTERACTIVE (optional)  │
│  n8n + HTTP API        │        │  Claude + MCP            │
│                        │        │                          │
│  Workflows 01–06       │        │  MCPs in .mcp.json       │
│  → Ayrshare / Postiz   │        │  → Higgsfield (gen)      │
│  → TT / IG / YT / FB   │        │  → PostEverywhere / Postiz│
│                        │        │     (publishing)         │
└────────────────────────┘        └──────────────────────────┘
        ↑                                   ↑
   runs hands-off                  for ad-hoc creative tasks
   24/7, no Claude                 ("make me a hero clip and
                                    post it now")
```

Both paths are useful — they're not in competition:

- **n8n path** = factory operations. Daily volume, scheduled, deterministic.
  This is what runs the business.
- **MCP path** = creative cockpit. When you want Claude to brainstorm,
  generate a synthetic b-roll cutaway in Higgsfield, and one-off post it to
  TikTok without touching the queue.

This doc sets up the MCP path.

---

## What you'll connect

| MCP                    | Purpose                                              | Auth                | Cost                  |
| ---------------------- | ---------------------------------------------------- | ------------------- | --------------------- |
| **Higgsfield**         | Generate synthetic images + 5–15 s video b-roll      | OAuth (browser)     | 150 free credits/mo; paid after |
| **PostEverywhere**     | Publish / schedule to TT, IG, YT, FB + 4 others      | API key (env var)   | 7-day trial → from ~$15/mo |
| **Postiz** *(opt.)*    | Same as above, but self-hosted (free)                | API key (URL path)  | $0 + your VPS         |
| **Ayrshare docs** *(opt.)* | Lets Claude read Ayrshare API docs for n8n work  | none                | free                  |

You only need **Higgsfield + ONE publisher**. The blueprint defaults to
Postiz (self-host, free) — use PostEverywhere if you want managed.

---

## Important: where MCP config lives

MCPs are configured on the **client side** (your Claude Code / Claude
Desktop installation). Three valid locations, in priority order:

1. **Project-local** — `.mcp.json` at the repo root (this one is in the repo).
2. **User-global** — `~/.claude.json` `"mcpServers"` key, applies everywhere.
3. **Claude Code on the web** — Settings → Connectors (for hosted MCPs only).

> **A running session does NOT pick up new MCPs from edits to `.mcp.json`.**
> Claude must restart (`/exit` then re-open) for the new servers to appear.

In the cloud / web environment Claude is currently running in, this repo's
`.mcp.json` is loaded **when the next session starts** — not in this one.
If you want to use Higgsfield + a publisher *right now*, run Claude Code
locally with this repo open.

---

## Setup — recommended path (per-user, global)

Run these once on your machine. They write to `~/.claude.json` so the
servers are available in every project.

### 1) Higgsfield (image + video generation)

```bash
claude mcp add --transport http --scope user higgsfield \
  https://mcp.higgsfield.ai/mcp
```

First Higgsfield tool call → Claude Code pops a browser window for OAuth →
you sign in → done. No API key on disk.

**Models exposed**: Soul V2, Veo 3.1, Kling 3.0, Sora 2, Seedance 2.0,
WAN 2.6, Hailuo 02 (video) + GPT Image 2, Nano Banana Pro, Flux 2,
Seedream 5.0 Lite (image). All behind one tool surface.

**Use cases in this factory**:
- Synthetic b-roll cutaways (e.g. an aerial we forgot to shoot).
- Cinematic 5-second intro stings used in C8 "dramatic deep cleans".
- Cover frames when the candidate's actual frame is unflattering.
- "Soul" consistency-locked character of the operator for stylized cards.

> ⚠️ Out of scope for daily volume: Higgsfield is **opt-in per video**.
> The blueprint's viral DNA depends on **real** before/after footage. Use
> Higgsfield for accents, not for the main beat.

### 2) PostEverywhere (publisher, managed)

```bash
# Get an API key first: posteverywhere.ai → sign up → connect TT/IG/YT
# → Settings → Developers → create key (pe_live_...)

claude mcp add --scope user posteverywhere \
  -e POSTEVERYWHERE_API_KEY=pe_live_YOUR_KEY \
  -- npx -y @posteverywhere/mcp
```

**Platforms supported**: Instagram, TikTok, YouTube, Facebook, LinkedIn,
X, Threads, Pinterest.

**Use cases**:
- "Hey Claude, take post 20260517-OVR-02-A-001-TT-v2 from R2 and post it
  to TikTok and Reels right now with this caption."
- Replanning the day's schedule conversationally.
- Quick deletes / reposts from chat.

### 2 alternative) Postiz (publisher, self-hosted, free)

If you self-host Postiz (the blueprint's default), the MCP endpoint is
baked into your instance:

```bash
claude mcp add --transport http --scope user postiz \
  https://postiz.your-domain.tld/api/mcp/YOUR_POSTIZ_API_KEY
```

The API key goes **in the URL path** (Postiz design). Treat the URL as
secret; it's effectively a bearer token.

To enable writes (publish, not just read):
```bash
claude mcp add --transport http --scope user postiz \
  -e POSTIZ_ENABLE_WRITE=true \
  https://postiz.your-domain.tld/api/mcp/YOUR_POSTIZ_API_KEY
```

Default rate-limit is 30 req/hour. Override via
`-e POSTIZ_RATE_LIMIT_PER_HOUR=120` if you'll batch a lot conversationally.

### 3) Ayrshare docs (optional, for n8n work)

Pure documentation MCP — handy when you're editing the publish workflow
and want Claude to look up Ayrshare's exact param names.

```bash
claude mcp add --transport http --scope user ayrshare-docs \
  https://www.ayrshare.com/docs/mcp
```

Not a publisher. Don't confuse with the (separate) Ayrshare publishing
MCP, which isn't recommended here — the n8n path already wraps Ayrshare's
API directly.

---

## Setup — project-local path (this repo)

If you'd rather scope the MCPs to this project only, the repo already
ships a `.mcp.json` with all four servers. Replace the placeholders:

```jsonc
{
  "mcpServers": {
    "higgsfield":     { "type": "http", "url": "https://mcp.higgsfield.ai/mcp" },
    "posteverywhere": {
      "command": "npx",
      "args": ["-y", "@posteverywhere/mcp"],
      "env": { "POSTEVERYWHERE_API_KEY": "pe_live_REPLACE_ME" }
    },
    "postiz": {
      "type": "http",
      "url": "https://postiz.your-domain.tld/api/mcp/REPLACE_WITH_POSTIZ_API_KEY"
    },
    "ayrshare_docs":  { "type": "http", "url": "https://www.ayrshare.com/docs/mcp" }
  }
}
```

> **Never commit real API keys to the repo.** Replace the placeholder
> with your real value *locally*, and add a git filter or use
> `.env` + a small wrapper script to keep secrets out of source.

A small `.env`-based pattern:

```bash
# .env (gitignored)
POSTEVERYWHERE_API_KEY=pe_live_xxxxxxxxxxxx
POSTIZ_URL=https://postiz.example.com/api/mcp/abcd1234
```

```jsonc
// .mcp.json — references env
{
  "mcpServers": {
    "posteverywhere": {
      "command": "npx",
      "args": ["-y", "@posteverywhere/mcp"],
      "env": { "POSTEVERYWHERE_API_KEY": "${POSTEVERYWHERE_API_KEY}" }
    },
    "postiz": { "type": "http", "url": "${POSTIZ_URL}" }
  }
}
```

Load `.env` into your shell before launching Claude Code (e.g. via
`direnv`, `dotenv-cli`, or shell `source .env`).

---

## Verifying everything works

After restarting Claude Code:

```
/mcp list
```

You should see:

```
✓ higgsfield        connected
✓ posteverywhere    connected   (or postiz)
✓ ayrshare-docs     connected   (optional)
```

Then try a smoke test:

```
> Generate a 5-second 9:16 aerial reveal of a freshly-mowed front
> yard at sunset, using Veo 3.1 via Higgsfield.

> Post the result to my TikTok with caption "Sunset cleanup. Done."
> #cleantok #lawncare via PostEverywhere.
```

If both calls succeed, you're wired up.

---

## How this fits the blueprint

Update `docs/07-ai-stack.md` mental model:

| Old recommendation               | New default                             |
| -------------------------------- | --------------------------------------- |
| "Generative video — Kling 2.0"   | **Higgsfield MCP** (Kling 3.0 + Veo 3.1 + Sora 2 etc. under one tool) |
| "Manual posting — Postiz HTTP"   | **Postiz** still drives n8n, but the **MCP** lets you also publish from chat |

The **daily volume** (30 unique videos/week, 4 platforms) still goes
through **n8n + HTTP**. MCPs are the **creative pilot's seat**, not the
conveyor belt.

---

## Cost ceiling for the MCP layer

| Item                                | Monthly cap                   |
| ----------------------------------- | ----------------------------- |
| Higgsfield credits                  | $0 (free tier) → $25 if needed |
| PostEverywhere (if used)            | $15–29                        |
| Postiz (self-host)                  | $0                            |
| Ayrshare docs MCP                   | $0                            |
| **Add to blueprint total**          | **+$0 to +$54 / mo**          |

Stays within the budget envelope of `docs/13-low-budget.md` ($140/mo cap).

---

## Security checklist

- [ ] `.mcp.json` does not contain real keys (placeholders only).
- [ ] Real keys live in a gitignored `.env` or `~/.claude.json`.
- [ ] Postiz URL with API key is treated as a secret.
- [ ] PostEverywhere key is rotated quarterly.
- [ ] Higgsfield OAuth is bound to a dedicated email (not your personal one).
- [ ] Each MCP's permission scope is reviewed: do not enable writes you
      don't need (`POSTIZ_ENABLE_WRITE=false` if you just want to read state).

---

## Troubleshooting

| Symptom                                              | Fix                                                              |
| ---------------------------------------------------- | ---------------------------------------------------------------- |
| `/mcp list` shows higgsfield as `connecting`         | Open Higgsfield dashboard once in the browser; OAuth needs init  |
| PostEverywhere returns 401                           | Regenerate key, ensure `pe_live_` prefix, restart Claude Code    |
| Postiz returns 404 on tool call                      | Confirm `/api/mcp/{key}` is reachable; check Postiz container logs |
| Two publishers conflict on the same scheduled time   | Use only ONE publisher MCP at a time (Postiz **or** PostEverywhere) |
| n8n and MCP both posted the same video               | Add a `posts.published_by` column; gate MCP path on `manual=true`|

---

## What I (Claude in the session) can and cannot do

- ✅ I CAN write configs into the repo (this file, `.mcp.json`).
- ✅ I CAN tell you exactly which commands to run.
- ✅ I CAN call the MCPs **once they are loaded into a future session**.
- ❌ I CANNOT add MCPs to your persistent Claude Code config from inside
     this session — you (or the Claude Code app) own that surface.
- ❌ I CANNOT pick up edits to `.mcp.json` in the currently-running
     session. Restart required.

For the cloud/web environment specifically: hosted MCPs (Higgsfield,
Postiz) are easiest to add via the Connectors UI in Claude Code on the web
when starting a new session. Stdio MCPs (PostEverywhere via npx) need
either local Claude Code OR a managed runtime that allows stdio servers.
