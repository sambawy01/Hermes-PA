---
name: demand-forecasting
description: "Predict covers / occupancy for hospitality venues. Combines a historical baseline with adjustment drivers (local events, weather, day-of-week, seasonality, promotions) and returns a forecast with a confidence band and the drivers behind it. Use for staffing, prep, and purchasing decisions."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [forecasting, covers, occupancy, demand, hospitality, staffing, fnb]
    related_skills: [fnb-expert]
---

# Demand Forecasting

Forecast covers (restaurant) or occupancy (hotel) so the operator can staff, prep,
and purchase correctly. Produce a number **with a confidence level and the drivers
behind it** — never a bare guess.

## When to Use

- "How many covers should we expect Friday?"
- Staffing / prep / purchasing for an upcoming day or week.
- Assessing the impact of a local event, holiday, or weather on demand.

## Method

1. **Baseline** — average historical covers for that venue + day-of-week (pull from
   `persona='fnb'` interactions / stored history).
2. **Drivers** — adjust the baseline with multipliers:
   - Local events (search the web for what's on near the venue that day).
   - Weather (good weather lifts terrace/walk-in; storms suppress).
   - Seasonality / holidays.
   - Promotions or marketing pushes.
3. **Confidence** — wider band when history is thin or drivers conflict.

Use the helper to combine baseline + drivers consistently:

```bash
python3 ~/.hermes/skills/demand-forecasting/forecast.py \
    --baseline 120 \
    --driver "local festival,1.25" \
    --driver "good weather,1.10" \
    --driver "midweek,0.95" \
    --confidence medium
```

Always report: the forecast, the band (e.g. 150–185), and the 2–3 drivers that
moved it most. State your assumptions.

## Output

A short, decision-ready answer: "Expect ~165 covers Fri (band 150–185).
Up on the 120 baseline mainly from the jazz festival next door and good weather;
trimmed slightly for it being off-peak season."
