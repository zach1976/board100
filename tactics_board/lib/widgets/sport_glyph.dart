import 'package:flutter/material.dart';
import '../config_constants.dart';
import '../models/sport_type.dart';

/// The sport's ball or implement, one sprite per sport, drawn at [size].
class SportGlyph extends StatelessWidget {
  final SportType sport;
  final double size;
  const SportGlyph({super.key, required this.sport, this.size = 24});

  @override
  Widget build(BuildContext context) {
    // A rendered sprite per sport (assets/icon/sport_<key>.png, cut from one
    // generated sheet so the fifteen share a light and a finish). The
    // painter below drew them flat in code and read as a template.
    return Image.asset(
      packageAsset('assets/icon/sport_${sport.name}.png'),
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    );
  }
}
