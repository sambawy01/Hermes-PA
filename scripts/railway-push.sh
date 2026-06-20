#!/usr/bin/env bash
# Push Hermes-PA config to Railway, then build+deploy.
#
# Run from the Hermes-PA repo root:
#   RAILWAY_TOKEN=*** bash scripts/railway-push.sh
#
# Reads secrets from local ~/.hermes/.env — none are hardcoded here.
# The Dockerfile.railway in the repo root clones the Hermes Agent source
# from GitHub at build time, so you don't need the full source tree locally.
set -euo pipefail

: "${RAILWAY_TOKEN:?Set RAILWAY_TOKEN before running}"

# ── Config ────────────────────────────────────────────────────────────────
SERVICE="${SERVICE:-b8142270-6ff5-4af8-a94d-52ab2de13c14}"
ENV_FILE="${ENV_FILE:-$HOME/.hermes/.env}"

# Resolve repo root (parent of scripts/)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

val() { grep -E "^$1=" "$ENV_FILE" | head -1 | cut -d= -f2-; }

echo "→ Setting Railway variables on Hermes-Gateway…"

# ── Set Railway env vars (secrets from local .env, no deploy trigger) ─────
railway variables --service "$SERVICE" \
  --set "RAILWAY_DOCKERFILE_PATH=Dockerfile.railway" \
  --set "OLLAMA_API_KEY=*** OLLAMA_API_KEY)" \
  --set "OLLAMA_BASE_URL=https://ollama.com/v1" \
  --set "EMBED_MODEL=nomic-embed-text" \
  --set "EXTRACT_MODEL=gpt-oss:20b" \
  --set "SUPABASE_MEMORY_URL=$(val SUPABASE_MEMORY_URL)" \
  --set "SUPABASE_MEMORY_KEY=*** SUPABASE_MEMORY_KEY)" \
  --set "GATEWAY_ALLOW_ALL_USERS=false" \
  --set "TELEGRAM_BOT_TOKEN=*** TELEGRAM_BOT_TOKEN)" \
  --set "TELEGRAM_ALLOWED_USERS=$(val TELEGRAM_ALLOWED_USERS)" \
  --set "GITHUB_TOKEN=*** GITHUB_TOKEN)" \
  --set "GH_TOKEN=*** GH_TOKEN)" \
  --set "GITHUB_USER=$(val GITHUB_USER)" \
  --set "GIT_AUTHOR_NAME=*** GIT_AUTHOR_NAME)" \
  --set "GIT_AUTHOR_EMAIL=*** GIT_AUTHOR_EMAIL)" \
  --set "GCP_OAUTH_KEYS_B64=*** -i ~/.hermes/secrets/gcp-oauth.keys.json)" \
  --set "GCAL_TOKENS_B64=*** -i ~/.config/google-calendar-mcp/tokens.json)" \
  --skip-deploys

echo "→ Variables set. Building + deploying from repo root (Dockerfile.railway)…"
cd "$REPO_ROOT"
railway up --service "$SERVICE" --detach --message "deploy from Hermes-PA repo"

echo "✓ Deploy kicked off. Tail logs with:"
echo "  railway logs --service $SERVICE --lines 50"