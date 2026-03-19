import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_status.dart';

class RequestStatusBadge extends StatelessWidget {
  final RequestStatus status;
  final bool compact;

  const RequestStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, text, icon) = _style(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 12, color: text),
          const SizedBox(width: 4),
          Text(
            status.labelAr,
            style: GoogleFonts.cairo(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: text,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  static (Color bg, Color text, IconData icon) _style(RequestStatus s) {
    switch (s) {
      case RequestStatus.pending:
        return (
          const Color(0xFFFEF3C7),
          const Color(0xFF92400E),
          Icons.schedule_rounded
        );
      case RequestStatus.underReview:
        return (
          const Color(0xFFDBEAFE),
          const Color(0xFF1E40AF),
          Icons.manage_search_rounded
        );
      case RequestStatus.approved:
        return (
          const Color(0xFFD1FAE5),
          const Color(0xFF065F46),
          Icons.check_circle_rounded
        );
      case RequestStatus.rejected:
        return (
          const Color(0xFFFEE2E2),
          const Color(0xFF991B1B),
          Icons.cancel_rounded
        );
      case RequestStatus.completed:
        return (
          const Color(0xFFEDE9FF),
          const Color(0xFF4C1D95),
          Icons.verified_rounded
        );
    }
  }
}
