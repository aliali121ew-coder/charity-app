import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// عدّاد تنازلي حيّ يتحدّث كل ثانية حتى موعد [target].
/// يعرض الأيام/الساعات/الدقائق/الثواني بحسب ما تبقّى.
class CountdownText extends StatefulWidget {
  final DateTime target;
  final double fontSize;
  final Color color;
  final String endedLabel;
  final bool showIcon;
  final VoidCallback? onEnded; // يُستدعى مرّة واحدة عند بلوغ الصفر

  const CountdownText({
    super.key,
    required this.target,
    required this.color,
    this.fontSize = 10.5,
    this.endedLabel = 'انتهت',
    this.showIcon = true,
    this.onEnded,
  });

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  late Duration _remaining;
  bool _firedEnded = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.target.difference(DateTime.now());
    _firedEnded = _remaining.inSeconds <= 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = widget.target.difference(DateTime.now()));
      if (!_firedEnded && _remaining.inSeconds <= 0) {
        _firedEnded = true;
        widget.onEnded?.call(); // أبلغ الأب ليُحدّث الحالة/الزر لحظياً
      }
    });
  }

  @override
  void didUpdateWidget(covariant CountdownText old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      _remaining = widget.target.difference(DateTime.now());
      _firedEnded = _remaining.inSeconds <= 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (days >= 1) return '$days ي  $hours س  $minutes د  $seconds ث';
    if (hours >= 1) return '$hours س  $minutes د  $seconds ث';
    return '$minutes د  $seconds ث';
  }

  @override
  Widget build(BuildContext context) {
    final ended = _remaining.isNegative || _remaining.inSeconds <= 0;
    // تحت ساعة → لون تحذيري للإلحاح.
    final urgent = !ended && _remaining.inHours < 1;
    final color = urgent ? const Color(0xFFEF4444) : widget.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          Icon(ended ? Icons.event_busy_rounded : Icons.timer_outlined, size: widget.fontSize + 3, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          ended ? widget.endedLabel : _format(_remaining),
          style: GoogleFonts.cairo(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
