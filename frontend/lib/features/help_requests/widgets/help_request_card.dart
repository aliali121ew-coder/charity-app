import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';
import 'package:charity_app/features/help_requests/domain/entities/request_type.dart';
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

  static _CardConfig _typeConfig(RequestType t) {
    switch (t) {
      case RequestType.generalHelp:
        return const _CardConfig(
          gradient: LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9), Color(0xFF4C1D95)],
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
            colors: [Color(0xFF06B6D4), Color(0xFF0891B2), Color(0xFF164E63)],
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
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
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
            colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF064E3B)],
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
            colors: [Color(0xFFF97316), Color(0xFFEA580C), Color(0xFF7C2D12)],
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
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF312E81)],
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
    final dateStr = intl.DateFormat('dd/MM/yyyy  HH:mm').format(widget.request.submittedAt);

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: cfg.accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
              width: 1,
            ),
            boxShadow: [
              // Colored glow shadow
              BoxShadow(
                color: cfg.glowColor.withValues(alpha: isDark ? 0.35 : 0.22),
                blurRadius: 18,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
              // Deep dark shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.14),
                blurRadius: 28,
                spreadRadius: -6,
                offset: const Offset(0, 14),
              ),
              // Top highlight (light reflection)
              BoxShadow(
                color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.9),
                blurRadius: 0,
                spreadRadius: 0,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              children: [
                // ── Gradient Header ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                    gradient: cfg.gradient,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 3D Icon container
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  blurRadius: 0,
                                  offset: const Offset(0, -1),
                                ),
                              ],
                            ),
                            child: Icon(
                              cfg.icon,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.request.type.labelAr,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(alpha: 0.95),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.request.title,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  maxLines: 3,
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
                    ],
                  ),
                ),

                // ── Divider shine line ───────────────────────────────
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cfg.accentColor.withValues(alpha: 0.0),
                        cfg.accentColor.withValues(alpha: 0.4),
                        cfg.accentColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),

                // ── Body ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? LinearGradient(
                            colors: [
                              const Color(0xFF0F172A),
                              cfg.accentColor.withValues(alpha: 0.04),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white,
                              cfg.accentColor.withValues(alpha: 0.03),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.description,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Meta chips row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _MetaChip(
                            icon: Icons.location_on_outlined,
                            label: '${widget.request.governorate} - ${widget.request.area}',
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
                              label: '${widget.request.attachments.length} مرفقات',
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

                      // Footer row
                      Row(
                        children: [
                          EditWindowIndicator(
                            request: widget.request,
                            onEditTap: widget.onEditTap,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cfg.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: cfg.accentColor,
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
