import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/drill.dart';
import '../models/sport_type.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';

/// Report something wrong with a drill.
///
/// The library is generated — 624 boards from a few hundred lines of Python —
/// and when one of them is wrong it is usually wrong for a whole family. A
/// coach who spots it is the cheapest bug report there is, so the form
/// carries the drill's id and sport for them and asks only what is wrong.
///
/// Goes to the same endpoint as Contact Us; a second inbox would be a second
/// thing to remember to read.
class DrillReportPage extends StatefulWidget {
  final Drill drill;
  final SportType sportType;
  final String locale;
  const DrillReportPage({
    super.key,
    required this.drill,
    required this.sportType,
    required this.locale,
  });

  static Future<void> push(BuildContext context,
      {required Drill drill,
      required SportType sportType,
      required String locale}) {
    return Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => DrillReportPage(
          drill: drill, sportType: sportType, locale: locale),
    ));
  }

  @override
  State<DrillReportPage> createState() => _DrillReportPageState();
}

class _DrillReportPageState extends State<DrillReportPage> {
  final _bodyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _kind;
  bool _sending = false;

  /// The things that actually go wrong in a generated library, in the words
  /// a coach would use. Picking one is optional but it sorts the inbox.
  static const _kinds = [
    ('wrong_shape', 'report_kind_shape'),
    ('wrong_text', 'report_kind_text'),
    ('wrong_sport', 'report_kind_sport'),
    ('other', 'report_kind_other'),
  ];

  @override
  void dispose() {
    _bodyCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('report_needs_detail'.tr())),
      );
      return;
    }
    setState(() => _sending = true);
    final d = widget.drill;
    try {
      final response = await http.post(
        Uri.parse('https://tacticsboard.100for1.com/api/v1/send-email'),
        body: {
          'from': 'support@ScoreSyncer.com',
          'to': 'zachsong@gmail.com',
          'email': _emailCtrl.text.trim(),
          'sport': widget.sportType.name,
          'app': widget.sportType.displayName,
          'subject': 'Drill report: ${d.id}',
          // Everything needed to find the drill in tools/drills/ without
          // asking the coach a single follow-up question.
          'message': [
            'drill: ${d.id}',
            'name: ${d.localizedName(widget.locale)}',
            'sport: ${widget.sportType.name}',
            'locale: ${widget.locale}',
            if (_kind != null) 'kind: $_kind',
            '',
            body,
          ].join('\n'),
        },
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      final ok = response.statusCode == 200;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'report_sent'.tr() : 'send_error'.tr()),
        backgroundColor: ok ? Colors.green : null,
      ));
      if (ok) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('send_error'.tr())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg0,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(T.s8, T.s4, T.screenX, T.s8),
              child: Row(
                children: [
                  TacticalIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: T.s4),
                  Expanded(
                    child: Text('report_title'.tr(),
                        style: const TextStyle(
                            color: T.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    T.screenX, 0, T.screenX, T.s24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(T.s12),
                    decoration: const BoxDecoration(
                        color: T.surface, borderRadius: T.brMd),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 16, color: T.textDim),
                        const SizedBox(width: T.s8),
                        Expanded(
                          child: Text(
                              widget.drill.localizedName(widget.locale),
                              style: const TextStyle(
                                  color: T.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: T.s20),
                  Text('report_what'.tr(),
                      style: const TextStyle(
                          color: T.textOff,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                  const SizedBox(height: T.s8),
                  Wrap(
                    spacing: T.s8,
                    runSpacing: T.s8,
                    children: [
                      for (final (key, label) in _kinds)
                        TacticalChip(
                          label: label.tr(),
                          selected: _kind == key,
                          onTap: () => setState(
                              () => _kind = _kind == key ? null : key),
                        ),
                    ],
                  ),
                  const SizedBox(height: T.s20),
                  TextField(
                    controller: _bodyCtrl,
                    maxLines: 5,
                    style: const TextStyle(color: T.text),
                    decoration: InputDecoration(
                      hintText: 'report_hint'.tr(),
                      hintStyle: const TextStyle(color: T.textOff),
                      filled: true,
                      fillColor: T.surface,
                      border: const OutlineInputBorder(
                          borderRadius: T.brMd, borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: T.s12),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: T.text),
                    decoration: InputDecoration(
                      hintText: 'report_email_optional'.tr(),
                      hintStyle: const TextStyle(color: T.textOff),
                      filled: true,
                      fillColor: T.surface,
                      border: const OutlineInputBorder(
                          borderRadius: T.brMd, borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                  T.screenX, T.s12, T.screenX, T.s12),
              decoration: const BoxDecoration(
                color: T.bg1,
                border: Border(top: BorderSide(color: T.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: TacticalButton(
                  label: _sending ? 'sending'.tr() : 'report_send'.tr(),
                  icon: Icons.send_outlined,
                  onTap: _sending ? null : _send,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
