"""Session templates: a practice plan a coach can take as it is.

The practice-plan page lets a coach build a session drill by drill, and
most never do — the plan list stays empty, and the drill library is read
one card at a time. Competitors sell ready sessions as the thing worth
paying for. These are ours: six templates per sport, each a sequence of
drills from the library with the drill's own minutes, chosen by category
and level so the same recipe gives every sport a sensible session. They
ride in the pack under ``plans`` — a key installed apps ignore, so the
pack's minimum client does not move — and the app that reads them turns
one into a Practice with a tap.

Each template: ``{"id", "name": {locale: text}, "items": [{"drill",
"minutes"}]}``. Names are written here in the fourteen pack locales.
"""
from __future__ import annotations

# (template id, slots) — a slot is (category, preferred levels in order).
# Slots are filled in order from the library's own order, never repeating
# a drill, so the sheet reads warm-up first and game last like a session.
TEMPLATES = [
    ("foundation", [
        ("warmup", ("foundation", "development")),
        ("possession", ("foundation", "development")),
        ("attacking", ("foundation", "development")),
        ("defending", ("foundation", "development")),
        ("ssg", ("foundation", "development")),
    ]),
    ("attacking", [
        ("warmup", ("development", "foundation")),
        ("possession", ("development", "advanced")),
        ("attacking", ("development", "advanced")),
        ("attacking", ("advanced", "development")),
        ("finishing", ("development", "advanced")),
        ("ssg", ("development", "advanced")),
    ]),
    ("defending", [
        ("warmup", ("development", "foundation")),
        ("defending", ("development", "advanced")),
        ("defending", ("advanced", "development")),
        ("possession", ("development", "foundation")),
        ("ssg", ("development", "advanced")),
        ("conditioning", ("development", "foundation")),
    ]),
    ("setpiece", [
        ("warmup", ("development", "foundation")),
        ("setpiece", ("development", "foundation")),
        ("setpiece", ("advanced", "development")),
        ("setpiece", ("development", "advanced")),
        ("ssg", ("development", "advanced")),
    ]),
    ("matchweek", [
        ("warmup", ("development", "foundation")),
        ("possession", ("development", "advanced")),
        ("attacking", ("advanced", "development")),
        ("defending", ("advanced", "development")),
        ("setpiece", ("advanced", "development")),
        ("ssg", ("development", "advanced")),
    ]),
    ("preseason", [
        ("warmup", ("foundation", "development")),
        ("conditioning", ("foundation", "development")),
        ("possession", ("foundation", "development")),
        ("ssg", ("foundation", "development")),
        ("conditioning", ("development", "foundation")),
        ("finishing", ("foundation", "development")),
    ]),
]

NAMES = {
    "foundation": {
        "en": "Foundation session", "en-GB": "Foundation session",
        "zh-CN": "基础课", "zh-TW": "基礎課", "ja-JP": "基礎練習",
        "ko-KR": "기초 훈련", "es-ES": "Sesión de base",
        "fr-FR": "Séance de base", "id-ID": "Sesi dasar", "ms-MY": "Sesi asas",
        "th-TH": "คาบฝึกพื้นฐาน", "vi-VN": "Buổi tập cơ bản",
        "de-DE": "Grundlageneinheit", "nl-NL": "Basistraining",
    },
    "attacking": {
        "en": "Attacking session", "en-GB": "Attacking session",
        "zh-CN": "进攻课", "zh-TW": "進攻課", "ja-JP": "攻撃練習",
        "ko-KR": "공격 훈련", "es-ES": "Sesión de ataque",
        "fr-FR": "Séance d'attaque", "id-ID": "Sesi menyerang",
        "ms-MY": "Sesi serangan", "th-TH": "คาบฝึกเกมรุก",
        "vi-VN": "Buổi tập tấn công", "de-DE": "Angriffseinheit",
        "nl-NL": "Aanvalstraining",
    },
    "defending": {
        "en": "Defending session", "en-GB": "Defending session",
        "zh-CN": "防守课", "zh-TW": "防守課", "ja-JP": "守備練習",
        "ko-KR": "수비 훈련", "es-ES": "Sesión defensiva",
        "fr-FR": "Séance défensive", "id-ID": "Sesi bertahan",
        "ms-MY": "Sesi pertahanan", "th-TH": "คาบฝึกเกมรับ",
        "vi-VN": "Buổi tập phòng ngự", "de-DE": "Abwehreinheit",
        "nl-NL": "Verdedigingstraining",
    },
    "setpiece": {
        "en": "Set-piece session", "en-GB": "Set-piece session",
        "zh-CN": "定位球课", "zh-TW": "定位球課", "ja-JP": "セットプレー練習",
        "ko-KR": "세트피스 훈련", "es-ES": "Sesión de jugadas a balón parado",
        "fr-FR": "Séance coups de pied arrêtés", "id-ID": "Sesi bola mati",
        "ms-MY": "Sesi bola mati", "th-TH": "คาบฝึกลูกตั้งเตะ",
        "vi-VN": "Buổi tập tình huống cố định", "de-DE": "Standardsituationen",
        "nl-NL": "Standaardsituaties",
    },
    "matchweek": {
        "en": "Match week", "en-GB": "Match week",
        "zh-CN": "赛前一周", "zh-TW": "賽前一週", "ja-JP": "試合週",
        "ko-KR": "경기 주간", "es-ES": "Semana de partido",
        "fr-FR": "Semaine de match", "id-ID": "Pekan pertandingan",
        "ms-MY": "Minggu perlawanan", "th-TH": "สัปดาห์แข่งขัน",
        "vi-VN": "Tuần thi đấu", "de-DE": "Spielwoche", "nl-NL": "Wedstrijdweek",
    },
    "preseason": {
        "en": "Pre-season", "en-GB": "Pre-season",
        "zh-CN": "赛季前", "zh-TW": "季前", "ja-JP": "プレシーズン",
        "ko-KR": "프리시즌", "es-ES": "Pretemporada", "fr-FR": "Présaison",
        "id-ID": "Pramusim", "ms-MY": "Pramusim", "th-TH": "ช่วงก่อนเปิดฤดูกาล",
        "vi-VN": "Tiền mùa giải", "de-DE": "Saisonvorbereitung",
        "nl-NL": "Voorbereiding",
    },
}

# Sports without set pieces or conditioning as a category lose that slot
# rather than the template: a four-drill session is still a session.
MIN_ITEMS = 4


def build_plans(records: list[dict]) -> list[dict]:
    """The templates for one sport, from its finished drill records."""
    plans = []
    for tid, slots in TEMPLATES:
        used: set[str] = set()
        items = []
        for category, levels in slots:
            pick = None
            for level in levels:
                pick = next((r for r in records
                             if r["category"] == category and r["level"] == level
                             and r["id"] not in used), None)
                if pick:
                    break
            if pick is None:
                pick = next((r for r in records
                             if r["category"] == category and r["id"] not in used), None)
            if pick is None:
                continue
            used.add(pick["id"])
            items.append({"drill": pick["id"], "minutes": pick["minutes"]})
        if len(items) >= MIN_ITEMS:
            plans.append({"id": tid, "name": dict(NAMES[tid]), "items": items})
    return plans
