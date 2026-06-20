#!/usr/bin/env sh
# railway-init.sh — boot-time materialisation of file-based credentials on Railway.
#
# Railway injects secrets as ENV VARS (read directly by Hermes / the Supabase
# memory plugin via os.environ). A few integrations need real FILES, which we
# write here from base64-encoded Railway variables so no secret is baked into
# the image. Runs once per container start via /etc/cont-init.d/03-railway-init.
set -eu

HOME_DIR="${HERMES_HOME:-/opt/data}"
log() { printf '[railway-init] %s\n' "$1"; }

# --- Git credentials (GitHub PAT) -----------------------------------------
if [ -n "${GITHUB_TOKEN:-}" ] && [ -n "${GITHUB_USER:-}" ]; then
  git config --global credential.helper store || true
  printf 'https://%s:%s@github.com\n' "$GITHUB_USER" "$GITHUB_TOKEN" > "$HOME_DIR/.git-credentials"
  chmod 600 "$HOME_DIR/.git-credentials"
  [ -n "${GIT_AUTHOR_NAME:-}" ]  && git config --global user.name  "$GIT_AUTHOR_NAME"  || true
  [ -n "${GIT_AUTHOR_EMAIL:-}" ] && git config --global user.email "$GIT_AUTHOR_EMAIL" || true
  log "git credentials written"
  # Authenticate gh CLI from the token so GitHub skills work despite
  # _HERMES_PROVIDER_ENV_BLOCKLIST scrubbing GITHUB_TOKEN/GH_TOKEN from
  # terminal subprocesses (GHSA-rhgp-j443-p4rf).  gh stores the token in
  # its own config file, so it survives the env scrub.
  if command -v gh >/dev/null 2>&1; then
    # gh refuses to store credentials when GH_TOKEN/GITHUB_TOKEN are set in
    # the environment ("The value of the GH_TOKEN environment variable is
    # being used for authentication").  Save the token, unset both vars,
    # authenticate, then leave them unset — Hermes scrubs them from
    # subprocesses anyway via _HERMES_PROVIDER_ENV_BLOCKLIST.
    #
    # CRITICAL: railway-init.sh runs as root, but the Hermes terminal tool
    # runs as the "hermes" user (UID 10000, HOME=/opt/data).  gh stores
    # credentials in ~/.config/gh/hosts.yml, so we must authenticate as
    # the hermes user — otherwise gh creds land in /root/.config/gh/ and
    # the hermes user can't see them.
    _gh_token="$GITHUB_TOKEN"
    unset GH_TOKEN GITHUB_TOKEN
    mkdir -p "$HOME_DIR/.config/gh"
    chown hermes:hermes "$HOME_DIR/.config/gh"
    if command -v s6-setuidgid >/dev/null 2>&1; then
      printf '%s' "$_gh_token" | s6-setuidgid hermes gh auth login --with-token >/dev/null 2>&1 && \
        log "gh CLI authenticated (as hermes)" || log "gh CLI auth failed (non-fatal)"
    else
      # Fallback: authenticate as root, then copy hosts.yml to hermes home
      printf '%s' "$_gh_token" | gh auth login --with-token >/dev/null 2>&1
      if [ -f /root/.config/gh/hosts.yml ]; then
        cp /root/.config/gh/hosts.yml "$HOME_DIR/.config/gh/hosts.yml"
        chown hermes:hermes "$HOME_DIR/.config/gh/hosts.yml"
        chmod 600 "$HOME_DIR/.config/gh/hosts.yml"
        log "gh CLI authenticated (copied to hermes home)"
      else
        log "gh CLI auth failed (non-fatal)"
      fi
    fi
  fi
fi

# --- Google Calendar OAuth (Desktop client keys + cached tokens) -----------
# Provide these as base64 in Railway:
#   GCP_OAUTH_KEYS_B64  = base64 of gcp-oauth.keys.json
#   GCAL_TOKENS_B64     = base64 of ~/.config/google-calendar-mcp/tokens.json
if [ -n "${GCP_OAUTH_KEYS_B64:-}" ]; then
  mkdir -p "$HOME_DIR/secrets"
  printf '%s' "$GCP_OAUTH_KEYS_B64" | base64 -d > "$HOME_DIR/secrets/gcp-oauth.keys.json"
  chmod 600 "$HOME_DIR/secrets/gcp-oauth.keys.json"
  log "gcp-oauth.keys.json written"
fi
if [ -n "${GCAL_TOKENS_B64:-}" ]; then
  mkdir -p "$HOME_DIR/.config/google-calendar-mcp"
  printf '%s' "$GCAL_TOKENS_B64" | base64 -d > "$HOME_DIR/.config/google-calendar-mcp/tokens.json"
  chmod 600 "$HOME_DIR/.config/google-calendar-mcp/tokens.json"
  log "google-calendar tokens written"
fi

# --- Warm the local embedder so first recall isn't slow --------------------
python3 - <<'PY' 2>/dev/null || true
try:
    from fastembed import TextEmbedding
    list(TextEmbedding(model_name="nomic-ai/nomic-embed-text-v1.5").embed(["warmup"]))
except Exception:
    pass
PY

log "init complete"
