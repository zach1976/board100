#!/usr/bin/env python3
"""One page with everything an app is about to be released with.

Reads the app's own store files off disk — metadata, screenshots, the built
package — and writes a self-contained HTML review. Nothing is fetched: the
images are embedded, so the page reads with the network off and survives
being sent to somebody.

    python3 tools/release_review.py soccer
    open -a "Google Chrome" tools/release_review.html
"""
import base64, html, io, json, pathlib, plistlib, subprocess, sys

from PIL import Image

REPO = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / 'tools'))
from apps import APPS, metadata_dir, screenshots_dir, play_metadata_dir  # noqa: E402

# App Store locale → the name a reader knows it by.
LOCALE_NAMES = {
    'en-US': 'English (US)', 'en-GB': 'English (UK)', 'zh-Hans': '简体中文',
    'zh-Hant': '繁體中文', 'ja': '日本語', 'ko': '한국어', 'es-ES': 'Español',
    'fr-FR': 'Français', 'id': 'Bahasa Indonesia', 'ms': 'Bahasa Melayu',
    'th': 'ไทย', 'vi': 'Tiếng Việt',
}
PLAY_NAMES = dict(LOCALE_NAMES, **{'zh-CN': '简体中文', 'zh-TW': '繁體中文',
                                   'ja-JP': '日本語', 'ko-KR': '한국어'})
# The App Store's own limits, so a field that will be rejected says so here.
LIMITS = {'name': 30, 'subtitle': 30, 'keywords': 100, 'promotional_text': 170,
          'release_notes': 4000, 'description': 4000}
FIELD_LABEL = {'name': '名称', 'subtitle': '副标题', 'keywords': '关键词',
               'promotional_text': '推广文本', 'release_notes': '更新说明',
               'description': '描述'}


def thumb(path: pathlib.Path, width: int, quality: int = 72) -> str:
    """An embedded copy, sized for the width it will be DRAWN at.

    Twice that, because the reader is on a Retina screen: an image encoded
    at the CSS width is drawn at half the pixels it needs and looks soft,
    which is what the Mac shots did at 520 across a 1148pt column.
    """
    im = Image.open(path).convert('RGB')
    im.thumbnail((width * 2, width * 8), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, 'JPEG', quality=quality, optimize=True)
    return 'data:image/jpeg;base64,' + base64.b64encode(buf.getvalue()).decode()


def read(p: pathlib.Path) -> str:
    return p.read_text().strip() if p.exists() else ''


def esc(s: str) -> str:
    return html.escape(s)


def field_block(loc: str, name: str, text: str) -> str:
    limit = LIMITS.get(name)
    n = len(text)
    over = limit is not None and n > limit
    count = f'{n}/{limit}' if limit else str(n)
    cls = ' over' if over else ''
    return (f'<div class="field{cls}">'
            f'<div class="fhead"><b>{FIELD_LABEL.get(name, name)}</b>'
            f'<span class="count">{count}</span>'
            f'<button class="copy" data-copy>复制</button></div>'
            f'<pre>{esc(text)}</pre></div>')


