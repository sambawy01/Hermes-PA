# GitHub Secrets — set these for the uptime monitor workflow

# Required for .github/workflows/uptime-monitor.yml
#
# Set via: gh secret set <NAME> --repo sambawy01/Hermes-PA
# Or via:  https://github.com/sambawy01/Hermes-PA/settings/secrets/actions
#
# 1. TELEGRAM_BOT_TOKEN  — the bot token (same as Railway env var)
# 2. TELEGRAM_ALLOWED_USERS — your numeric Telegram user ID (same as Railway env var)
#
# These are used ONLY by the uptime-monitor workflow to send heartbeat
# messages and alerts. They are NOT used by the Railway container.