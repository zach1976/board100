import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sport_type.dart';
import '../models/tactic_meta.dart';
import '../services/auth_service.dart';
import '../services/drill_library_service.dart';
import '../services/drill_notes_service.dart';
import '../services/practice_service.dart';
import '../state/tactics_state.dart';
import '../ui/adaptive.dart';
import '../ui/tokens.dart';
import '../widgets/language_picker.dart';
import 'drill_library_page.dart';
import 'home_page.dart';
import 'intro_page.dart';
import 'practice_plan_page.dart';
import 'sport_home_page.dart';

/// The four places the app is, with a bar to move between them.
///
/// Everything used to be reached by pushing: the home page pushed the board,
/// the library, the plan, and a coach three pages deep had to walk back out
/// the way they came. A bar says what the app contains before anything is
/// tapped, which is the one thing a stack of routes can never do.
///
/// The board is the exception and stays a pushed route. It is a full-screen
/// editor with its own chrome — a back button, plan mode, the external
/// display — all of it built around being something you enter and leave, and
/// hosting it in a tab would leave a back button on screen with nothing
/// behind it. Tapping 战术板 opens it; closing it drops you back on the tab
/// you came from.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  /// Bumped whenever the home tab comes back into view, so its lists — the
  /// recent drills, the coach's own boards — are re-read. See
  /// SportHomePage.revision.
  int _homeRevision = 0;

  /// Whether the intro still has to be shown, or null while we are asking.
  ///
  /// The gate belongs here rather than inside the home page. SportHomePage is
  /// in two places: pushed on its own by the sport picker, where returning the
  /// intro from its build replaces the whole screen, and as this shell's first
  /// tab, where the same return only replaces the *body* — leaving the tab bar
  /// sitting under an onboarding page that has nothing to switch between.
  /// Above the Scaffold there is nothing to leave behind.
  bool? _intro;

  /// How many drills this sport has, for the intro's second panel.
  ///
  /// Without it that panel falls back to its countless wording. The home page
  /// passes the number when it shows the intro itself, and a coach who lands
  /// here instead should read the same sentence.
  int? _drillCount;

  @override
  void initState() {
    super.initState();
    IntroPage.shouldShow().then((show) {
      if (mounted) setState(() => _intro = show);
    });
    DrillLibraryService.instance
        .forSport(context.read<TacticsState>().sportType)
        .then((all) {
      if (mounted) setState(() => _drillCount = all.length);
    }).catchError((Object _) {
      // No library is not a reason to hold the intro back; the panel
      // just keeps its countless wording.
    });
  }

  /// 战术板 in the tab bar. On a first run there is no board behind it, and
  /// dropping a coach on an unnamed empty pitch is the one thing
  /// createNamedBoard exists to prevent — so the tab makes one, exactly as
  /// the home card's 新建空白板 does.
  Future<void> _boardTab() async {
    if (hasWorkingBoard(context.read<TacticsState>())) {
      await _openBoard();
      return;
    }
    if (await createNamedBoard(context) && mounted) await _openBoard();
  }

  Future<void> _openBoard() async {
    final state = context.read<TacticsState>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TacticsBoardHomePage()),
    );
    await state.autosave();
    // Whatever happened on the board — a drill loaded, a board saved — is
    // news to the home tab's lists.
    if (mounted) setState(() => _homeRevision++);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TacticsState>();
    // Hold the empty background rather than flashing the tabs for one frame
    // while the preference is read.
    if (_intro == null) {
      return Scaffold(backgroundColor: T.bg0, body: const SizedBox.shrink());
    }
    if (_intro == true) {
      return IntroPage(
        sportType: state.sportType,
        drillCount: _drillCount,
        onDone: () => setState(() => _intro = false),
      );
    }
    final tabs = IndexedStack(
        index: _tab,
        children: [
          // The intro is gated here, above the Scaffold; the page must not
          // gate it again inside the tab. See SportHomePage.gateIntro.
          SportHomePage(gateIntro: false, revision: _homeRevision),
          // Built once, kept alive: the library holds a search box, a scroll
          // position and a set of filters, and a coach who taps away to check
          // a board expects to come back to the list they had, not to the top
          // of an unfiltered one.
          DrillLibraryPage(state: state, onLoaded: _openBoard),
          _MinePage(onOpenBoard: _openBoard),
        ],
      );
    void onTab(int i) {
      // The board is an action, not a destination — see the note above.
      if (i == 1) {
        _boardTab();
        return;
      }
      setState(() {
        _tab = i > 1 ? i - 1 : i;
        if (_tab == 0) _homeRevision++;
      });
    }

    // An iPad keeps its sections in a rail down the side, the way iPadOS
    // apps do: a phone's bottom bar spread four items over 1376pt, 344pt
    // apart, with 22pt icons and labels too small for the distance.
    if (isTabletLayout(context)) {
      return Scaffold(
        backgroundColor: T.bg0,
        body: Row(
          children: [
            _SideRail(current: _tab, onTap: onTab),
            Expanded(child: tabs),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: T.bg0,
      body: tabs,
      bottomNavigationBar: _TabBar(
        current: _tab,
        onTap: onTab,
      ),
    );
  }
}

/// The coach's face, or the next best thing. Public for its own test.
///
/// Three states, in the order they are worth having: the picture the
/// provider gave (Google), the coach's own initials (Apple, which sends no
/// picture, and any account whose photo will not load), and the generic
/// person for someone who has not signed in. A silhouette where a name is
/// already known says less than the name does.
class AccountAvatar extends StatelessWidget {
  final String? name;
  final String? photo;
  const AccountAvatar({super.key, this.name, this.photo});

  static const _size = 46.0;

  /// The colours a nameless avatar can come out. Seven of the app's own —
  /// no new hex, and nothing that could land outside the palette.
  ///
  /// They are used the way the accent already is on this card: the hue at
  /// 14% for the fill, 40% for the ring, full strength for the letters. So
  /// a generated avatar is the same object it has always been, in a
  /// different colour, and its contrast is settled by construction rather
  /// than by which hue the hash happened to pick.
  static const palette = <Color>[
    T.accent,
    T.home,
    T.success,
    T.warning,
    T.routeAlt,
    T.away,
    T.lime,
  ];

  /// Which of them this name gets. The same coach is the same colour on
  /// every launch and every device, so it reads as *their* avatar and not
  /// as decoration — which rules out String.hashCode, whose value Dart does
  /// not promise to keep between runs or platforms.
  static Color colorFor(String? name) {
    final key = (name ?? '').trim();
    if (key.isEmpty) return T.accent;
    var h = 0;
    for (final r in key.runes) {
      // Masked to 29 bits: the same arithmetic on the web's 53-bit ints and
      // on a phone's 64-bit ones.
      h = (h * 31 + r) & 0x1FFFFFFF;
    }
    return palette[h % palette.length];
  }

  /// Up to two letters. "zach song" → "ZS"; a one-word or CJK name → its
  /// first character, because the second character of 宋 is not an initial.
  static String? _initials(String? raw) {
    final parts = (raw ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    final first = String.fromCharCode(parts.first.runes.first);
    if (parts.length == 1) return first.toUpperCase();
    final last = String.fromCharCode(parts.last.runes.first);
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final hue = colorFor(name);
    Widget fallback() => Center(
          child: initials == null
              ? Icon(Icons.person_outline_rounded, color: hue, size: 24)
              : Text(initials,
                  style: TextStyle(
                      color: hue, fontSize: 17, fontWeight: FontWeight.w700)),
        );

    return Container(
      width: _size,
      height: _size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hue.withValues(alpha: 0.14),
        border: Border.all(color: hue.withValues(alpha: 0.4)),
      ),
      child: photo == null
          ? fallback()
          : Image.network(
              photo!,
              fit: BoxFit.cover,
              width: _size,
              height: _size,
              // A card that is mostly one row must not jump when the picture
              // arrives, and must not sit empty if it never does.
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback(),
              errorBuilder: (_, _, _) => fallback(),
            ),
    );
  }
}

/// The bar itself.
///
/// Drawn rather than taken from BottomNavigationBar: that widget brings
/// Material 3's own surface colour, its own ripple and its own idea of how
/// much a selected label should grow, and undoing all three came to more
/// code than drawing four columns.
class _TabBar extends StatelessWidget {
  /// The index into the four items, where 1 is the board — which is not a
  /// tab and therefore never stays selected.
  final int current;
  final void Function(int) onTap;
  const _TabBar({required this.current, required this.onTap});

  static const _items = [
    (Icons.home_rounded, 'tab_home'),
    (Icons.dashboard_outlined, 'tab_board'),
    (Icons.fitness_center, 'tab_drills'),
    (Icons.person_outline_rounded, 'tab_mine'),
  ];

  /// The bar's index for the tab showing: 0 → 0, 1 → 2, 2 → 3, because the
  /// board sits at 1 in the bar and nowhere in the stack.
  int get _selected => current == 0 ? 0 : current + 1;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: T.surface,
        border: const Border(top: BorderSide(color: T.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _TabButton(
                    icon: _items[i].$1,
                    label: _items[i].$2.tr(),
                    selected: i == _selected,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tablet's form of [_TabBar]: the same four items, down the leading
/// edge, as an iPadOS sidebar does.
class _SideRail extends StatelessWidget {
  final int current;
  final void Function(int) onTap;
  const _SideRail({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = current == 0 ? 0 : current + 1;
    return DecoratedBox(
      key: const ValueKey('shell-side-rail'),
      decoration: BoxDecoration(
        color: T.surface,
        border: const Border(right: BorderSide(color: T.border)),
      ),
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: 92,
          child: Column(
            children: [
              const SizedBox(height: T.s24),
              for (var i = 0; i < _TabBar._items.length; i++)
                SizedBox(
                  height: 76,
                  child: _TabButton(
                    icon: _TabBar._items[i].$1,
                    label: _TabBar._items[i].$2.tr(),
                    selected: i == selected,
                    onTap: () => onTap(i),
                    large: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  /// The rail's size: a bigger glyph and label for a tablet.
  final bool large;
  const _TabButton(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap,
      this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = selected ? T.accent : T.textOff;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: large ? 26 : 22, color: color),
          SizedBox(height: large ? 5 : 3),
          // One line, shrinking rather than wrapping: "Ejercicios" under a
          // quarter of a 320pt screen has 80pt to live in.
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color,
                  fontSize: large ? 12.5 : 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        ],
      ),
    );
  }
}

/// The coach's own things: what they have made, and what the app is set to.
///
/// Both were reachable already — the boards through the home page, the
/// settings through a ⋯ menu in its corner — which is exactly the problem a
/// tab bar exists to fix: a menu hides what an app can do behind a glyph
/// that says nothing. Gathering them is not enough on its own, though: four
/// naked rows under a title is a page that looks unfinished however finished
/// it is. So it opens with who you are, says what you have made in numbers
/// before it says it in a list, and groups the rest into the two things a
/// settings page is actually made of — your content, and your preferences.
class _MinePage extends StatefulWidget {
  final VoidCallback onOpenBoard;
  const _MinePage({required this.onOpenBoard});

  @override
  State<_MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<_MinePage> {
  List<TacticMeta> _mine = const [];
  int _plans = 0;
  int _starred = 0;
  int _drills = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final state = context.read<TacticsState>();
    state.listSavedTacticMetas().then((m) {
      m.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) setState(() => _mine = m);
    }).catchError((_) {});
    PracticeService.listNames(state.sportType).then((n) {
      if (mounted) setState(() => _plans = n.length);
    }).catchError((_) {});
    DrillNotesService.instance.all(state.sportType).then((m) {
      final n = m.values.where((e) => e.starred).length;
      if (mounted) setState(() => _starred = n);
    }).catchError((_) {});
    DrillLibraryService.instance.forSport(state.sportType).then((d) {
      if (mounted) setState(() => _drills = d.length);
    }).catchError((_) {});
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) _refresh();
  }

  /// A form — sign in, contact — which a tablet shows as a form sheet.
  Future<void> _pushForm(Widget page) async {
    await pushFormSheet<void>(context, page);
    if (mounted) _refresh();
  }

  Future<void> _openLibrary({bool mine = false, bool starred = false}) async {
    final state = context.read<TacticsState>();
    await DrillLibraryPage.push(
      context,
      state,
      openMine: mine,
      starredOnly: starred,
      onLoaded: widget.onOpenBoard,
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<TacticsState>();
    final auth = AuthService.instance;
    return SafeArea(
      bottom: false,
      // A tablet keeps the page to a readable column, centred; the list still
      // scrolls from anywhere on the screen.
      child: LayoutBuilder(builder: (context, c) {
        final x = T.screenX + tabletInset(context, c.maxWidth);
        return ListView(
        padding: EdgeInsets.fromLTRB(x, T.s16, x, T.s32),
        children: [
          Text('tab_mine'.tr(),
              style: const TextStyle(
                  color: T.text, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: T.s16),

          // Who you are, or the offer to become someone. The account is the
          // one thing on this page that is about the coach rather than about
          // the app, so it goes first and looks different from the rest.
          _AccountCard(
            name: auth.isLoggedIn ? (auth.userName ?? 'menu_login'.tr()) : null,
            email: auth.userEmail,
            photo: auth.userPhoto,
            onTap: () => _pushForm(const LoginPage()).then((_) {
              if (mounted) setState(() {});
            }),
          ),
          const SizedBox(height: T.s16),

          // What the coach has made, in one line. A settings page that opens
          // with an empty list says "you have nothing"; three numbers say
          // what there is to come back to.
          Row(
            children: [
              Expanded(
                  child: _Stat(
                      value: '${_mine.length}', label: 'home_mine'.tr())),
              const SizedBox(width: T.s8),
              Expanded(
                  child: _Stat(
                      value: '$_starred', label: 'home_starred'.tr())),
              const SizedBox(width: T.s8),
              Expanded(
                  child: _Stat(
                      value: '$_drills', label: 'tab_drills'.tr())),
            ],
          ),
          const SizedBox(height: T.s24),

          _SectionLabel('mine_content'.tr()),
          _Card(children: [
            _Row(
              icon: Icons.dashboard_outlined,
              label: 'home_mine'.tr(),
              trailing: _mine.isEmpty ? 'mine_none'.tr() : '${_mine.length}',
              onTap: () => _openLibrary(mine: true),
            ),
            _Row(
              icon: Icons.star_outline_rounded,
              label: 'home_starred'.tr(),
              trailing: _starred == 0 ? 'mine_none'.tr() : '$_starred',
              onTap: () => _openLibrary(starred: true),
            ),
            _Row(
              icon: Icons.event_note_outlined,
              label: 'practice_plan'.tr(),
              trailing: _plans == 0 ? 'mine_none'.tr() : '$_plans',
              onTap: () => _push(PracticePlanPage(state: state)),
              last: true,
            ),
          ]),
          const SizedBox(height: T.s24),

          _SectionLabel('mine_settings'.tr()),
          _Card(children: [
            _Row(
              icon: Icons.language_rounded,
              label: 'menu_language'.tr(),
              // The language names itself: a coach looking for Thai is
              // looking for ภาษาไทย, not for "th_TH".
              trailing: LanguagePicker.nameOf(context.locale),
              onTap: () => LanguagePicker.show(context),
            ),
            _Row(
              icon: Icons.mail_outline_rounded,
              label: 'menu_contact'.tr(),
              onTap: () => _pushForm(const ContactPage()),
              last: true,
            ),
          ]),

          const SizedBox(height: T.s32),
          // The version, small and grey at the bottom, where a support email
          // can ask for it and the coach can find it without being told how.
          Center(
            child: Text(
              'home_board_title'.tr(args: [state.sportType.displayName]) +
                  (kAppVersion.isEmpty ? '' : '  ·  $kAppVersion'),
              style: const TextStyle(color: T.textOff, fontSize: 11.5),
            ),
          ),
        ],
      );
      }),
    );
  }
}

/// The app's own version, shown at the foot of the settings page.
///
/// Passed in by the build — tools/build_all_ipa.sh reads it out of the app's
/// own pubspec — rather than written here. It was a constant, and one
/// constant cannot be right for sixteen apps on sixteen version numbers:
/// soccer went to App Store Connect as 2.0.1 with its settings page still
/// reading 2.0.0, and the field hockey build after it read 2.0.1 while
/// being 2.0.0. A development build passes nothing and shows nothing, which
/// is honest — it has no release version to show.
const String kAppVersion = String.fromEnvironment('APP_VERSION');

class _AccountCard extends StatelessWidget {
  final String? name;
  final String? email;
  /// Null for a signed-out coach and for every Apple account — Apple does
  /// not hand out a picture. See AuthService.userPhoto.
  final String? photo;
  final VoidCallback onTap;
  const _AccountCard(
      {this.name, this.email, this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final signedIn = name != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(T.s16),
        decoration: BoxDecoration(
          borderRadius: T.brLg,
          border: Border.all(color: T.border),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // From the app's own chrome, not a fixed teal: on a re-hued
            // single-sport app (the footvolley sand, say) the hard-coded
            // teal corner was the one piece of the hub left on the page.
            colors: [T.surfaceHi, T.surface],
          ),
        ),
        child: Row(
          children: [
            AccountAvatar(name: name, photo: photo),
            const SizedBox(width: T.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(signedIn ? name! : 'menu_login'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: T.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(signedIn ? (email ?? '') : 'login_subtitle'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: T.textDim, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: T.textOff),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: T.s12, horizontal: T.s8),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: T.brMd,
        border: Border.all(color: T.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: T.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: T.textDim, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: T.s8),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              color: T.textOff,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8)),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: T.brMd,
        border: Border.all(color: T.border),
      ),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  /// No hairline under the last row: a divider against the card's own edge
  /// reads as a line that failed to line up with something.
  final bool last;
  const _Row(
      {required this.icon,
      required this.label,
      this.trailing,
      required this.onTap,
      this.last = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(T.s12, T.s12, T.s12, T.s12),
        decoration: last
            ? null
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: T.border))),
        child: Row(
          children: [
            Icon(icon, size: 19, color: T.textDim),
            const SizedBox(width: T.s12),
            // The label takes the row and the value sits at its far end, by
            // the chevron. Expanded + Flexible split the free width in half,
            // which left "None yet" floating mid-row — at x≈700 on an iPad.
            Expanded(
              flex: 3,
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: T.text, fontSize: 15)),
            ),
            if (trailing != null) ...[
              const SizedBox(width: T.s8),
              Expanded(
                flex: 2,
                child: Text(trailing!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: T.textOff, fontSize: 13)),
              ),
            ],
            const SizedBox(width: T.s4),
            const Icon(Icons.chevron_right, size: 18, color: T.textOff),
          ],
        ),
      ),
    );
  }
}
