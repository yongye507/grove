#!/usr/bin/env python3
"""Fetch public App Store data (charts, app metadata, recent reviews) for research.
Read-only requests to Apple's public iTunes/RSS endpoints. No auth, no writes to Apple.
"""
import json
import os
import time
import urllib.parse
import urllib.request

BASE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(BASE, "data")
os.makedirs(DATA, exist_ok=True)

UA = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"}


def get(url, timeout=20):
    for attempt in range(3):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return r.read().decode("utf-8", "replace")
        except Exception as e:
            code = getattr(e, "code", None)
            print(f"  retry {attempt + 1} code={code} {url[:100]}", flush=True)
            time.sleep(12 if code in (403, 429) else 4)
    return None


def save(name, text):
    if text is None:
        print(f"MISS {name}", flush=True)
        return False
    with open(os.path.join(DATA, name), "w") as f:
        f.write(text)
    print(f"OK   {name} ({len(text)} bytes)", flush=True)
    return True


# slug, country, search term, expected substring in trackName (lowercase)
APPS = [
    ("myfitnesspal", "us", "MyFitnessPal Calorie Counter", "myfitnesspal"),
    ("calai", "us", "Cal AI Calorie Tracker", "cal ai"),
    ("calm", "us", "Calm Sleep Meditation", "calm"),
    ("flo", "us", "Flo Period Pregnancy Tracker", "flo"),
    ("picturethis", "us", "PictureThis Plant Identifier", "picturethis"),
    ("alltrails", "us", "AllTrails Hike Bike Run", "alltrails"),
    ("life360", "us", "Life360 Find My Family", "life360"),
    ("remini", "us", "Remini AI Photo Enhancer", "remini"),
    ("forest", "us", "Forest Focus Productivity", "forest"),
    ("widgetsmith", "us", "Widgetsmith", "widgetsmith"),
    ("sleepcycle", "us", "Sleep Cycle Sleep Tracker", "sleep cycle"),
    ("yuka", "us", "Yuka Food Cosmetic Scanner", "yuka"),
    ("duolingo", "us", "Duolingo Language Lessons", "duolingo"),
    ("strava", "us", "Strava Run Ride Hike", "strava"),
    ("notability", "us", "Notability Notes PDF", "notability"),
    ("flighty", "us", "Flighty Flight Tracker", "flighty"),
    ("opal", "us", "Opal Screen Time Control", "opal"),
    ("structured", "us", "Structured Daily Planner", "structured"),
    ("boohee", "cn", "薄荷健康 减肥", "薄荷"),
    ("tide", "cn", "潮汐 睡眠 专注", "潮汐"),
]


def main():
    for cc in ("us", "cn"):
        for kind in ("top-free", "top-paid"):
            url = f"https://rss.applemarketingtools.com/api/v2/{cc}/apps/{kind}/100/apps.json"
            save(f"chart_{cc}_{kind}.json", get(url))
            time.sleep(1.5)

    save(
        "chart_us_topgrossing_legacy.json",
        get("https://itunes.apple.com/us/rss/topgrossingapplications/limit=100/json", timeout=15),
    )
    time.sleep(1.5)

    for slug, cc, term, expect in APPS:
        q = urllib.parse.urlencode({"term": term, "country": cc, "entity": "software", "limit": 5})
        txt = get(f"https://itunes.apple.com/search?{q}")
        save(f"search_{slug}.json", txt)
        time.sleep(2.5)
        appid = None
        if txt:
            try:
                results = json.loads(txt).get("results", [])
                chosen = None
                for r in results:
                    if expect in r.get("trackName", "").lower():
                        chosen = r
                        break
                if chosen is None and results:
                    chosen = results[0]
                    print(f"  WARN {slug}: no exact name match, using {chosen.get('trackName')}", flush=True)
                if chosen:
                    appid = chosen["trackId"]
                    with open(os.path.join(DATA, f"meta_{slug}.json"), "w") as f:
                        json.dump(chosen, f, ensure_ascii=False, indent=1)
            except Exception as e:
                print(f"  parse error {slug}: {e}", flush=True)
        if appid:
            for page in (1, 2):
                u = f"https://itunes.apple.com/{cc}/rss/customerreviews/page={page}/id={appid}/sortby=mostrecent/json"
                save(f"reviews_{slug}_p{page}.json", get(u))
                time.sleep(2.5)
    print("DONE", flush=True)


if __name__ == "__main__":
    main()
