import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_type.dart';
import 'package:charity_app/features/help_requests/domain/entities/urgency_level.dart';
import 'package:charity_app/features/help_requests/widgets/request_status_badge.dart';
import 'package:charity_app/features/help_requests/widgets/edit_window_indicator.dart';
import 'package:intl/intl.dart' as intl;

class HelpRequestCard extends StatefulWidget {
  final HelpRequest request;
  final VoidCallback onTap;
  final VoidCallback? onEditTap;

  const HelpRequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.onEditTap,
  });

  @override
  State<HelpRequestCard> createState() => _HelpRequestCardState();
}

class _HelpRequestCardState extends State<HelpRequestCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  static Color _urgencyColor(UrgencyLevel u) {
    switch (u) {
      case UrgencyLevel.critical:
        return const Color(0xFFEF4444);
      case UrgencyLevel.high:
        return const Color(0xFFF59E0B);
      case UrgencyLevel.medium:
        return const Color(0xFF3B82F6);
      case UrgencyLevel.low:
        return const Color(0xFF10B981);
    }
  }

  static _CardConfig _typeConfig(RequestType t) {
    switch (t) {
      case RequestType.generalHelp:
        return const _CardConfig(
          gradient: LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: Color(0xFF8B5CF6),
          icon: Icons.volunteer_activism_rounded,
          glowColor: Color(0xFF8B5CF6),
        );
      case RequestType.doctorBooking:
        return const _CardConfig(
          gradient: LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: Color(0xFF06B6D4),
          icon: Icons.medical_services_rounded,
          glowColor: Color(0xFF06B6D4),
        );
      case RequestType.treatment:
        return const _CardConfig(
          gradient: LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: Color(0xFF3B82F6),
          icon: Icons.medication_rounded,
          glowColor: Color(0xFF3B82F6),
        );
      case RequestType.foodBasket:
        return const _CardConfig(
          gradient: LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: Color(0xFF10B981),
          icon: Icons.shopping_basket_rounded,
          glowColor: Color(0xFF10B981),
        );
      case RequestType.financial:
        return const _CardConfig(
          gradient: LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: Color(0xFFF97316),
          icon: Icons.account_balance_wallet_rounded,
          glowColor: Color(0xFFF97316),
        );
      case RequestType.householdMaterials:
        return const _CardConfig(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: Color(0xFF6366F1),
          icon: Icons.chair_rounded,
          glowColor: Color(0xFF6366F1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cfg = _typeConfig(widget.request.type);
    final stripeColor = _urgencyColor(widget.request.urgency);
    final dateStr =
        intl.DateFormat('dd/MM/yyyy  HH:mm').format(widget.request.submittedAt);

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: stripeColor.withValues(alpha: isDark ? 0.18 : 0.1),
                blurRadius: 14,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.07),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // ── Left accent stripe (position absolute) ──────────────
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: 4,
                  child: Container(color: stripeColor),
                ),

                // ── Card content (padded away from stripe) ──────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ────────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: cfg.gradient,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: [
                                BoxShadow(
                                  color: cfg.glowColor.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child:
                                Icon(cfg.icon, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),

                          // Title + type badge
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        cfg.accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    widget.request.type.labelAr,
                                    style: GoogleFonts.cairo(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: cfg.accentColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.request.title,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          RequestStatusBadge(
                              status: widget.request.status, compact: true),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── Gradient divider ─────────────────────────────
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              stripeColor.withValues(alpha: 0.4),
                              stripeColor.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Description ──────────────────────────────────
                      Text(
                        widget.request.description,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          height: 1.55,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),

                      // ── Meta chips ───────────────────────────────────
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _MetaChip(
                            icon: Icons.location_on_outlined,
                            label:
                                '${widget.request.governorate} - ${widget.request.area}',
                            accentColor: cfg.accentColor,
                            isDark: isDark,
                          ),
                          _MetaChip(
                            icon: Icons.access_time_rounded,
                            label: dateStr,
                            accentColor: cfg.accentColor,
                            isDark: isDark,
                          ),
                          if (widget.request.attachments.isNotEmpty)
                            _MetaChip(
                              icon: Icons.attach_file_rounded,
                              label:
                                  '${widget.request.attachments.length} مرفقات',
                              accentColor: cfg.accentColor,
                              isDark: isDark,
                              colored: true,
                            ),
                          if (widget.request.familySize != null)
                            _MetaChip(
                              icon: Icons.group_rounded,
                              label: '${widget.request.familySize} أفراد',
                              accentColor: cfg.accentColor,
                              isDark: isDark,
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── Footer ───────────────────────────────────────
                      Row(
                        children: [
                          EditWindowIndicator(
                            request: widget.request,
                            onEditTap: widget.onEditTap,
                          ),
                          const Spacer(),
                          _UrgencyPill(
                            urgency: widget.request.urgency,
                            color: stripeColor,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: stripeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                  color: stripeColor.withValues(alpha: 0.2)),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: stripeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Urgency pill ───────────────────────────────────────────────────────────────

class _UrgencyPill extends StatelessWidget {
  final UrgencyLevel urgency;
  final Color color;

  const _UrgencyPill({required this.urgency, required this.color});

  IconData get _icon {
    switch (urgency) {
      case UrgencyLevel.critical:
        return Icons.warning_amber_rounded;
      case UrgencyLevel.high:
        return Icons.priority_high_rounded;
      case UrgencyLevel.medium:
        return Icons.remove_rounded;
      case UrgencyLevel.low:
        return Icons.arrow_downward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            urgency.labelAr,
            style: GoogleFonts.cairo(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Internal helpers ──────────────────────────────────────────────────────────

class _CardConfig {
  final LinearGradient gradient;
  final Color accentColor;
  final IconData icon;
  final Color glowColor;

  const _CardConfig({
    required this.gradient,
    required this.accentColor,
    required this.icon,
    required this.glowColor,
  });
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool isDark;
  final bool colored;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.isDark,
    this.colored = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = colored
        ? accentColor
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colored
            ? accentColor.withValues(alpha: 0.1)
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
