part of '../pages/donations_page.dart';

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : color,
          ),
        ),
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final TransferRecord transfer;
  final bool isDark, isAdmin;
  final VoidCallback onTap;

  const _TransferCard(
      {required this.transfer,
      required this.isDark,
      required this.isAdmin,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color:
                  isDark ? AppColors.borderDark : AppColors.borderLight),
          boxShadow: [
            BoxShadow(
                color: Colors.black
                    .withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                spreadRadius: -3,
                offset: const Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [
                      transfer.avatarColor,
                      transfer.avatarColor.withValues(alpha: 0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: transfer.avatarColor
                          .withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Center(
                  child: Text(transfer.avatarInitials,
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transfer.donor,
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: transfer.method.accentColor
                                .withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(6)),
                        child: Text(transfer.method.labelAr,
                            style: GoogleFonts.cairo(
                                fontSize: 10,
                                color:
                                    transfer.method.accentColor,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(transfer.reference,
                            style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ]),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(NumberFormat('#,###').format(transfer.amount),
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight)),
              Text('د.ع',
                  style: GoogleFonts.cairo(
                      fontSize: 9,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: transfer.statusBg,
                    borderRadius: BorderRadius.circular(7)),
                child: Text(transfer.status,
                    style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: transfer.statusColor)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Transfer Detail Bottom Sheet ──────────────────────────────────────────────

