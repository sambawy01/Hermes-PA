# Hermes-PA

A multi-persona personal/business assistant built on [Hermes Agent](https://hermes-agent.nousresearch.com). One **concierge** front door routes to four specialists, with persistent semantic memory, adaptive learning, Google Calendar, kanban task routing, GitHub access, and a Telegram gateway — runnable locally or 24/7 on Railway.

> This repo is the **declarative rebuild kit** — configs, souls, the custom memory plugin, skills, and the Railway deploy. **No secrets** are committed; supply them via `.env` (see `.env.example`).

## Architecture

```
Telegram / CLI
      │
   CONCIERGE (default profile)  ── classifies + routes, replies as one assistant
      ├─ pa       calendar, reminders, email, briefings   (Google Calendar MCP)
      ├─ coder    repos, code, debug, review, tests        (git + gh)
      ├─ fnb      menu costing, suppliers, forecasting     (fnb-expert, demand-forecasting)
      └─ founder  strategy, financials, fundraising        (entrepreneur-frameworks)
            │
   Supabase (semantic memory + adaptive learning)   ·   Kanban (profile-targeted task execution)
```

- **Model:** `glm-5.2` via Ollama Cloud (all personas).
- **Memory:** custom Supabase plugin (`plugins/memory/supabase/`) — hybrid keyword+vector recall, persona-scoped, local `fastembed` embeddings (`nomic-embed-text-v1.5`, 768-dim). Adaptive learning: session-end LLM extraction + a `supabase_add_rule` feedback loop.
- **Routing:** concierge SOUL handles chat inline; the kanban orchestrator decomposes tasks and assigns them to specialist profiles for execution by the gateway dispatcher.

## Layout

| Path | What |
|---|---|
| `config.yaml`, `SOUL.md` | concierge (default profile) config + routing soul |
| `profiles/<name>/` | the four specialists (config + soul) |
| `plugins/memory/supabase/` | custom Supabase memory provider |
| `skills/` | custom skills: fnb-expert, demand-forecasting, entrepreneur-frameworks |
| `scripts/supabase_migration.sql` | one-time Supabase schema (tables, pgvector, search fns) |
| `scripts/railway-push.sh` | set Railway vars + deploy |
| `railway/Dockerfile.railway` | Railway image (VOLUME stripped, gateway run, fastembed + gh) |
| `railway/railway-init.sh` | boot-time materialisation of git/Google creds from env |
| `railway/railway-state/` | baked seed copied into the image (no secrets) |

## Setup (summary)

1. Install Hermes; copy these files into `~/.hermes/` (configs, `SOUL.md`, `profiles/`, `plugins/`, `skills/`).
2. `cp .env.example ~/.hermes/.env` and fill in real values.
3. Run `scripts/supabase_migration.sql` in the Supabase SQL Editor.
4. `pip install fastembed` into the Hermes venv (local embeddings).
5. Local: `hermes` (concierge) or `hermes -p coder` etc. Cloud: deploy with `scripts/railway-push.sh` using `railway/Dockerfile.railway`.

## Security

- All credentials live in `.env` / the secrets vault — **never** in this repo.
- Telegram is owner-locked (`TELEGRAM_ALLOWED_USERS`); destructive actions (push to main, prod deploys/DB writes, third-party messages) require explicit confirmation.
