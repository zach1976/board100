#!/usr/bin/env python3
"""Build tools/player_turn_left_prompts.html — the three missing headings.

The eight-cell turnaround sheets were generated as FIVE views and the other
three were made by flipping three of them. For the plain figure that is
sound, and the original prompt says so in as many words. For a figure
holding something it is not: a flip swaps the hands, so the three headings
that come from it draw a right-hander as a left-hander.
"""
import base64, io, pathlib
from PIL import Image, ImageDraw

REPO = pathlib.Path(__file__).resolve().parent.parent
ICON = REPO / 'tactics_board' / 'assets' / 'icon'
OUT = REPO / 'tools' / 'player_turn_left_prompts.html'

SHEETS = [
    ('male', 'racket', 'badminton / tennis racket'),
    ('female', 'racket', 'badminton / tennis racket'),
    ('male', 'paddle', 'table-tennis paddle'),
    ('female', 'paddle', 'table-tennis paddle'),
    ('male', 'bat', 'baseball bat'),
    ('female', 'bat', 'baseball bat'),
    ('male', 'stick', 'field-hockey stick'),
    ('female', 'stick', 'field-hockey stick'),
]

HAIR = {
    'male': 'short dark hair',
    'female': 'dark hair gathered into a ponytail at the back of the head',
}

HOLD = {
    'racket': ("a racket held in its RIGHT hand, hanging straight down at its "
               "right side with the oval head level with the knee — pale "
               "strings, a dark slim frame and a short grip"),
    'paddle': ("a table-tennis paddle held in its RIGHT hand, hanging at its "
               "right side — a small dark rounded blade about the size of the "
               "figure's own hand, on a short pale handle"),
    'bat': ("a baseball bat held in BOTH hands in a right-handed batting "
            "stance: the hands together on the grip beside the RIGHT "
            "shoulder, the pale wooden barrel angled up and back over that "
            "same shoulder"),
    'stick': ("a field-hockey stick held in BOTH hands, the left hand at the "
              "top of the handle and the right hand below it, the hooked head "
              "resting on the ground a little in front of and to the RIGHT of "
              "the figure's feet"),
}

KIT = {
    'male': 'the SHIRT and the SHORTS',
    'female': 'the SHIRT and the SHORTS or skirt',
}


def prompt(gender, impl, _label):
    name = f'player_top_{gender}_{impl}_turn_left.png'
    return f"""{name}
1536x512
A character turnaround of a single {'sportsman' if gender == 'male' else 'sportswoman'} with {HAIR[gender]}, a plain short-sleeved shirt, shorts, socks and shoes, holding {HOLD[impl]}. THIS IS A CHARACTER TURNAROUND SHEET: ONE image, 1536 wide by 512 tall, containing the SAME figure THREE times in a single horizontal row, evenly spaced, equal size, not touching and not overlapping, each in its own 512 by 512 cell. Same camera, same lighting, same scale, same pose for all three - a moulded figurine turned on a turntable and photographed at three stops, 45 degrees apart. From left to right the figure faces: (1) three-quarters toward the camera and toward the viewer's LEFT, most of the face visible; (2) directly to the viewer's LEFT, a clean side profile, no part of the far eye visible; (3) three-quarters away from the camera and toward the viewer's LEFT, most of its back showing and no part of the face visible. The turn must be even: each figure is the previous one turned a further 45 degrees away from the camera. THE HAND NEVER CHANGES. In all three the {impl} is in the figure's own RIGHT hand - the hand on the side of its body that is AWAY from the camera in view (1) and NEAREST the camera in view (3). This sheet exists because the three headings it replaces were made by flipping three other headings, which put the {impl} in the left hand; do not mirror anything, pose the figure. The camera is fixed for all three: above the figure and a little in front of it, looking down at about 55 degrees, so the crown of the head and the shoulders read from above and the feet are visible below - exactly the camera of the front-facing and side-facing figures already made for this app. The figure is 3D rendered as a moulded plastic tactics-board figurine, in exactly the same style, chunky toy proportions and colour rules as the figures already made for this app: the head is large for the body, about a quarter of the figure's height; the shoulders are broad; the arms and legs are short and thick, simple rounded masses with no anatomical muscle definition at all. Standing upright, feet a little apart. Surfaces are smooth and matte and completely untextured: no fabric weave, no individual hair strands, no laces, no stitching, no seams, no folds. Lit softly from the upper left by one neutral white light, the same for all three. Fully transparent background (alpha) across the whole sheet, not white and not a colour. No ground, no pitch, no scene, no cell borders or dividing lines, and NO CONTACT SHADOW of any kind beneath any figure - the app draws its own. COLOUR, identical on all three. The figure is NOT one colour. Every part is coloured as that part really is, EXCEPT the kit, which is painted in a key colour the app replaces at runtime: {KIT[gender]} - and nothing else in the image - are pure vivid magenta, fuchsia, RGB 255 0 255, shaded properly with their own soft highlights and shadows but with every shaded pixel unmistakably magenta, no pink drifting to red, no purple drifting to blue, and no other surface anywhere in the picture carrying even a trace of magenta; the SKIN of the face, neck, arms and legs is natural skin; the HAIR is dark brown; the SOCKS and SHOES are white; and the {impl} keeps its own real colours. Head width must be the same in all three cells."""


