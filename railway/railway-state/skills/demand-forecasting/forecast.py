#!/usr/bin/env python3
"""forecast.py — combine a demand baseline with driver multipliers.

Takes a historical baseline (covers or occupancy) and a set of named driver
multipliers, returns the point forecast plus a confidence band.

    python3 forecast.py --baseline 120 \
        --driver "local festival,1.25" \
        --driver "good weather,1.10" \
        --driver "midweek,0.95" \
        --confidence medium

--confidence sets the band width: high=±8%, medium=±15%, low=±25%.
"""
import argparse
import sys

BANDS = {"high": 0.08, "medium": 0.15, "low": 0.25}


def parse_driver(raw: str):
    parts = [p.strip() for p in raw.split(",")]
    if len(parts) != 2:
        sys.exit(f"Bad --driver {raw!r}: expected 'name,multiplier'")
    name, mult = parts
    try:
        mult = float(mult)
    except ValueError:
        sys.exit(f"Bad --driver {raw!r}: multiplier must be a number")
    if mult <= 0:
        sys.exit(f"Bad --driver {raw!r}: multiplier must be > 0")
    return name, mult


def main():
    ap = argparse.ArgumentParser(description="Demand forecast = baseline x drivers")
    ap.add_argument("--baseline", type=float, required=True,
                    help="historical baseline covers / occupancy")
    ap.add_argument("--driver", action="append", default=[],
                    help="'name,multiplier' (repeatable); 1.0 = neutral")
    ap.add_argument("--confidence", choices=BANDS, default="medium")
    args = ap.parse_args()

    if args.baseline < 0:
        sys.exit("--baseline must be >= 0")

    drivers = [parse_driver(d) for d in args.driver]
    factor = 1.0
    for _, m in drivers:
        factor *= m
    point = args.baseline * factor
    band = BANDS[args.confidence]
    low = point * (1 - band)
    high = point * (1 + band)

    print(f"Baseline                : {args.baseline:.0f}")
    if drivers:
        print("Drivers")
        for name, m in sorted(drivers, key=lambda x: abs(x[1] - 1), reverse=True):
            arrow = "▲" if m > 1 else ("▼" if m < 1 else "•")
            print(f"  {arrow} {name:<24} x{m:.2f}")
        print(f"Combined factor         : x{factor:.3f}")
    print(f"Forecast                : {point:.0f}")
    print(f"Confidence ({args.confidence:<6})      : band {low:.0f}–{high:.0f}")


if __name__ == "__main__":
    main()