def main() -> None:
    key = sys.argv[1] if len(sys.argv) > 1 else 'soccer'
    app = APPS[key]
    app_dir = REPO / app['dir']
    version = ''
    for line in (app_dir / 'pubspec.yaml').read_text().splitlines():
        if line.startswith('version:'):
            version = line.split(':', 1)[1].strip()

    # ── iOS metadata ──────────────────────────────────────────────────────
    md = pathlib.Path(metadata_dir(key))
    shots_dir = pathlib.Path(screenshots_dir(key))

    def order(loc: str) -> tuple:
        """The primary language first, then the ones with their own
        screenshots. Alphabetical opened the page on en-GB, which has text
        but no screenshots of its own — the store falls back to en-US — so
        the iPhone section looked empty at first glance."""
        has = (shots_dir / loc).is_dir() and any((shots_dir / loc).glob('*.png'))
        return (loc != 'en-US', not has, loc)

    # The iPad set is rendered into the core's tree, not the shell's: it is
    # uploaded straight from there by the release script's ipad step, so it
    # would otherwise be the one part of a submission this page never showed.
    ipad_dir = REPO / 'tactics_board' / 'fastlane' / 'screenshots_ipad' / key

    locales = sorted((d.name for d in md.iterdir() if d.is_dir()), key=order)
    ios = {}
    for loc in locales:
        ios[loc] = {
            'fields': {f: read(md / loc / f'{f}.txt') for f in LIMITS},
            # Drawn 440pt tall, which on a 1290x2796 shot is 203pt across.
            'shots': [thumb(p, 205) for p in sorted((shots_dir / loc).glob('*.png'))]
            if (shots_dir / loc).is_dir() else [],
            # 2064x2752 is 4:3, so the same drawn height is wider across.
            'ipad': [thumb(p, 260) for p in sorted((ipad_dir / loc).glob('*.png'))]
            if (ipad_dir / loc).is_dir() else [],
        }

    # ── Play metadata ─────────────────────────────────────────────────────
    play_root = pathlib.Path(play_metadata_dir(key))
    play = {}
    if play_root.is_dir():
        for d in sorted(p for p in play_root.iterdir() if p.is_dir()):
            # Sorted by versionCode, with fastlane's `default.txt` — the
            # fallback used for any code without its own file — last. It has
            # no number, and int() on it used to abort the whole page.
            logs = sorted(
                (d / 'changelogs').glob('*.txt'),
                key=lambda p: (1, 0) if not p.stem.isdigit() else (0, int(p.stem)),
            ) if (d / 'changelogs').is_dir() else []
            play[d.name] = {
                'title': read(d / 'title.txt'),
                'short': read(d / 'short_description.txt'),
                'full': read(d / 'full_description.txt'),
                'changelog': read(logs[-1]) if logs else '',
                'code': logs[-1].stem if logs else '—',
            }

    # ── macOS ─────────────────────────────────────────────────────────────
    mac_dir = app_dir / 'fastlane' / 'screenshots_mac'
    # Drawn the full width of the column, so encoded for it.
    mac_shots = [(p.stem, thumb(p, 1148, quality=80))
                 for p in sorted(mac_dir.glob('*.png'))]
    # Root build/ first. The one under the app's own build/ is wiped by
    # every flutter clean — tools/drive_app.sh runs one on its way out, and
    # recording the preview film that way deleted the pkg seven times over.
    pkg = REPO / 'build' / 'pkg_mac' / f"{app['bundle'].rsplit('.', 1)[-1]}.pkg"
    if not pkg.exists():
        pkg = app_dir / 'build' / 'macos' / 'appstore' / f"{app.get('name_en', 'Runner')}.pkg"
    if not pkg.exists():
        found = list((app_dir / 'build' / 'macos' / 'appstore').glob('*.pkg')) \
            if (app_dir / 'build' / 'macos' / 'appstore').is_dir() else []
        pkg = found[0] if found else None
    pkg_info = {}
    if pkg and pkg.exists():
        summary = pkg.parent / 'DistributionSummary.plist'
        pkg_info = {'path': str(pkg.relative_to(REPO)),
                    'size': f'{pkg.stat().st_size / 1_048_576:.0f} MB'}
        if summary.exists():
            d = plistlib.loads(summary.read_bytes())
            for items in d.values():
                for item in items:
                    pkg_info.update({
                        'version': item.get('versionNumber', ''),
                        'build': item.get('buildNumber', ''),
                        'arch': ', '.join(item.get('architectures', [])),
                        'cert': (item.get('certificate') or {}).get('type', ''),
                        'profile': (item.get('profile') or {}).get('name', ''),
                    })
        sig = subprocess.run(['pkgutil', '--check-signature', str(pkg)],
                             capture_output=True, text=True).stdout.splitlines()
        pkg_info['signature'] = next((l.strip() for l in sig if 'Status:' in l), '')

    privacy = json.loads(
        (REPO / 'tactics_board/tool/app_privacy/app_privacy_admob.json').read_text())

    # ── the artwork that ships INSIDE the app, and Play's own graphics ────
    def art(rel: str, width: int) -> dict | None:
        f = app_dir / rel
        if not f.exists():
            return None
        im = Image.open(f)
        return {'name': f.name, 'rel': rel, 'size': f'{im.width}×{im.height}',
                'mode': im.mode, 'kb': f'{f.stat().st_size // 1024}K',
                'src': thumb(f, width)}

    icons = [a for a in [
        art('assets/icon/app_icon.png', 150),
        art('assets/icon/splash_logo.png', 110),
        art('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png', 150),
        art('macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png', 150),
        art('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 150),
    ] if a]

    play_dir = play_root / 'en-US' / 'images'
    play_art = [a for a in [
        art(str((play_dir / 'featureGraphic.png').relative_to(app_dir)), 520),
        art(str((play_dir / 'icon.png').relative_to(app_dir)), 120),
    ] if a] if play_dir.is_dir() else []
    play_shots = [thumb(p, 205) for p in
                  sorted((play_dir / 'phoneScreenshots').glob('*.png'))] \
        if (play_dir / 'phoneScreenshots').is_dir() else []

    # ── what a store record needs besides text and pictures ──────────────
    sport = key if key != 'tactics_board' else ''
    iap = [(f'{sport.lower()}_remove_ads_lifetime' if sport else 'remove_ads_lifetime',
            '去广告 · 一次性'),
           (f'{sport.lower()}_remove_ads_yearly' if sport else 'remove_ads_annual',
            '去广告 · 年订阅')]
    links = []
    for line in read(md / 'en-US' / 'description.txt').splitlines():
        if 'http' in line:
            label, _, url = line.partition(': ')
            links.append((label, url.strip()))

    # ── App preview film ─────────────────────────────────────────────────
    # Embedded like every image on this page: the point of the page is that
    # it survives being sent to somebody with the network off.
    # .mp4 first: Chrome will not play a data/blob whose type says
    # quicktime, whatever is actually inside the container.
    preview = REPO / 'build' / 'preview' / f'{key}.mp4'
    if not preview.exists():
        preview = REPO / 'build' / 'preview' / f'{key}.mov'
    video = None
    if preview.exists():
        spec = subprocess.run(
            ['ffprobe', '-v', 'error', '-select_streams', 'v:0',
             '-show_entries', 'stream=width,height,r_frame_rate,codec_name',
             '-show_entries', 'format=duration', '-of', 'default=nw=1:nk=1',
             str(preview)], capture_output=True, text=True).stdout.split()
        # ffprobe prints the entries in ITS order, not the order they were
        # asked for: codec, width, height, rate — then the format's duration.
        try:
            codec, cw, ch, rate, dur = (
                spec[0], spec[1], spec[2], spec[3], float(spec[4]))
        except (IndexError, ValueError):
            cw = ch = rate = codec = '?'
            dur = 0.0
        fps = rate.split('/')[0] if rate.endswith('/1') else rate
        mb = preview.stat().st_size / 1_048_576
        # Apple takes 15–30s. Saying so here beats finding out at upload.
        ok = 15 <= dur <= 30 and mb <= 500
        video = {
            'b64': base64.b64encode(preview.read_bytes()).decode(),
            'spec': f'{cw}×{ch} · {codec.upper()} · {fps}fps · '
                    f'{dur:.1f}s · {mb:.1f} MB',
            'ok': ok,
            'verdict': '符合 App Store 规格（15–30 秒，≤500 MB）' if ok
                       else f'⚠️ App Store 要 15–30 秒，这条 {dur:.1f} 秒',
            'rel': str(preview.relative_to(REPO)),
        }

    # ── build artefacts, and what is missing ─────────────────────────────
    def artefact(label: str, path: pathlib.Path, note: str) -> dict:
        ok = path.exists()
        return {'label': label, 'ok': ok, 'note': note,
                'detail': (f'{path.stat().st_size / 1_048_576:.0f} MB · '
                           f'{path.relative_to(REPO)}') if ok else '未构建'}

    # Where the build scripts actually leave things: build_all_ipa.sh copies
    # the export out to build/ipa_all/<bundle suffix>.ipa at the repo root,
    # and xcodebuild names the one inside the app dir after the Flutter
    # project rather than the app — so looking for "<App>.ipa" there found
    # nothing and the page said 未构建 over a freshly built IPA.
    ipa = REPO / 'build' / 'ipa_all' / f"{app['bundle'].rsplit('.', 1)[-1]}.ipa"
    if not ipa.exists():
        local = app_dir / 'build' / 'ios' / 'ipa'
        found = sorted(local.glob('*.ipa')) if local.is_dir() else []
        if found:
            ipa = found[0]
    # build_all_aab.sh names it by the marketing version alone; the
    # pubspec line here still carries the +build.
    aab = (REPO / 'build' / 'aab_play'
           / f"{key}-{version.split('+')[0]}.aab")
    if not aab.exists():
        aab = (app_dir / 'build' / 'app' / 'outputs' / 'bundle' / 'release'
               / 'app-release.aab')
    builds = [
        artefact('iOS · IPA', ipa, 'tools/build_all_ipa.sh ' + key),
        artefact('Android · AAB', aab,
                 f'BUILD_NUMBER=3 tools/build_all_aab.sh {key}'),
    ]
    if pkg and pkg.exists():
        builds.append({'label': 'macOS · PKG', 'ok': True,
                       'note': 'xcodebuild archive + exportArchive',
                       'detail': f"{pkg_info.get('size')} · {pkg_info.get('path')}"})

    # ── the page ──────────────────────────────────────────────────────────
    ios_tabs = ''.join(
        f'<button class="tab{" on" if i == 0 else ""}" data-loc="{loc}">'
        f'{LOCALE_NAMES.get(loc, loc)}</button>' for i, loc in enumerate(locales))
    ios_panes = ''
    for i, loc in enumerate(locales):
        d = ios[loc]
        shots = ''.join(f'<img loading="lazy" src="{s}" alt="">' for s in d['shots'])
        fields = ''.join(field_block(loc, f, d['fields'][f]) for f in LIMITS)
        ios_panes += (
            f'<div class="pane{" on" if i == 0 else ""}" data-loc="{loc}">'
            f'<div class="shots">{shots or "<p class=none>这个语言没有自己的截图 —— App Store 会用主语言（en-US）的那一套。文案是它自己的。</p>"}</div>'
            f'{fields}</div>')

    n_ipad = sum(len(ios[l]['ipad']) for l in locales)
    ipad_locales = [l for l in locales if ios[l]['ipad']]
    ipad_tabs = ''.join(
        f'<button class="tab{" on" if i == 0 else ""}" data-iloc="{loc}">'
        f'{LOCALE_NAMES.get(loc, loc)}</button>'
        for i, loc in enumerate(ipad_locales))
    ipad_panes = ''
    for i, loc in enumerate(ipad_locales):
        shots = ''.join(
            f'<img loading="lazy" src="{s}" alt="">' for s in ios[loc]['ipad'])
        ipad_panes += (f'<div class="pane{" on" if i == 0 else ""}" '
                       f'data-iloc="{loc}"><div class="shots">{shots}</div></div>')
    if not ipad_locales:
        ipad_panes = ('<p class="none">没有 iPad 截图 —— 支持 iPad 的 app '
                      '必须提交这一档。</p>')

    play_tabs = ''.join(
        f'<button class="tab{" on" if i == 0 else ""}" data-ploc="{loc}">'
        f'{PLAY_NAMES.get(loc, loc)}</button>' for i, loc in enumerate(play))
    play_panes = ''
    for i, (loc, d) in enumerate(play.items()):
        play_panes += (
            f'<div class="pane{" on" if i == 0 else ""}" data-ploc="{loc}">'
            + field_block(loc, 'title', d['title'])
            + field_block(loc, 'short', d['short'])
            + field_block(loc, f'changelog · versionCode {d["code"]}', d['changelog'])
            + field_block(loc, 'full', d['full']) + '</div>')

    def art_card(a: dict) -> str:
        return (f'<figure class="art"><img loading="lazy" src="{a["src"]}" alt="">'
                f'<figcaption><b>{esc(a["name"])}</b><br>{a["size"]} · {a["mode"]} · '
                f'{a["kb"]}<br><span class="mono">{esc(a["rel"])}</span></figcaption></figure>')

    icons_html = ''.join(art_card(a) for a in icons)
    play_art_html = ''.join(art_card(a) for a in play_art)
    play_shots_html = ''.join(f'<img loading="lazy" src="{s}" alt="">'
                              for s in play_shots)
    iap_rows = ''.join(f'<tr><td class="mono">{esc(pid)}</td><td>{esc(label)}</td></tr>'
                       for pid, label in iap)
    link_rows = ''.join(
        f'<tr><th>{esc(label)}</th><td class="mono">'
        f'<a href="{esc(url)}">{esc(url)}</a></td></tr>' for label, url in links)
    build_rows = ''.join(
        f'<tr><th>{esc(b["label"])}</th>'
        f'<td class="{"ok" if b["ok"] else "missing"}">{esc(b["detail"])}</td>'
        f'<td class="mono">{esc(b["note"])}</td></tr>' for b in builds)

    # The film rides in a script tag and is turned into a Blob on load,
    # rather than sitting in the video element's src as a data: URI. A
    # <video> fed a data URI has no byte ranges to seek over and Chrome
    # simply refuses it; a Blob URL behaves like a real file.
    video_html = (
        f'<video id="film" controls preload="metadata" playsinline></video>'
        f'<p class="sub">{esc(video["spec"])} · '
        f'<span class="{"ok" if video["ok"] else "bad"}">{esc(video["verdict"])}'
        f'</span><br><span class="mono">{esc(video["rel"])}</span></p>'
        f'<script id="film-data" type="text/plain">{video["b64"]}</script>'
        if video else
        '<p class="none">还没有录制 —— <span class="mono">'
        'tools/record_preview.sh ' + key + '</span></p>')

    mac = ''.join(
        f'<figure><img loading="lazy" src="{src}" alt=""><figcaption>{esc(n)}</figcaption></figure>'
        for n, src in mac_shots)
    pkg_rows = ''.join(
        f'<tr><th>{esc(k)}</th><td class="mono">{esc(str(v))}</td></tr>'
        for k, v in pkg_info.items())
    priv_rows = ''.join(
        f'<tr><td class="mono">{esc(e["category"])}</td>'
        f'<td>{esc(", ".join(e["purposes"]))}</td>'
        f'<td>{esc(", ".join(e["data_protections"]))}</td></tr>' for e in privacy)

    out = REPO / 'tools' / f'release_review_{key}.html'
    out.write_text(PAGE.format(
        title=f"{app.get('name_en', key)} {version}",
        app=esc(app.get('name_en', key)), bundle=esc(app['bundle']),
        version=esc(version), n_ios=sum(len(v['shots']) for v in ios.values()),
        n_locales=len(locales), n_mac=len(mac_shots),
        n_ipad=n_ipad, ipad_tabs=ipad_tabs, ipad_panes=ipad_panes,
        ios_tabs=ios_tabs, ios_panes=ios_panes,
        play_tabs=play_tabs, play_panes=play_panes,
        mac=mac, pkg_rows=pkg_rows or '<tr><td colspan=2>还没有构建</td></tr>',
        priv_rows=priv_rows, icons=icons_html, play_art=play_art_html,
        play_shots=play_shots_html or '<p class="none">没有 Play 手机截图</p>',
        iap_rows=iap_rows, link_rows=link_rows, build_rows=build_rows,
        video=video_html,
        css=CSS, out=out))
    print(f'wrote {out}  ({out.stat().st_size / 1_048_576:.1f} MB)')


CSS = """
:root{--bg:#0e1112;--panel:#161b1d;--line:#2a3336;--text:#e8eef0;--dim:#9fb0b5;
      --accent:#4dd0e1;--ok:#3ddc97;--bad:#ff6b6b}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);
     font:15px/1.6 -apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif}
.wrap{max-width:1180px;margin:0 auto;padding:28px 16px 90px}
h1{font-size:27px;margin:0 0 4px}
h2{font-size:18px;margin:34px 0 10px;padding-bottom:6px;border-bottom:1px solid var(--line)}
.sub{color:var(--dim);margin:0 0 18px}
.tally{display:flex;gap:10px;flex-wrap:wrap;margin:0 0 8px}
.tally div{background:var(--panel);border:1px solid var(--line);border-radius:10px;
           padding:9px 14px;min-width:120px}
.tally b{display:block;font-size:20px}
.tally span{color:var(--dim);font-size:12.5px}
.tabs{display:flex;gap:6px;flex-wrap:wrap;margin:0 0 12px}
.tab{background:var(--panel);border:1px solid var(--line);color:var(--dim);
     border-radius:99px;padding:5px 12px;font-size:13px;cursor:pointer}
.tab.on{border-color:var(--accent);color:var(--accent)}
.pane{display:none}.pane.on{display:block}
.shots{display:flex;gap:8px;overflow-x:auto;padding-bottom:8px;margin-bottom:14px}
.shots img{height:440px;border-radius:10px;display:block;background:#000}
.field{background:var(--panel);border:1px solid var(--line);border-radius:10px;
       padding:10px 12px;margin:0 0 8px}
.field.over{border-color:var(--bad)}
.fhead{display:flex;align-items:center;gap:10px;margin-bottom:6px}
.fhead b{font-size:13px;color:var(--dim);font-weight:600}
.count{color:var(--dim);font-size:12px;font-variant-numeric:tabular-nums}
.field.over .count{color:var(--bad)}
.copy{margin-left:auto;background:transparent;border:1px solid var(--line);
      color:var(--dim);border-radius:7px;padding:2px 9px;font-size:12px;cursor:pointer}
.copy.done{border-color:var(--ok);color:var(--ok)}
pre{margin:0;white-space:pre-wrap;word-break:break-word;font:13px/1.55 ui-monospace,Menlo,monospace}
figure{margin:0 0 12px}
figure img{width:100%;border-radius:10px;display:block;border:1px solid var(--line)}
figcaption{color:var(--dim);font-size:12.5px;padding-top:5px}
table{border-collapse:collapse;width:100%;font-size:13.5px}
th,td{border:1px solid var(--line);padding:6px 10px;text-align:left;vertical-align:top}
th{color:var(--dim);font-weight:600;white-space:nowrap}
.mono{font-family:ui-monospace,Menlo,monospace;font-size:12.5px}
.warn{background:#2a1a1a;border:1px solid var(--bad);border-radius:10px;
      padding:12px 14px;margin:0 0 18px;color:#ffd9d9}
.note{background:var(--panel);border:1px solid var(--line);border-radius:10px;
      padding:12px 14px;margin:14px 0}
.none{color:var(--dim)}
.arts{display:flex;gap:12px;flex-wrap:wrap;align-items:flex-start;margin-bottom:8px}
.art{background:var(--panel);border:1px solid var(--line);border-radius:10px;
     padding:10px;max-width:280px}
.art img{width:auto;max-width:260px;border:0;border-radius:8px}
.art figcaption{font-size:12px;line-height:1.5}
td.ok{color:var(--ok)}td.missing{color:var(--dim)}
video{width:100%;max-width:300px;border-radius:14px;border:1px solid var(--line);display:block;background:#000}
span.ok{color:var(--ok)}span.bad{color:var(--bad)}
a{color:var(--accent)}
footer{color:var(--dim);font-size:12.5px;margin-top:36px}
"""

PAGE = """<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title} · 发布素材</title><style>{css}</style></head><body><div class="wrap">
<h1>{app} {version}</h1>
<p class="sub">{bundle} · 发布素材总览。图片全部内嵌，断网可读。</p>

<div class="warn"><b>未上传任何内容。</b>App Store / Play 的写操作都需要你再次明确许可。
macOS 另有一层风险：2026-07 Apple 曾以 <b>4.3(a) 垃圾应用</b>拒绝全部 16 个 macOS 版本，
单运动 Mac 版正是该条款点名的形态。</div>

<div class="tally">
  <div><b>{n_ios}</b><span>iPhone 截图</span></div>
  <div><b>{n_mac}</b><span>Mac 截图</span></div>
  <div><b>{n_ipad}</b><span>iPad 截图</span></div>
  <div><b>{n_locales}</b><span>App Store 语言</span></div>
</div>

<h2>iPhone — 截图与文案</h2>
<div class="tabs">{ios_tabs}</div>
{ios_panes}

<h2>iPad — 截图</h2>
<p class="sub">十三英寸档（2064×2752）。支持 iPad 的 app 这一档是必填的，
线上 1.1.25 每个语言只有一张。</p>
<div class="tabs">{ipad_tabs}</div>
{ipad_panes}

<h2>iPhone — 预览视频</h2>
<p class="sub">App Store 的 App Preview。真实操作录屏，不是拼接的动画；
六.九英寸档（1320×2868），与上面的截图同一个尺寸类。</p>
{video}

<h2>应用内的图形</h2>
<p class="sub">打进包里的图标和启动图 —— 商店页看不到，但它们是同一批发布资源。</p>
<div class="arts">{icons}</div>

<h2>Mac — 截图</h2>
<p class="sub">2880×1800，真实窗口，已去 alpha。</p>
{mac}

<h2>Mac — 安装包</h2>
<table>{pkg_rows}</table>

<h2>Google Play — 图形</h2>
<div class="arts">{play_art}</div>
<div class="shots">{play_shots}</div>

<h2>Google Play — 文案</h2>
<div class="tabs">{play_tabs}</div>
{play_panes}

<h2>App Privacy — 数据声明</h2>
<p class="sub">本地文件，尚未推送到 App Store Connect（推送需要 2FA 会话）。</p>
<table><tr><th>类别</th><th>用途</th><th>关联</th></tr>{priv_rows}</table>

<h2>内购商品</h2>
<p class="sub">商店记录里也要填的东西：去广告的两个商品 id。</p>
<table><tr><th>Product ID</th><th>说明</th></tr>{iap_rows}</table>

<h2>法务链接</h2>
<table>{link_rows}</table>

<h2>构建产物</h2>
<table><tr><th>平台</th><th>状态</th><th>怎么构建</th></tr>{build_rows}</table>
<div class="note">Play 的 versionCode 必须 ≥ 3（线上是 2），构建 AAB 时传
<span class="mono">BUILD_NUMBER=3</span>。</div>

<footer>{out} — <span class="mono">python3 tools/release_review.py soccer</span> 重新生成。</footer>
</div>
<script>
function wire(attr, tabSel, paneSel) {{
  document.querySelectorAll(tabSel).forEach(function (b) {{
    b.addEventListener('click', function () {{
      var v = b.getAttribute(attr);
      document.querySelectorAll(tabSel).forEach(function (x) {{ x.classList.remove('on'); }});
      b.classList.add('on');
      document.querySelectorAll(paneSel).forEach(function (p) {{
        p.classList.toggle('on', p.getAttribute(attr) === v);
      }});
    }});
  }});
}}
(function () {{
  var data = document.getElementById('film-data');
  var film = document.getElementById('film');
  if (!data || !film) return;
  var raw = atob(data.textContent.trim());
  var bytes = new Uint8Array(raw.length);
  for (var i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
  film.src = URL.createObjectURL(new Blob([bytes], {{type: 'video/mp4'}}));
}})();
wire('data-loc', '.tab[data-loc]', '.pane[data-loc]');
wire('data-ploc', '.tab[data-ploc]', '.pane[data-ploc]');
wire('data-iloc', '.tab[data-iloc]', '.pane[data-iloc]');
document.querySelectorAll('[data-copy]').forEach(function (b) {{
  b.addEventListener('click', function () {{
    navigator.clipboard.writeText(b.parentNode.parentNode.querySelector('pre').innerText)
      .then(function () {{ b.textContent = '已复制'; b.classList.add('done'); }});
  }});
}});
</script>
</body></html>
"""

if __name__ == '__main__':
    main()
