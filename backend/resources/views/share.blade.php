<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{{ $play->title ?: 'A play' }} — Tactics Board</title>
<meta name="description" content="A play shared from Tactics Board.">

{{-- Most of these links are opened from a chat app, so the preview card is
     the first thing the receiver sees — it has to look like the play. --}}
<meta property="og:title" content="{{ $play->title ?: 'A play' }}">
<meta property="og:description" content="Shared from Tactics Board">
<meta property="og:type" content="{{ $play->media_kind === 'mp4' ? 'video.other' : 'article' }}">
@if ($play->mediaUrl())
  <meta property="og:image" content="{{ $play->media_kind === 'png' ? $play->mediaUrl() : '' }}">
  @if ($play->media_kind === 'mp4')
    <meta property="og:video" content="{{ $play->mediaUrl() }}">
    <meta property="og:video:type" content="video/mp4">
  @endif
@endif
<meta name="twitter:card" content="summary_large_image">

<style>
  :root {
    --ground: #0f1c22;
    --panel: #16272f;
    --line: #243a44;
    --ink: #e8f0ee;
    --ink-2: #9db2b0;
    --accent: #00c2b2;
  }
  * { box-sizing: border-box; }
  html, body { margin: 0; height: 100%; }
  body {
    background: var(--ground); color: var(--ink);
    font: 16px/1.55 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    display: flex; flex-direction: column; align-items: center;
    padding: max(16px, env(safe-area-inset-top)) 16px 28px;
  }
  header { width: 100%; max-width: 520px; display: flex; align-items: center; gap: 10px; margin-bottom: 14px; }
  header .mark {
    width: 26px; height: 26px; border-radius: 7px; background: var(--accent);
    display: grid; place-items: center; color: #06211f; font-weight: 800; font-size: 14px;
  }
  header b { font-size: 14px; font-weight: 600; letter-spacing: .01em; }
  header span { color: var(--ink-2); font-size: 13px; margin-left: auto; text-transform: capitalize; }

  main { width: 100%; max-width: 520px; display: flex; flex-direction: column; gap: 14px; }
  h1 { font-size: 20px; margin: 0; line-height: 1.25; }
  .stage {
    background: #000; border: 1px solid var(--line); border-radius: 14px;
    overflow: hidden; display: grid; place-items: center; min-height: 220px;
  }
  .stage video, .stage img { width: 100%; height: auto; display: block; }
  .empty { color: var(--ink-2); font-size: 14px; padding: 48px 20px; text-align: center; }

  .meta { color: var(--ink-2); font-size: 13px; display: flex; gap: 14px; flex-wrap: wrap; }

  .cta {
    display: flex; gap: 10px; flex-wrap: wrap; margin-top: 4px;
  }
  .cta a {
    flex: 1 1 180px; text-align: center; text-decoration: none;
    padding: 12px 16px; border-radius: 10px; font-weight: 600; font-size: 15px;
  }
  .cta .primary { background: var(--accent); color: #06211f; }
  .cta .ghost { border: 1px solid var(--line); color: var(--ink); background: var(--panel); }

  footer { color: var(--ink-2); font-size: 12px; margin-top: 22px; text-align: center; }
  footer a { color: var(--ink-2); }
</style>
</head>
<body>

<header>
  <span class="mark">T</span>
  <b>Tactics Board</b>
  <span>{{ str_replace('_', ' ', $play->sport_type) }}</span>
</header>

<main>
  @if ($play->title)
    <h1>{{ $play->title }}</h1>
  @endif

  <div class="stage">
    @if ($play->media_kind === 'mp4' && $play->mediaUrl())
      {{-- autoplay muted+inline is the only combination iOS Safari will start
           without a tap; loop because a play is a few seconds long. --}}
      <video src="{{ $play->mediaUrl() }}" autoplay muted loop playsinline controls></video>
    @elseif ($play->mediaUrl())
      <img src="{{ $play->mediaUrl() }}" alt="{{ $play->title ?: 'Shared play' }}">
    @else
      <p class="empty">This play was shared without a preview.</p>
    @endif
  </div>

  <div class="meta">
    <span>Shared {{ $play->created_at->diffForHumans() }}</span>
    @if ($play->expires_at)
      <span>Link expires {{ $play->expires_at->diffForHumans() }}</span>
    @endif
  </div>

  <div class="cta">
    <a class="primary" href="https://apps.apple.com/app/id6478977637">Get Tactics Board</a>
    <a class="ghost" href="/">What is this?</a>
  </div>
</main>

<footer>
  Shared from Tactics Board · <a href="/privacy">Privacy</a>
</footer>

</body>
</html>
