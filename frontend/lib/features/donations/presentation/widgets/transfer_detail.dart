part of '../pages/donations_page.dart';

class _TransferDetailSheet extends ConsumerWidget {
  final TransferRecord transfer;
  final bool isDark, isAdmin;

  const _TransferDetailSheet(
      {required this.transfer,
      required this.isDark,
      required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: isDark
                    ? AppColors.borderDark
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Row(children: [
          Container(
            width: 56,
            height: 56,
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
                    color:
                        transfer.avatarColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Center(
                child: Text(transfer.avatarInitials,
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white))),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(transfer.donor,
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight)),
                Text(transfer.method.labelAr,
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: transfer.method.accentColor,
                        fontWeight: FontWeight.w600)),
              ])),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: transfer.statusBg,
                borderRadius: BorderRadius.circular(10)),
            child: Text(transfer.status,
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: transfer.statusColor)),
          ),
        ]),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: transfer.method.cardGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: transfer.method.accentColor
                      .withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Column(children: [
            Text('المبلغ المحوّل',
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75))),
            const SizedBox(height: 4),
            Text(
                '${NumberFormat('#,###').format(transfer.amount)} د.ع',
                style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardDark
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : const Color(0xFFE2E8F0)),
          ),
          child: Column(children: [
            _DetailRow(
                label: 'رقم المرجع',
                value: transfer.reference,
                isDark: isDark),
            const SizedBox(height: 10),
            _DetailRow(
                label: 'طريقة الدفع',
                value: transfer.method.labelAr,
                isDark: isDark),
            const SizedBox(height: 10),
            _DetailRow(
                label: 'التاريخ',
                value:
                    DateFormat('dd/MM/yyyy').format(transfer.date),
                isDark: isDark),
            const SizedBox(height: 10),
            _DetailRow(
                label: 'الوقت',
                value: DateFormat('hh:mm a').format(transfer.date),
                isDark: isDark),
            const SizedBox(height: 10),
            _DetailRow(
                label: 'رقم العملية',
                value: transfer.id,
                isDark: isDark),
          ]),
        ),
        // Admin: change status
        if (isAdmin &&
            transfer.status == 'قيد المعالجة') ...[
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ref
                      .read(donationsProvider.notifier)
                      .updateStatus(transfer.id, 'مرفوض');
                  Navigator.pop(context);
                },
                icon:
                    const Icon(Icons.close_rounded, size: 16),
                label: Text('رفض',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(donationsProvider.notifier)
                      .updateStatus(transfer.id, 'مكتمل');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تأكيد التحويل',
                          style: GoogleFonts.cairo()),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(
                    Icons.check_circle_rounded,
                    size: 16),
                label: Text('تأكيد',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ],
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon:
                  const Icon(Icons.close_rounded, size: 16),
              label: Text('إغلاق',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.receipt_long_rounded,
                  size: 16),
              label: Text('طباعة الإيصال',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool isDark;

  const _DetailRow(
      {required this.label,
      required this.value,
      required this.isDark});

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: GoogleFonts.cairo(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight)),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight)),
      ]);
}

// ── Operations Log Tab ────────────────────────────────────────────────────────

