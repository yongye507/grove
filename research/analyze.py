#!/usr/bin/env python3
"""Analyze fetched App Store data: metadata table + review complaint themes."""
import json
import os
import re
from collections import Counter

BASE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(BASE, "data")

THEMES_EN = {
    "price/subscription": r"subscript|expensive|paywall|pricey|overpriced|\bpay\b|paid|charged|charging|refund|scam|cancel|trial|money|\bcost\b|greedy|cash grab",
    "ads": r"\bads?\b|advert|commercial",
    "bugs/crash": r"crash|\bbug|broken|freez|glitch|\berror\b|won't (open|load|work)|doesn't work|stopped working|not working|laggy|\blag\b",
    "update/regression": r"\bupdate|new version|used to|bring back|removed|downgrade|redesign|ui change|new ui",
    "sync/account/data-loss": r"\bsync\b|log ?in|sign ?in|account|password|lost (my )?data|data loss|deleted my|disappeared|restore",
    "accuracy": r"inaccurate|accuracy|\bwrong\b|incorrect|misidentif|not accurate",
    "privacy": r"privacy|selling (my|our|user)|sell (my|our|user)|data broker|creepy|stalker",
    "support": r"customer (service|support)|no response|never (replied|responded)|support team|contacted support",
    "missing-feature": r"\bwish\b|please add|add (an?|the) (option|feature|ability)|should (have|allow)|no option|can't even|offline",
}
THEMES_CN = {
    "price/subscription": r"收费|会员|订阅|续费|退款|骗|坑|割韭菜|价格|太贵|付费|扣费|扣款|试用",
    "ads": r"广告",
    "bugs/crash": r"闪退|卡顿|卡死|bug|崩溃|打不开|加载|白屏|发热|耗电",
    "update/regression": r"更新|新版|以前|旧版|越改越|改版",
    "sync/account/data-loss": r"同步|登录|账号|注销|数据丢失|记录没了|丢失",
    "accuracy": r"不准|误差|识别错|不对",
    "privacy": r"隐私|泄露|窃取",
    "support": r"客服|没人理|不回复|售后",
    "missing-feature": r"希望|建议|能不能|为什么不能|没有.{0,6}功能|缺少",
}


def load(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return None


def reviews_for(slug):
    out = {}
    files = sorted(f for f in os.listdir(DATA) if f.startswith(f"reviews_{slug}_"))
    for fname in files:
        j = load(os.path.join(DATA, fname))
        if not j:
            continue
        entries = j.get("feed", {}).get("entry", [])
        if isinstance(entries, dict):
            entries = [entries]
        for e in entries:
            if "im:rating" not in e:
                continue
            rid = e.get("id", {}).get("label")
            out[rid] = {
                "rating": int(e["im:rating"]["label"]),
                "title": e.get("title", {}).get("label", ""),
                "content": e.get("content", {}).get("label", ""),
                "version": e.get("im:version", {}).get("label", ""),
                "date": e.get("updated", {}).get("label", "")[:10],
            }
    return list(out.values())


def main():
    slugs = sorted(
        f[len("meta_"):-len(".json")]
        for f in os.listdir(DATA)
        if f.startswith("meta_")
    )
    report = []
    for slug in slugs:
        meta = load(os.path.join(DATA, f"meta_{slug}.json")) or {}
        revs = reviews_for(slug)
        low = [r for r in revs if r["rating"] <= 3]
        themes = THEMES_CN if slug in ("boohee", "tide") else THEMES_EN
        counts = Counter()
        samples = {t: [] for t in themes}
        for r in low:
            text = (r["title"] + " " + r["content"]).lower()
            for t, pat in themes.items():
                if re.search(pat, text, re.IGNORECASE):
                    counts[t] += 1
                    if len(r["content"]) > 60 and len(samples[t]) < 3:
                        samples[t].append(
                            f"[{r['rating']}★ {r['date']} v{r['version']}] {r['title']} — {r['content'][:400]}"
                        )
        report.append({
            "slug": slug,
            "name": meta.get("trackName"),
            "seller": meta.get("sellerName"),
            "price": meta.get("formattedPrice"),
            "rating": round(meta.get("averageUserRating") or 0, 2),
            "ratingCount": meta.get("userRatingCount"),
            "genres": meta.get("genres"),
            "lastUpdate": (meta.get("currentVersionReleaseDate") or "")[:10],
            "released": (meta.get("releaseDate") or "")[:10],
            "reviewsFetched": len(revs),
            "lowShare": round(len(low) / len(revs), 2) if revs else None,
            "themes": dict(counts.most_common()),
            "samples": {t: s for t, s in samples.items() if s},
        })
    with open(os.path.join(BASE, "analysis.json"), "w") as f:
        json.dump(report, f, ensure_ascii=False, indent=1)

    for r in report:
        print(f"\n=== {r['slug']} | {r['name']} | {r['seller']}")
        print(f"    price={r['price']} rating={r['rating']} ({r['ratingCount']:,} ratings) genres={r['genres']}")
        print(f"    released={r['released']} lastUpdate={r['lastUpdate']}")
        print(f"    reviewsFetched={r['reviewsFetched']} lowShare={r['lowShare']}")
        print(f"    themes={r['themes']}")

    for cc in ("us", "cn"):
        for kind in ("top-free", "top-paid"):
            j = load(os.path.join(DATA, f"chart_{cc}_{kind}.json"))
            if not j:
                continue
            results = j.get("feed", {}).get("results", [])
            print(f"\n--- CHART {cc} {kind} (top 25 of {len(results)}) ---")
            for i, a in enumerate(results[:25], 1):
                genres = ",".join(g["name"] for g in a.get("genres", [])[:2])
                print(f"{i:2}. {a.get('name')} [{genres}]")


if __name__ == "__main__":
    main()
