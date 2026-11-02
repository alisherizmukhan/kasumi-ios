"""Prints the UDID of an available simulator.

Usage: python3 scripts/pick_simulator.py "iPhone Duo"
With a name, picks that device on the newest runtime that has it.
Without one, picks the newest iPhone Pro (not Max, not Duo).
"""
import json
import subprocess
import sys


def version(runtime):
    return [int(part) for part in runtime.rsplit("iOS-", 1)[1].split("-") if part.isdigit()]


devices = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))["devices"]
runtimes = sorted((r for r in devices if ".iOS-" in r), key=version, reverse=True)
wanted = sys.argv[1] if len(sys.argv) > 1 else None

for runtime in runtimes:
    sims = devices[runtime]
    if wanted:
        matches = [s for s in sims if s["name"] == wanted]
    else:
        phones = [s for s in sims if s["name"].startswith("iPhone") and "Duo" not in s["name"]]
        matches = [s for s in phones if "Pro" in s["name"] and "Max" not in s["name"]] or phones
    if matches:
        print(matches[0]["udid"])
        sys.exit(0)

sys.exit(f"No simulator found for {wanted or 'an iPhone'}")
