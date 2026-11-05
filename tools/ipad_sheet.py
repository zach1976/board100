#!/usr/bin/env python3
"""Every iPad screenshot an app is about to submit, on one page, all at once.

The release review page puts each locale behind a tab, which is right for
reading one locale's text and wrong for the question "do these fifty-five
pictures look alike" — you cannot compare what you cannot see side by side.
This writes one flat page: every locale, every shot, in order, no tabs.

Images are embedded, so the page reads with the network off.

    python3 tools/ipad_sheet.py fieldHockey
    open -a "Google Chrome" tools/ipad_sheet_fieldHockey.html
"""
import base64
import io
import pathlib
import sys

from PIL import Image

REPO = pathlib.Path(__file__).resolve().parent.parent
SHOTS = REPO / "tactics_board" / "fastlane" / "screenshots_ipad"

LOCALE_NAMES = {
    "en-US": "English (US)", "en-GB": "English (UK)", "zh-Hans": "简体中文",
    "zh-Hant": "繁體中文", "ja": "日本語", "ko": "한국어", "es-ES": "Español",
    "fr-FR": "Français", "id": "Bahasa Indonesia", "ms": "Bahasa Melayu",
    "th": "ไทย", "vi": "Tiếng Việt", "de-DE": "Deutsch", "nl-NL": "Nederlands",
}


def thumb(path: pathlib.Path, width: int) -> tuple[str, tuple[int, int]]:
    """A data: URI at [width] points across, and the source's real size."""
    im = Image.open(path)
    size = im.size
    im = im.convert("RGB")
    scale = width / im.width
    im = im.resize((width, max(1, round(im.height * scale))), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=82, optimize=True)
    return ("data:image/jpeg;base64,"
            + base64.b64encode(buf.getvalue()).decode()), size


def main() -> int:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    key = sys.argv[1]
    root = SHOTS / key
    if not root.is_dir():
        sys.exit(f"没有 iPad 截图: {root}")

    locales = sorted((d.name for d in root.iterdir() if d.is_dir()),
                     key=lambda l: (l != "en-US", l))
    blocks, total, sizes = [], 0, set()
    for loc in locales:
        shots = sorted((root / loc).glob("*.png"))
        if not shots:
            continue
        cells = []
        for p in shots:
            src, size = thumb(p, 380)
            sizes.add(size)
            cells.append(
                f'<figure><img loading="lazy" src="{src}" alt="">'
                f'<figcaption>{p.name}</figcaption></figure>')
            total += 1
        blocks.append(
            f'<section><h2>{LOCALE_NAMES.get(loc, loc)} '
            f'<span class="code">{loc}</span> '
            f'<span class="n">{len(shots)} 张</span></h2>'
            f'<div class="row">{"".join(cells)}</div></section>')

    dims = " · ".join(f"{w}×{h}" for w, h in sorted(sizes))
    out = REPO / "tools" / f"ipad_sheet_{key}.html"
    out.write_text(PAGE.format(key=key, total=total, n_loc=len(blocks),
                               dims=dims, blocks="".join(blocks)),
                   encoding="utf-8")
    print(f"wrote {out}  ({out.stat().st_size / 1_048_576:.1f} MB)")
    return 0


PAGE = """<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{key} · iPad 截图全览</title>
<style>
  :root{{color-scheme:dark;--bg:#0e1112;--panel:#161b1d;--line:#2a3336;
    --text:#e8eef0;--dim:#9fb0b5;--accent:#4dd0e1;
    --body:"PingFang SC","Hiragino Sans GB",sans-serif;--mono:"SF Mono",Menlo,monospace}}
  *{{box-sizing:border-box}}
  body{{margin:0;background:var(--bg);color:var(--text);
    font:15px/1.6 var(--body);-webkit-font-smoothing:antialiased}}
  .wrap{{max-width:2200px;margin:0 auto;padding:26px 18px 90px}}
  h1{{font-size:26px;margin:0 0 6px}}
  .lede{{color:var(--dim);margin:0 0 18px}}
  .tally{{display:flex;gap:10px;flex-wrap:wrap;margin:0 0 10px}}
  .tally div{{background:var(--panel);border:1px solid var(--line);
    border-radius:10px;padding:9px 14px;min-width:130px}}
  .tally b{{display:block;font-size:20px}}
  .tally span{{color:var(--dim);font-size:12.5px}}
  h2{{font-size:17px;margin:34px 0 10px;padding-bottom:6px;
    border-bottom:1px solid var(--line);font-weight:800}}
  h2 .code{{font-family:var(--mono);font-size:12.5px;color:var(--accent);
    font-weight:400;margin-left:8px}}
  h2 .n{{color:var(--dim);font-size:12.5px;font-weight:400;margin-left:8px}}
  .row{{display:flex;gap:14px;flex-wrap:nowrap;overflow-x:auto;
    padding-bottom:10px}}
  figure{{margin:0;flex:0 0 auto}}
  figure img{{display:block;width:380px;border-radius:10px;
    border:1px solid var(--line);background:#000}}
  figcaption{{color:var(--dim);font-family:var(--mono);font-size:11px;
    margin-top:6px}}
  footer{{color:#5b6d72;font-size:12.5px;margin-top:44px;padding-top:18px;
    border-top:1px solid var(--line)}}
</style></head>
<body><div class="wrap">
<h1>{key} · iPad 截图全览</h1>
<p class="lede">每个语言一行，全部摊开，没有标签页。横向可以滚。</p>
<div class="tally">
  <div><b>{total}</b><span>iPad 截图</span></div>
  <div><b>{n_loc}</b><span>语言</span></div>
  <div><b>{dims}</b><span>像素尺寸</span></div>
</div>
{blocks}
<footer>tactics_board/fastlane/screenshots_ipad/{key}/ · 由 tools/ipad_sheet.py 生成</footer>
</div></body></html>
"""


if __name__ == "__main__":
    raise SystemExit(main())
