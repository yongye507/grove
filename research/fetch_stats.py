#!/usr/bin/env python3
"""Best-effort fetch of public revenue/statistics pages to ground estimates."""
import os
import time
import urllib.request

BASE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(BASE, "data", "stats")
os.makedirs(DATA, exist_ok=True)
UA = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml",
    "Accept-Language": "en-US,en;q=0.9",
}

PAGES = {
    "myfitnesspal": "https://www.businessofapps.com/data/my-fitnesspal-statistics/",
    "flo": "https://www.businessofapps.com/data/flo-statistics/",
    "life360": "https://www.businessofapps.com/data/life360-statistics/",
    "strava": "https://www.businessofapps.com/data/strava-statistics/",
    "alltrails": "https://www.businessofapps.com/data/alltrails-statistics/",
    "calm": "https://www.businessofapps.com/data/calm-statistics/",
    "sleepcycle": "https://www.businessofapps.com/data/sleep-cycle-statistics/",
    "picturethis": "https://www.businessofapps.com/data/picturethis-statistics/",
}

for slug, url in PAGES.items():
    try:
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req, timeout=15) as r:
            html = r.read().decode("utf-8", "replace")
        with open(os.path.join(DATA, f"{slug}.html"), "w") as f:
            f.write(html)
        print(f"OK {slug} ({len(html)})", flush=True)
    except Exception as e:
        print(f"MISS {slug}: {getattr(e, 'code', e)}", flush=True)
    time.sleep(2)
print("DONE", flush=True)
