import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';

class EditWindowIndicator extends StatefulWidget {
  final HelpRequest request;
  final VoidCallback? onEditTap;

  const EditWindowIndicator({
    super.key,
    required this.request,
    this.onEditTap,
  });

  @override
  State<EditWindowIndicator> createState() => _EditWindowIndicatorState();
}

class _EditWindowIndicatorState extends State<EditWindowIndicator> {
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.request.editSecondsRemaining;
    if (_secondsRemaining > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _secondsRemaining = widget.request.editSecondsRemaining;
          if (_secondsRemaining <= 0) _timer?.cancel();
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = _secondsRemaining > 0;

    if (!isEditable) {
      return _ExpiredBadge();
    }

    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: widget.onEditTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_note_rounded,
                size: 16, color: Color(0xFFEA580C)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'قابل للتعديل',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEA580C),
                  ),
                ),
                Text(
                  'متبقي $timeStr',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: const Color(0xFFC2410C),
                  ),
                ),
              ],
            ),
            if (widget.onEditTap != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'تعديل',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpiredBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 14, color: Color(0xFF94A3B8)),
          const SizedBox(width: 5),
          Text(
            'انتهت مهلة التعديل',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
