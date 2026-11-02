"""Prints the UDID of an iPhone simulator whose iOS version is supported by the selected Xcode."""
import json
import subprocess
import sys


def version(text):
    return [int(part) for part in text.replace("-", ".").split(".") if part.isdigit()]


sdk = version(subprocess.check_output(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-version"], text=True).strip())
devices = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))["devices"]

runtimes = []
for runtime, sims in devices.items():
    if ".iOS-" not in runtime:
        continue
    runtime_version = version(runtime.rsplit("iOS-", 1)[1])
    if runtime_version[:2] <= sdk[:2]:
        runtimes.append((runtime_version, sims))

for _, sims in sorted(runtimes, key=lambda item: item[0], reverse=True):
    phones = [s for s in sims if s["name"].startswith("iPhone")]
    preferred = [s for s in phones if "Pro" in s["name"] and "Max" not in s["name"]] or phones
    if preferred:
        print(preferred[0]["udid"])
        sys.exit(0)

sys.exit("No iPhone simulator found")
