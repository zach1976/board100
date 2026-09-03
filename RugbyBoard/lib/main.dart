import 'package:tactics_board/config_constants.dart';
import 'package:tactics_board/main.dart';
import 'package:tactics_board/models/sport_type.dart';

/// Rugby Board (com.zach.rugbyBoard) — a single-sport build of the shared board.
///
/// Everything below is configuration; the app itself is the tactics_board
/// package. Per-sport ad unit ids are NOT set here on purpose: AdService
/// looks them up by sport, so this shell cannot get them wrong.
void main() {
  ConfigConstants.fixedSportType = SportType.rugby;
  // The core is a dependency here, so its assets live under
  // packages/tactics_board/ in this app's bundle.
  ConfigConstants.hasPackagePath = true;
  mainReal();
}
