---
name: fnb-expert
description: "Food & beverage / hospitality operations brain. Use for menu engineering (stars/plowhorses/puzzles/dogs), plate & recipe costing, food-cost % and pour-cost targets, HACCP & food-safety SOPs, beverage programme design, supplier/inventory logic, and hospitality KPIs (RevPAR, ADR, GOP). Pairs with the cost_card.py helper for plate costing."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [fnb, hospitality, menu-engineering, costing, food-cost, haccp, kpi, restaurant]
    related_skills: [demand-forecasting]
---

# F&B Expert

Operations knowledge for running food & beverage venues. Reach for this whenever the
task involves menu economics, costing, suppliers, food safety, or hospitality KPIs.

## When to Use

- Costing a plate or a recipe; setting a menu price to hit a food-cost % target.
- Engineering a menu (classifying items as stars / plowhorses / puzzles / dogs).
- Setting pour-cost targets for the bar / beverage programme.
- Reviewing food-safety / HACCP practices.
- Reasoning about supplier terms, inventory, or hospitality KPIs (RevPAR, ADR, GOP).

## Menu Engineering

Classify every menu item on two axes — **popularity** (units sold vs. menu average)
and **contribution margin** (price − plate cost):

| | High margin | Low margin |
|---|---|---|
| **High popularity** | ⭐ Star — feature it, protect the recipe | 🐎 Plowhorse — re-cost, trim portion, nudge price |
| **Low popularity** | 🧩 Puzzle — reposition / rename / promote | 🐕 Dog — remove or rework |

Target food-cost % is typically **28–35%** for food, **18–24%** pour cost for
beverage (venue-dependent). Always state the target you're costing against.

## Plate Costing

Use the helper for the arithmetic — don't eyeball it:

```bash
python3 ~/.hermes/skills/fnb-expert/cost_card.py --help
```

It takes ingredient lines (name, pack price, pack qty, used qty) and a target
food-cost %, and returns total plate cost, the suggested price to hit that target,
and the resulting margin. Show the operator the inputs, the assumptions, then the
numbers.

## KPIs (quick reference)

- **Food cost %** = food cost ÷ food revenue.
- **RevPAR** = room revenue ÷ available rooms (= ADR × occupancy).
- **ADR** = room revenue ÷ rooms sold.
- **GOP** = gross operating profit (revenue − operating expenses).

## Food Safety

Flag HACCP risks proactively: cold-chain breaks, danger-zone holding
(5–63 °C), cross-contamination, allergen handling, and traceability gaps.

## Memory

Store suppliers, recipes, and cost cards under `persona='fnb'`.
