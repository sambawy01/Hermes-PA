#!/command/with-contenv sh
# seed-volume.sh — populate the Railway persistent volume on first boot.
#
# WHY THIS EXISTS
# ---------------
# HERMES_HOME=/opt/data holds config.yaml, profiles/, plugins/, SOUL.md,
# auth.json and runtime state. The Dockerfile bakes a seed into /opt/data at
# build time — but a Railway *persistent volume* mounted at /opt/data mounts
# EMPTY and SHADOWS that baked content (Railway, unlike Docker named volumes,
# does not copy image data into a fresh volume). With config.yaml hidden,
# Hermes loses model.provider=ollama-cloud and dies with "model provider
# failure" even though OLLAMA_API_KEY is set.
#
# So we keep an immutable seed at /opt/railway-seed (OUTSIDE the mount) and:
#   * first boot (empty volume)   -> copy the whole seed into /opt/data
#   * every boot                  -> re-sync config-as-code (config.yaml,
#                                    SOUL.md) from the image so model/provider
#                                    settings always match the deployed image,
#                                    while preserving mutable runtime state
#                                    (sessions, auth.json, cron, caches, kanban).
#
# Runs as cont-init 00-railway-seed, i.e. BEFORE profile reconciliation,
# railway-init, and the gateway — and AFTER the volume is mounted.
set -eu

SEED=/opt/railway-seed
DATA="${HERMES_HOME:-/opt/data}"
log() { printf '[seed-volume] %s\n' "$1"; }

[ -d "$SEED" ] || { log "no seed dir at $SEED, nothing to do"; exit 0; }
mkdir -p "$DATA"

if [ ! -f "$DATA/config.yaml" ]; then
  # First boot onto an empty (or volume-shadowed) data dir.
  log "no config.yaml in $DATA — seeding full state from image"
  cp -a "$SEED/." "$DATA/"
  chown -R hermes:hermes "$DATA"
  log "full seed complete"
  exit 0
fi

# Subsequent boots: keep runtime state, but force config-as-code to match the
# image. This is what prevents a stale/missing config from re-introducing the
# "model provider failure" after future image rebuilds.
for f in config.yaml SOUL.md; do
  if [ -f "$SEED/$f" ]; then
    cp -a "$SEED/$f" "$DATA/$f"
    chown hermes:hermes "$DATA/$f"
    log "re-synced $f from image"
  fi
done
log "config-as-code sync complete"