def strip(gender, impl):
    """Eight cells in heading order, the three to be replaced marked."""
    sheet = Image.open(ICON / f'player_top_{gender}_{impl}_turn_base.png').convert('RGBA')
    c, cols, s = 512, 4, 112
    out = Image.new('RGB', (8 * (s + 6) + 6, s + 34), (0x16, 0x1b, 0x1d))
    d = ImageDraw.Draw(out)
    for i in range(8):
        cell = sheet.crop(((i % cols) * c, (i // cols) * c,
                           (i % cols + 1) * c, (i // cols + 1) * c)).resize((s, s))
        x = 6 + i * (s + 6)
        bad = i in (5, 6, 7)
        d.rectangle([x - 3, 24, x + s + 2, 26 + s + 2],
                    fill=(0x3a, 0x1d, 0x22) if bad else (0x1d, 0x2a, 0x24))
        out.paste(cell, (x, 26), cell)
        d.text((x + 2, 8), f'{i * 45}°', fill=(0xff, 0x8b, 0x8b) if bad else (0x8f, 0xb0, 0xa0))
    buf = io.BytesIO()
    out.save(buf, 'PNG')
    return base64.b64encode(buf.getvalue()).decode()


def esc(t):
    return (t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'))


cards = []
for gender, impl, label in SHEETS:
    cards.append(f"""
<h2>{gender}_{impl} <span class="dim">· {label}</span></h2>
<p class="sub">现有八向图。红框那三格是翻转出来的，持拍手是反的，要用新图换掉。</p>
<img class="sheet" src="data:image/png;base64,{strip(gender, impl)}" alt="">
<div class="p"><button class="copy">复制整段</button><pre>{esc(prompt(gender, impl, label))}</pre></div>
""")

HTML = f"""<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>八向图 · 补画左半边的三个朝向</title>
<style>
  :root{{color-scheme:dark;--bg:#0e1112;--panel:#161b1d;--line:#2a3336;--text:#e8eef0;
    --dim:#9fb0b5;--accent:#4dd0e1;--ok:#3ddc97;--bad:#ff6b6b;
    --body:"PingFang SC","Hiragino Sans GB",sans-serif;--mono:"SF Mono",Menlo,Consolas,monospace}}
  *{{box-sizing:border-box}}
  body{{background:var(--bg);color:var(--text);font-family:var(--body);font-size:15px;
    line-height:1.7;margin:0;-webkit-font-smoothing:antialiased}}
  .wrap{{max-width:1080px;margin:0 auto;padding:0 20px 90px}}
  header.top{{padding:44px 0 22px;border-bottom:1px solid var(--line)}}
  .eyebrow{{font-family:var(--mono);font-size:11px;letter-spacing:.2em;text-transform:uppercase;
    color:var(--accent);margin:0 0 10px}}
  h1{{font-weight:800;font-size:clamp(24px,5vw,34px);line-height:1.15;margin:0 0 10px}}
  .lede{{color:var(--dim);margin:0;max-width:70ch}}
  h2{{font-weight:800;font-size:19px;margin:40px 0 4px;font-family:var(--mono)}}
  .dim{{color:var(--dim);font-weight:400;font-size:14px;font-family:var(--body)}}
  .sub{{color:var(--dim);margin:0 0 12px;max-width:74ch;font-size:14px}}
  .why{{background:var(--panel);border:1px solid var(--line);border-left:3px solid var(--accent);
    border-radius:0 12px 12px 0;padding:14px 18px;margin:18px 0;font-size:14.5px}}
  .why.bad{{border-left-color:var(--bad)}}
  table{{width:100%;border-collapse:collapse;margin:14px 0;font-size:13.5px}}
  th,td{{text-align:left;padding:7px 10px;border-bottom:1px solid var(--line)}}
  th{{color:var(--dim);font-weight:600;font-size:12px;text-transform:uppercase;letter-spacing:.05em}}
  td.n{{color:var(--bad);font-family:var(--mono)}}
  td.y{{color:var(--ok);font-family:var(--mono)}}
  img.sheet{{max-width:100%;border:1px solid var(--line);border-radius:10px;display:block}}
  code{{font-family:var(--mono);font-size:12.5px;color:#cfe3e8}}
  .p{{position:relative;background:#0b1416;border:1px solid var(--line);border-radius:12px;
    padding:50px 18px 18px;margin-top:12px}}
  .p pre{{margin:0;white-space:pre-wrap;word-break:break-word;
    font-family:var(--mono);font-size:12.4px;line-height:1.62;color:#dfe9ec}}
  .copy{{position:absolute;top:11px;right:11px;background:#17272b;border:1px solid var(--line);
    color:var(--dim);border-radius:8px;padding:7px 13px;font:600 12px/1 var(--mono);cursor:pointer}}
  .copy:hover{{color:var(--text);border-color:#35494f}}
  .copy.done{{background:var(--ok);border-color:var(--ok);color:#06231a}}
  footer{{color:#5b6d72;font-size:12.5px;margin-top:48px;padding-top:18px;border-top:1px solid var(--line)}}
</style></head>
<body><div class="wrap">

<header class="top">
  <p class="eyebrow">tactics board · player turnaround · 2026-10-06</p>
  <h1>补画左半边的三个朝向</h1>
  <p class="lede">八向转身图里，225°、270°、315° 这三格不是画出来的，是另外三格<b>左右翻转</b>出来的。
  翻转让身体朝向对了，却把持拍的手换到了另一只 —— 一名右手持拍的球员，只要朝向落在这三档，
  画出来就是左手。下面八段提示词各生成一张 1536×512 的三连图，把这三格换掉。</p>
</header>

<div class="why bad">
  <b>证据是逐像素量出来的。</b>把第 7 格水平翻转后与第 1 格相减，平均绝对差 <code>0.0</code>；
  第 6 格对第 2 格、第 5 格对第 3 格同样。只有第 0 格（背面）和第 4 格（正面）是各自画的 ——
  它们之间的差是 <code>8.5–18.0</code>。八张带持拍器的图版，无一例外。
</div>

<div class="why">
  <b>这不是当初的疏忽，是条件变了。</b>最早那版提示词自己写着
  「左边三个朝向用镜像（<b>基础小人没有手持物，镜像成立</b>）」。
  素人图确实成立。后来加了球拍、球板、球棒、曲棍球杆，沿用了同一条流水线，
  前提就不再成立了。所以要补的只有这八张带持拍器的图版，素人图和水球图不用动。
</div>

<h2 style="margin-top:34px">要换的是哪三格</h2>
<table>
  <tr><th>格子</th><th>朝向</th><th>现在是怎么来的</th><th>画面</th></tr>
  <tr><td>0</td><td>0°</td><td class="y">画的</td><td>完全背对镜头</td></tr>
  <tr><td>1</td><td>45°</td><td class="y">画的</td><td>背对、偏向画面右</td></tr>
  <tr><td>2</td><td>90°</td><td class="y">画的</td><td>正侧面，朝画面右</td></tr>
  <tr><td>3</td><td>135°</td><td class="y">画的</td><td>正面、偏向画面右</td></tr>
  <tr><td>4</td><td>180°</td><td class="y">画的</td><td>完全面对镜头</td></tr>
  <tr><td>5</td><td>225°</td><td class="n">翻 3 格</td><td>正面、偏向画面左</td></tr>
  <tr><td>6</td><td>270°</td><td class="n">翻 2 格</td><td>正侧面，朝画面左</td></tr>
  <tr><td>7</td><td>315°</td><td class="n">翻 1 格</td><td>背对、偏向画面左</td></tr>
</table>

<div class="why">
  <b>图回来之后我做什么。</b>每张三连图按 512 切成三格，按洋红键分成
  <code>turn_base</code>（整个人，球衣转中性灰）和 <code>turn_kit</code>（只有球衣，给队色上色用）两层，
  再贴回 2048×1024 的 8 格图版的第 5、6、7 格 —— 两层必须逐像素对齐，所以两层都从同一张渲染里拆。
  所以提示词里<b>球衣和短裤必须是纯洋红 RGB 255 0 255</b>，其余一切按真实颜色，这一条不能省。
</div>
{''.join(cards)}

<footer>
  /Users/zhenyusong/projects/board100/tools/player_turn_left_prompts.html<br>
  参照图：tactics_board/assets/icon/player_top_&lt;gender&gt;_&lt;implement&gt;_turn_base.png · 原始提示词见 tools/player_turn_prompts.html
</footer>

</div>
<script>
document.querySelectorAll('.copy').forEach(function (b) {{
  b.addEventListener('click', function () {{
    var text = b.parentNode.querySelector('pre').innerText;
    navigator.clipboard.writeText(text).then(function () {{
      b.textContent = '已复制';
      b.classList.add('done');
    }});
  }});
}});
</script>
</body></html>
"""

OUT.write_text(HTML, encoding='utf-8')
print(f'wrote {OUT}  ({len(HTML)/1024:.0f} KB)')
