import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sport_type.dart';
import '../state/tactics_state.dart';
import '../widgets/language_picker.dart';
import '../widgets/tactics_canvas.dart';
import '../widgets/toolbar.dart';
import 'sport_selection_page.dart';

class TacticsBoardHomePage extends StatelessWidget {
  const TacticsBoardHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TacticsState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1E2E),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SportSelectionPage()),
              ),
            ),
            title: Row(
              children: [
                Text(state.sportType.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  state.sportType.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'tactics_board'.tr(),
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _showSportPicker(context, state),
                icon: const Icon(Icons.sports, color: Colors.white70, size: 18),
                label: Text(
                  'sport_label'.tr(),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.language, color: Colors.white70),
                onPressed: () => LanguagePicker.show(context),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: const TacticsCanvas(),
                ),
              ),
              const TacticsToolbar(),
            ],
          ),
        );
      },
    );
  }

  void _showSportPicker(BuildContext context, TacticsState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'choose_sport'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              ...SportType.values.map((sport) => ListTile(
                    leading: Text(sport.emoji, style: const TextStyle(fontSize: 28)),
                    title: Text(
                      sport.displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    selected: state.sportType == sport,
                    selectedColor: Colors.blue,
                    selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                    onTap: () {
                      if (state.sportType != sport) {
                        _confirmSwitch(ctx, context, state, sport);
                      } else {
                        Navigator.pop(ctx);
                      }
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSwitch(
      BuildContext sheetCtx, BuildContext pageCtx, TacticsState state, SportType sport) {
    final hasContent = state.players.isNotEmpty || state.strokes.isNotEmpty;
    if (!hasContent) {
      state.setSportType(sport);
      Navigator.pop(sheetCtx);
      return;
    }
    showDialog(
      context: pageCtx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text('switch_sport_title'.tr(), style: const TextStyle(color: Colors.white)),
        content: Text(
          'switch_sport_message'.tr(args: [sport.displayName]),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              state.setSportType(sport);
              Navigator.pop(dCtx);
              Navigator.pop(sheetCtx);
            },
            child: Text('switch'.tr(), style: const TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}
