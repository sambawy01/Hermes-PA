#!/usr/bin/env python3
"""Create cron jobs on the Hermes instance.

Run this inside the Railway container (or locally) to ensure the
morning briefing and heartbeat cron jobs exist.

Usage:
  python3 scripts/setup-cron-jobs.py

This is idempotent — it checks for existing jobs by name and only
creates missing ones.
"""
import json
import os
import subprocess
import sys

JOBS = [
    {
        "name": "morning-briefing",
        "schedule": "0 7 * * *",
        "prompt": (
            "Good morning. Give me a concise daily briefing: "
            "(1) Check today's calendar events using get-current-time then list-events. "
            "(2) Flag anything that needs a decision or prep. "
            "(3) Note any open GitHub PRs or failing CI on my repos. "
            "(4) One line on weather in Cairo. "
            "Keep it scannable — no filler. UK English."
        ),
    },
    {
        "name": "heartbeat",
        "schedule": "*/15 * * * *",
        "script": "scripts/heartbeat.py",
        "no_agent": True,
    },
    {
        "name": "error-monitor",
        "schedule": "*/30 * * * *",
        "script": "scripts/error-monitor.py",
        "no_agent": True,
    },
]

def run_cron_list():
    """Get existing cron jobs as JSON."""
    try:
        result = subprocess.run(
            ["hermes", "cron", "list", "--json"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            return json.loads(result.stdout)
    except Exception:
        pass
    return []

def cron_job_exists(jobs, name):
    """Check if a job with the given name exists."""
    for job in jobs:
        if job.get("name") == name:
            return True
    return False

def create_cron_job(job):
    """Create a single cron job via hermes CLI."""
    cmd = ["hermes", "cron", "create", job["schedule"]]

    if job.get("no_agent"):
        cmd.append("--no-agent")

    if job.get("script"):
        cmd.extend(["--script", job["script"]])

    if job.get("prompt"):
        cmd.append(job["prompt"])  # prompt is a positional arg, not --prompt

    cmd.extend(["--name", job["name"]])

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        if result.returncode == 0:
            print(f"  Created: {job['name']}")
            return True
        else:
            print(f"  Failed to create {job['name']}: {result.stderr}")
            return False
    except Exception as e:
        print(f"  Error creating {job['name']}: {e}")
        return False

def main():
    print("Checking existing cron jobs...")
    existing = run_cron_list()
    existing_names = {j.get("name") for j in existing} if isinstance(existing, list) else set()

    if existing:
        print(f"  Found {len(existing)} existing jobs: {existing_names}")

    created = 0
    for job in JOBS:
        if job["name"] in existing_names:
            print(f"  Skip (exists): {job['name']}")
            continue
        if create_cron_job(job):
            created += 1

    print(f"\nDone: {created} jobs created, {len(JOBS) - created} already existed")

if __name__ == "__main__":
    main()