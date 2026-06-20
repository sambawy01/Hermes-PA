#!/usr/bin/env bash
# Push Hermes runtime config to Railway, then build+deploy.
# Run as:  RAILWAY_TOKEN=<token> bash ~/.hermes/scripts/railway-push.sh
# Reads secrets from local files — none are hardcoded here.
set -euo pipefail

: "${RAILWAY_TOKEN:?Set RAILWAY_TOKEN before running}"
cd ~/.hermes/hermes-agent

SERVICE="${SERVICE:-b8142270-6ff5-4af8-a94d-52ab2de13c14}"
ENV=~/.hermes/.env
val() { grep -E "^$1=" "$ENV" | head -1 | cut -d= -f2-; }

echo "→ Using service '$SERVICE' (create it in the dashboard first if it doesn't exist)…"

echo "→ Setting Railway variables on '$SERVICE'…"
railway variables --service "$SERVICE" \
  --set "RAILWAY_DOCKERFILE_PATH=Dockerfile.railway" \
  --set "OLLAMA_API_KEY=$(val OLLAMA_API_KEY)" \
  --set "OLLAMA_BASE_URL=https://ollama.com/v1" \
  --set "EMBED_MODEL=nomic-embed-text" \
  --set "EXTRACT_MODEL=gpt-oss:20b" \
  --set "SUPABASE_MEMORY_URL=$(val SUPABASE_MEMORY_URL)" \
  --set "SUPABASE_MEMORY_KEY=$(val SUPABASE_MEMORY_KEY)" \
  --set "GATEWAY_ALLOW_ALL_USERS=false" \
  --set "TELEGRAM_BOT_TOKEN=$(val TELEGRAM_BOT_TOKEN)" \
  --set "TELEGRAM_ALLOWED_USERS=$(val TELEGRAM_ALLOWED_USERS)" \
  --set "GITHUB_TOKEN=$(val GITHUB_TOKEN)" \
  --set "GH_TOKEN=$(val GH_TOKEN)" \
  --set "GITHUB_USER=$(val GITHUB_USER)" \
  --set "GIT_AUTHOR_NAME=$(val GIT_AUTHOR_NAME)" \
  --set "GIT_AUTHOR_EMAIL=$(val GIT_AUTHOR_EMAIL)" \
  --set "GCP_OAUTH_KEYS_B64=$(base64 -i ~/.hermes/secrets/gcp-oauth.keys.json)" \
  --set "GCAL_TOKENS_B64=$(base64 -i ~/.config/google-calendar-mcp/tokens.json)" \
  --skip-deploys

echo "→ Variables set. Building + deploying to '$SERVICE' (slow on first build)…"
railway up --service "$SERVICE" --detach

echo "✓ Deploy kicked off. Tail logs with:"
echo "    RAILWAY_TOKEN=\$RAILWAY_TOKEN railway logs"
echo
echo "NOTE: the gateway needs TELEGRAM_BOT_TOKEN to actually answer. Add it later with:"
echo "    RAILWAY_TOKEN=\$RAILWAY_TOKEN railway variables --set TELEGRAM_BOT_TOKEN=<token> --set TELEGRAM_ALLOWED_USERS=<your-id>"
