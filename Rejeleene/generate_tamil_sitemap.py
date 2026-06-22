from pathlib import Path
from datetime import datetime, timezone
from xml.sax.saxutils import escape

BASE_URL = "https://rickrejeleene.me/Tamil"
ROOT = Path("_site").resolve()

urls = []

for html_file in ROOT.rglob("*.html"):
    rel = html_file.relative_to(ROOT)
    parts = set(rel.parts)

    # skip Quarto/reveal helper files
    if "site_libs" in parts:
        continue

    rel_path = rel.as_posix()

    if rel_path == "index.html":
        url = f"{BASE_URL}/"
    elif rel_path.endswith("/index.html"):
        url = f"{BASE_URL}/{rel_path[:-10]}"
    else:
        url = f"{BASE_URL}/{rel_path}"

    lastmod = datetime.fromtimestamp(
        html_file.stat().st_mtime,
        tz=timezone.utc
    ).date().isoformat()

    urls.append((url, lastmod))

urls = sorted(set(urls))

xml = ['<?xml version="1.0" encoding="UTF-8"?>']
xml.append('<urlset xmlns="https://www.sitemaps.org/schemas/sitemap/0.9">')

for url, lastmod in urls:
    xml.append("  <url>")
    xml.append(f"    <loc>{escape(url)}</loc>")
    xml.append(f"    <lastmod>{lastmod}</lastmod>")
    xml.append("  </url>")

xml.append("</urlset>")

Path("tamil-sitemap.xml").write_text("\n".join(xml), encoding="utf-8")

print(f"Generated tamil-sitemap.xml with {len(urls)} clean URLs from _site/")
