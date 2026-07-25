part of '../pages/donations_page.dart';

class _QuickAmounts extends StatelessWidget {
  final double? selected;
  final ValueChanged<double> onSelect;

  const _QuickAmounts(
      {required this.selected, required this.onSelect});

  static const _amounts = [
    25000.0, 50000.0, 100000.0, 250000.0, 500000.0, 1000000.0
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _amounts.map((a) {
        final isSel = selected == a;
        final label = a >= 1000000
            ? '${(a / 1000000).toStringAsFixed(0)}M'
            : NumberFormat('#,###').format(a);
        return GestureDetector(
          onTap: () => onSelect(a),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSel
                  ? const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)
                  : null,
              color: isSel
                  ? null
                  : (isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSel
                      ? Colors.transparent
                      : (isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight)),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]
                  : null,
            ),
            child: Column(children: [
              Text(label,
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSel
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight))),
              Text('د.ع',
                  style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: isSel
                          ? Colors.white.withValues(alpha: 0.75)
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight))),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Custom Amount Field ───────────────────────────────────────────────────────

class _CustomAmountField extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CustomAmountField(
      {required this.isDark,
      required this.controller,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: 'أو أدخل مبلغاً مخصصاً...',
        hintStyle: GoogleFonts.cairo(
            fontSize: 14,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight),
        suffixText: 'د.ع',
        suffixStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary),
        prefixIcon:
            const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight)),
        focusedBorder: const OutlineInputBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(14)),
            borderSide:
                BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Donate Button ─────────────────────────────────────────────────────────────

class _DonateButton extends StatelessWidget {
  final bool isDark, loading;
  final PaymentMethod method;
  final double? amount;
  final VoidCallback onTap;

  const _DonateButton(
      {required this.isDark,
      required this.loading,
      required this.method,
      required this.amount,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final amountText = amount != null
        ? '${NumberFormat('#,###').format(amount)} د.ع'
        : 'اختر مبلغاً';
    final hasAmount = amount != null;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: hasAmount
                  ? const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF059669)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight)
                  : null,
              color: hasAmount
                  ? null
                  : (isDark
                      ? AppColors.surfaceVariantDark
                      : const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: hasAmount
                  ? [
                      BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6))
                    ]
                  : null,
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(method.icon,
                            color: hasAmount
                                ? Colors.white
                                : AppColors.textSecondaryLight,
                            size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'تبرع الآن — $amountText',
                          style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: hasAmount
                                  ? Colors.white
                                  : AppColors.textSecondaryLight),
                        ),
                      ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Security Note ─────────────────────────────────────────────────────────────

class _SecurityNote extends StatelessWidget {
  final bool isDark;
  const _SecurityNote({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success
              .withValues(alpha: isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.lock_rounded,
              size: 15, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
            'جميع معاملاتك محمية بتشفير SSL 256-bit. بياناتك في أمان تام.',
            style: GoogleFonts.cairo(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          )),
        ]),
      );
}

// ── Success Bottom Sheet ──────────────────────────────────────────────────────

class _SuccessSheet extends StatefulWidget {
  final PaymentMethod method;
  final double amount;
  final VoidCallback onViewHistory;

  const _SuccessSheet({
    required this.method,
    required this.amount,
    required this.onViewHistory,
  });

  @override
  State<_SuccessSheet> createState() => _SuccessSheetState();
}

class _SuccessSheetState extends State<_SuccessSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(
        parent: _ctrl,
        curve:
            const Interval(0.0, 0.6, curve: Curves.elasticOut));
    _fadeAnim = CurvedAnimation(
        parent: _ctrl,
        curve:
            const Interval(0.3, 1.0, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final refNum =
        'TRF-${DateTime.now().millisecondsSinceEpoch % 100000}';
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
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
        const SizedBox(height: 24),
        ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 8))
              ],
            ),
            child:
                const Icon(Icons.check_rounded, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 20),
        FadeTransition(
            opacity: _fadeAnim,
            child: Column(children: [
              Text('تم التبرع بنجاح!',
                  style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text('شكراً لتبرعك الكريم',
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.textSecondaryLight)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : const Color(0xFFE2E8F0)),
                ),
                child: Column(children: [
                  _ReceiptRow(
                      label: 'المبلغ',
                      value:
                          '${NumberFormat('#,###').format(widget.amount)} د.ع',
                      valueColor: AppColors.primary,
                      isDark: isDark),
                  Divider(
                      height: 20,
                      color: isDark
                          ? AppColors.borderDark
                          : const Color(0xFFE2E8F0)),
                  _ReceiptRow(
                      label: 'طريقة الدفع',
                      value: widget.method.labelAr,
                      isDark: isDark),
                  const SizedBox(height: 8),
                  _ReceiptRow(
                      label: 'رقم المرجع',
                      value: refNum,
                      isDark: isDark),
                  const SizedBox(height: 8),
                  _ReceiptRow(
                      label: 'التاريخ',
                      value: DateFormat('dd/MM/yyyy hh:mm a')
                          .format(DateTime.now()),
                      isDark: isDark),
                  const SizedBox(height: 8),
                  _ReceiptRow(
                      label: 'الحالة',
                      value: widget.method == PaymentMethod.bankTransfer
                          ? 'قيد المعالجة ⏳'
                          : 'مكتمل ✓',
                      valueColor:
                          widget.method == PaymentMethod.bankTransfer
                              ? AppColors.warning
                              : AppColors.success,
                      isDark: isDark),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onViewHistory,
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('عرض السجل',
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text('حسناً، شكراً',
                        style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ])),
      ]),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool isDark;

  const _ReceiptRow(
      {required this.label,
      required this.value,
      this.valueColor,
      required this.isDark});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                  color: valueColor ??
                      (isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF0F172A)))),
        ],
      );
}

// ── Transfer History Tab ──────────────────────────────────────────────────────

