#!/usr/bin/env python3
"""Retry review fetches for apps whose first-pass feeds came back empty."""
import json
import os
import time
import urllib.request

BASE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(BASE, "data")
UA = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"}

MISSING = [
    ("alltrails", "us"), ("calm", "us"), ("flighty", "us"), ("forest", "us"),
    ("myfitnesspal", "us"), ("notability", "us"), ("picturethis", "us"),
    ("remini", "us"), ("sleepcycle", "us"), ("strava", "us"),
    ("structured", "us"), ("tide", "cn"),
]


def get(url, timeout=20):
    for attempt in range(2):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return r.read().decode("utf-8", "replace")
        except Exception as e:
            print(f"  retry code={getattr(e, 'code', None)} {url[:90]}", flush=True)
            time.sleep(10)
    return None


def good(txt):
    if not txt or len(txt) < 2000:
        return False
    try:
        j = json.loads(txt)
        entries = j.get("feed", {}).get("entry", [])
        if isinstance(entries, dict):
            entries = [entries]
        return any("im:rating" in e for e in entries)
    except Exception:
        return False


def main():
    txt = get("https://itunes.apple.com/cn/rss/topgrossingapplications/limit=100/json")
    if txt:
        with open(os.path.join(DATA, "chart_cn_topgrossing_legacy.json"), "w") as f:
            f.write(txt)
        print(f"OK chart_cn_topgrossing ({len(txt)})", flush=True)
    time.sleep(2)

    for slug, cc in MISSING:
        meta = json.load(open(os.path.join(DATA, f"meta_{slug}.json")))
        appid = meta["trackId"]
        got = 0
        for page in (1, 2, 3, 4, 5):
            url = f"https://itunes.apple.com/{cc}/rss/customerreviews/page={page}/id={appid}/sortby=mostrecent/json"
            txt = get(url)
            time.sleep(3)
            if good(txt):
                with open(os.path.join(DATA, f"reviews_{slug}_p{page}.json"), "w") as f:
                    f.write(txt)
                got += 1
                print(f"OK reviews_{slug}_p{page} ({len(txt)})", flush=True)
                if got >= 2:
                    break
        if got == 0:
            alt_ok = False
            for suffix in ("sortBy=mostRecent", "page=2/sortBy=mostRecent"):
                url = f"https://itunes.apple.com/{cc}/rss/customerreviews/id={appid}/{suffix}/json"
                txt = get(url)
                time.sleep(3)
                if good(txt):
                    with open(os.path.join(DATA, f"reviews_{slug}_alt.json"), "w") as f:
                        f.write(txt)
                    print(f"OK reviews_{slug}_alt ({len(txt)})", flush=True)
                    alt_ok = True
                    break
        if got == 0 and not alt_ok:
            print(f"STILL-EMPTY {slug}", flush=True)
    print("DONE", flush=True)


if __name__ == "__main__":
    main()
