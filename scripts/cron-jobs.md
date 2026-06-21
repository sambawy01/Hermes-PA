# Cron Jobs — create these on Railway after deploy
#
# Run these commands from a Telegram session with the bot, or via
# `hermes cron create` in the Railway container shell.
#
# 1. Morning Briefing (daily 7am Cairo time)
#    Schedule: 0 7 * * *
#    Prompt: "Good morning. Give me a concise daily briefing:
#             (1) Check today's calendar events using get-current-time then list-events.
#             (2) Flag anything that needs a decision or prep.
#             (3) Note any open GitHub PRs or failing CI on my repos.
#             (4) One line on weather in Cairo.
#             Keep it scannable — no filler. UK English."
#
#    To create via Telegram:
#    /cron create 0 7 * * * Good morning. Give me a concise daily briefing: (1) Check today's calendar events using get-current-time then list-events. (2) Flag anything that needs a decision or prep. (3) Note any open GitHub PRs or failing CI on my repos. (4) One line on weather in Cairo. Keep it scannable. UK English.