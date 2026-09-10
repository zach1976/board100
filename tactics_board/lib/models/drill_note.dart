/// A drill's note, split back into the sections the generator wrote.
///
/// `tools/drills/narrate.py` composes the note as one labelled section per
/// line — 【目的】…, 【组织】…, "Purpose: …", "Setup: …" — because a coach
/// reading a card wants the whole thing as a paragraph. A detail page wants
/// the opposite: each section as its own block, and the sequence as numbered
/// beats it can hold against the stepper.
///
/// Parsed here rather than shipped as structured JSON: the labels are already
/// in the text, in the coach's own language, so splitting them off costs
/// nothing while a `sections` map would double the size of every drill file
/// and put a twelve-locale label table on both sides of the wire.
class DrillNote {
  final List<DrillSection> sections;
  const DrillNote(this.sections);

  static const _empty = DrillNote(<DrillSection>[]);

  bool get isEmpty => sections.isEmpty;

  /// The section a paragraph-style note has when there are no labels at all:
  /// an older drill, or a sport whose family predates the composed note.
  static DrillNote parse(String note) {
    final text = note.trim();
    if (text.isEmpty) return _empty;
    final rows = <(String?, String)>[];
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      rows.add(_splitLabel(line));
    }
    final out = <DrillSection>[];
    for (var i = 0; i < rows.length; i++) {
      final (label, body) = rows[i];
      final probe = DrillSection(label, body);
      final DrillSectionKind kind;
      if (i == 0) {
        kind = DrillSectionKind.lead;
      } else if (probe.beats.isNotEmpty) {
        kind = DrillSectionKind.sequence;
      } else if (body.contains(' → ')) {
        kind = DrillSectionKind.route;
      } else if (i == rows.length - 1) {
        kind = DrillSectionKind.point;
      } else {
        kind = DrillSectionKind.info;
      }
      out.add(DrillSection(label, body, kind: kind));
    }
    return DrillNote(out);
  }

  /// (label, body). CJK locales bracket the label — 【组织】人数… — and every
  /// other locale ends it with a colon. Both are only ever at the very start
  /// of a line, so the FIRST match is the label and anything later (a colon
  /// inside the body) is left alone.
  static (String?, String) _splitLabel(String line) {
    if (line.startsWith('【')) {
      final close = line.indexOf('】');
      if (close > 0) {
        return (line.substring(1, close), line.substring(close + 1).trim());
      }
    }
    // "Setup: ", "Mise en place : ", "การจัด: " — a label is short, so a
    // colon far into the line belongs to the body, not to a label.
    final colon = line.indexOf(RegExp(r'\s*[:：]\s'));
    if (colon > 0 && colon <= 28) {
      final after = line.indexOf(RegExp(r'[:：]'), colon);
      return (line.substring(0, colon).trim(), line.substring(after + 1).trim());
    }
    return (null, line);
  }
}

/// What a section is FOR, so the page can lay each one out as its own thing
/// instead of seven identical grey paragraphs.
///
/// Worked out from position and shape rather than from the label text: the
/// labels are localised into twelve languages, and matching them would put
/// that table on this side of the wire as well.
enum DrillSectionKind {
  /// Why run this at all. Always first, and the one line a coach reads if
  /// they read nothing else.
  lead,

  /// Where the ball goes — "1 → 2 → 3 → 球门". A chain, not a sentence.
  route,

  /// Beat by beat, matching the board's own steps.
  sequence,

  /// The one thing to say out loud. Always last.
  point,

  /// Frequency, origin, setup: the standing facts.
  info,
}

class DrillSection {
  /// Null on a note with no labels — then [body] is the whole paragraph.
  final String? label;
  final String body;
  final DrillSectionKind kind;
  const DrillSection(this.label, this.body,
      {this.kind = DrillSectionKind.info});

  /// The stops of a ball path, in order — "1", "2", "球门".
  List<String> get stops =>
      body.split(' → ').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

  /// The beats of a sequence section, in order, with their own numbering
  /// stripped — "第1步：1号球员把球传给2号球员" becomes the sentence alone, so
  /// the page can number them itself and they line up with the stepper.
  ///
  /// Returns an empty list when the body is not a sequence: a single
  /// unnumbered sentence is a paragraph and stays one.
  List<String> get beats {
    final parts = body
        .split(RegExp(r'[;；]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length < 2) return const [];
    final beats = <String>[];
    for (final part in parts) {
      // "第1步：", "Step 1: ", "ขั้นที่ 1: " — the number is the page's job
      // now. Anything that does not open with one is not a beat, so the
      // whole body stays a paragraph rather than being cut at a semicolon
      // that happened to be punctuation.
      final m = RegExp(r'^[^0-9]{0,12}\d+[^0-9:：]{0,6}[:：]\s*').firstMatch(part);
      if (m == null) return const [];
      final rest = part.substring(m.end).trim();
      beats.add(rest.isEmpty ? part : rest);
    }
    return beats;
  }
}
