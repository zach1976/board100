import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sport_type.dart';
import '../painters/badminton_court_painter.dart';
import '../painters/basketball_court_painter.dart';
import '../painters/tennis_court_painter.dart';
import '../painters/table_tennis_court_painter.dart';
import '../painters/volleyball_court_painter.dart';
import '../painters/pickleball_court_painter.dart';
import '../painters/soccer_court_painter.dart';
import '../painters/field_hockey_court_painter.dart';
import '../painters/rugby_court_painter.dart';
import '../painters/baseball_court_painter.dart';
import '../painters/handball_court_painter.dart';
import '../painters/water_polo_court_painter.dart';
import '../painters/sepak_takraw_court_painter.dart';
import '../painters/beach_tennis_court_painter.dart';
import '../state/tactics_state.dart';
import '../widgets/language_picker.dart';
import 'home_page.dart';

class SportSelectionPage extends StatelessWidget {
  const SportSelectionPage({super.key});

  static CustomPainter _painterFor(SportType sport) {
    switch (sport) {
      case SportType.badminton:    return const BadmintonCourtPainter();
      case SportType.tableTennis:  return const TableTennisCourtPainter();
      case SportType.tennis:       return const TennisCourtPainter();
      case SportType.basketball:   return const BasketballCourtPainter();
      case SportType.volleyball:   return const VolleyballCourtPainter();
      case SportType.pickleball:   return const PickleballCourtPainter();
      case SportType.soccer:       return const SoccerCourtPainter();
      case SportType.fieldHockey:  return const FieldHockeyCourtPainter();
      case SportType.rugby:        return const RugbyCourtPainter();
      case SportType.baseball:     return const BaseballCourtPainter();
      case SportType.handball:     return const HandballCourtPainter();
      case SportType.waterPolo:    return const WaterPoloCourtPainter();
      case SportType.sepakTakraw:  return const SepakTakrawCourtPainter();
      case SportType.beachTennis:  return const BeachTennisCourtPainter();
    }
  }

  /// Accent color for each sport card gradient
  static Color _accentFor(SportType sport) {
    switch (sport) {
      case SportType.badminton:    return const Color(0xFF43A047); // fresh green
      case SportType.tableTennis:  return const Color(0xFF1E88E5); // sky blue
      case SportType.tennis:       return const Color(0xFF5C6BC0); // indigo
      case SportType.basketball:   return const Color(0xFFE65100); // deep orange
      case SportType.volleyball:   return const Color(0xFFFFA000); // amber
      case SportType.pickleball:   return const Color(0xFF00897B); // teal
      case SportType.soccer:       return const Color(0xFF66BB6A); // light green
      case SportType.fieldHockey:  return const Color(0xFF42A5F5); // sky blue (astroturf)
      case SportType.rugby:        return const Color(0xFF8D6E63); // earthy brown (rugby ball)
      case SportType.baseball:     return const Color(0xFFD32F2F); // red (baseball stitching)
      case SportType.handball:     return const Color(0xFF1976D2); // blue (indoor)
      case SportType.waterPolo:    return const Color(0xFF0288D1); // pool blue
      case SportType.sepakTakraw:  return const Color(0xFFD4A017); // rattan gold
      case SportType.beachTennis:  return const Color(0xFFE6B058); // sand tan
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final crossCount = isLandscape ? 4 : isTablet ? 3 : 2;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF1A3A4A),
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isLandscape ? 16 : isTablet ? 32 : 24,
                topPad + (isLandscape ? 8 : isTablet ? 28 : 20),
                16,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    'app_title'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLandscape ? 20 : 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (!isLandscape) ...[
                    const Spacer(),
                  ] else ...[
                    const SizedBox(width: 12),
                    Text(
                      'choose_sport'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                  ],
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.language, color: Colors.white60, size: 18),
                      onPressed: () => LanguagePicker.show(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isLandscape)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 2, 20, 0),
                child: Text('choose_sport'.tr(), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: isLandscape ? 8 : 16)),

          // ── Sport Grid ──
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: isLandscape ? 12 : isTablet ? 24 : 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: isLandscape ? 8 : 10,
                mainAxisSpacing: isLandscape ? 8 : 10,
                childAspectRatio: isLandscape ? 1.3 : 1.15,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _SportCard(
                  sport: SportType.values[i],
                  painter: _painterFor(SportType.values[i]),
                  accent: _accentFor(SportType.values[i]),
                ),
                childCount: SportType.values.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _SportCard extends StatefulWidget {
  final SportType sport;
  final CustomPainter painter;
  final Color accent;

  const _SportCard({required this.sport, required this.painter, required this.accent});

  @override
  State<_SportCard> createState() => _SportCardState();
}

class _SportCardState extends State<_SportCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  void _navigate() {
    context.read<TacticsState>().setSportType(widget.sport);
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (ctx, anim, sec) => const TacticsBoardHomePage(),
      transitionsBuilder: (ctx, anim, sec, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); _navigate(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.accent.withValues(alpha: 0.22),
                const Color(0xFF1E4250),
                const Color(0xFF1A3A4A),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
            border: Border.all(
              color: widget.accent.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Court preview
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: widget.sport.isLandscapeCourt
                        ? CustomPaint(painter: widget.painter, child: const SizedBox.expand())
                        : RotatedBox(
                            quarterTurns: 1,
                            child: CustomPaint(painter: widget.painter, child: const SizedBox.expand()),
                          ),
                  ),
                ),
              ),
              // Sport name
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  children: [
                    Text(widget.sport.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.sport.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withValues(alpha: 0.3), size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
