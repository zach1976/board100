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
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide > 600;
    final crossCount = isTablet ? 3 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(isTablet ? 32 : 20, isTablet ? 28 : 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      'app_title'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      'choose_sport'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.language, color: Colors.white54),
                    onPressed: () => LanguagePicker.show(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 12),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: SportType.values.length,
                  itemBuilder: (ctx, i) => _SportCard(
                    sport: SportType.values[i],
                    painter: _painterFor(SportType.values[i]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SportCard extends StatelessWidget {
  final SportType sport;
  final CustomPainter painter;

  const _SportCard({required this.sport, required this.painter});

  void _navigate(BuildContext context) {
    context.read<TacticsState>().setSportType(sport);
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
      onTap: () => _navigate(context),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: sport.isLandscapeCourt
                  ? CustomPaint(painter: painter)
                  : RotatedBox(
                      quarterTurns: 1,
                      child: CustomPaint(painter: painter),
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.black.withValues(alpha: 0.35),
              child: Row(
                children: [
                  Text(sport.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    sport.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.white.withValues(alpha: 0.3), size: 13),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
