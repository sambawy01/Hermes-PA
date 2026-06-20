#!/usr/bin/env python3
"""cost_card.py — plate / recipe costing helper for the fnb-expert skill.

Computes total plate cost from ingredient lines, then the suggested menu price to
hit a target food-cost %, and the resulting contribution margin.

Ingredient line format (repeatable --line), comma-separated:
    name,pack_price,pack_qty,used_qty
where pack_price is the price you pay for a pack, pack_qty is how much that pack
contains, and used_qty is how much of it the dish uses (same unit as pack_qty).

Example:
    python3 cost_card.py \
        --line "chicken breast,42.00,5000,220" \
        --line "olive oil,28.00,1000,15" \
        --line "rosemary,3.50,50,2" \
        --target-food-cost 30 --yield 1

    # multi-portion recipe: pass --yield 4 to cost per portion.
"""
import argparse
import sys


def parse_line(raw: str):
    parts = [p.strip() for p in raw.split(",")]
    if len(parts) != 4:
        sys.exit(f"Bad --line {raw!r}: expected name,pack_price,pack_qty,used_qty")
    name, pack_price, pack_qty, used_qty = parts
    try:
        pack_price = float(pack_price)
        pack_qty = float(pack_qty)
        used_qty = float(used_qty)
    except ValueError:
        sys.exit(f"Bad --line {raw!r}: price/qty must be numbers")
    if pack_qty <= 0:
        sys.exit(f"Bad --line {raw!r}: pack_qty must be > 0")
    unit_cost = pack_price / pack_qty
    line_cost = unit_cost * used_qty
    return {"name": name, "used_qty": used_qty, "unit_cost": unit_cost,
            "line_cost": line_cost}


def main():
    ap = argparse.ArgumentParser(description="Plate/recipe costing helper")
    ap.add_argument("--line", action="append", default=[], required=True,
                    help="name,pack_price,pack_qty,used_qty (repeatable)")
    ap.add_argument("--target-food-cost", type=float, default=30.0,
                    help="target food-cost %% (default 30)")
    ap.add_argument("--yield", dest="yield_", type=float, default=1.0,
                    help="number of portions the recipe yields (default 1)")
    ap.add_argument("--waste", type=float, default=0.0,
                    help="waste/trim buffer %% added to ingredient cost (default 0)")
    args = ap.parse_args()

    if args.yield_ <= 0:
        sys.exit("--yield must be > 0")
    if not (0 < args.target_food_cost < 100):
        sys.exit("--target-food-cost must be between 0 and 100")

    lines = [parse_line(x) for x in args.line]
    raw_cost = sum(l["line_cost"] for l in lines)
    cost_with_waste = raw_cost * (1 + args.waste / 100.0)
    plate_cost = cost_with_waste / args.yield_
    suggested_price = plate_cost / (args.target_food_cost / 100.0)
    margin = suggested_price - plate_cost

    print("Ingredient breakdown")
    print("-" * 52)
    for l in lines:
        print(f"  {l['name']:<28} {l['used_qty']:>8.2f}  "
              f"= {l['line_cost']:>8.3f}")
    print("-" * 52)
    print(f"  Raw ingredient cost{'':<9} = {raw_cost:>10.3f}")
    if args.waste:
        print(f"  + waste buffer ({args.waste:.0f}%){'':<5} = {cost_with_waste:>10.3f}")
    if args.yield_ != 1:
        print(f"  Portions (yield){'':<12} = {args.yield_:>10.0f}")
    print()
    print(f"  Plate cost                = {plate_cost:>10.3f}")
    print(f"  Target food-cost %        = {args.target_food_cost:>10.1f}")
    print(f"  Suggested menu price      = {suggested_price:>10.2f}")
    print(f"  Contribution margin       = {margin:>10.2f}"
          f"  ({(margin/suggested_price*100):.1f}%)")


if __name__ == "__main__":
    main()
