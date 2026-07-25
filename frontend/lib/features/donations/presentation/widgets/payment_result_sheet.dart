import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/payment_flow_provider.dart';
import '../../domain/models/payment_models.dart';

// ── Payment Result Sheet ──────────────────────────────────────────────────────
// Shows success or failure state after completing a payment.

class PaymentResultSheet extends ConsumerStatefulWidget {
  final PaymentResult result;
  final String donorName;
  final bool isDark;

  const PaymentResultSheet({
    super.key,
    required this.result,
    required this.donorName,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    required PaymentResult result,
    required String donorName,
    required bool isDark,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentResultSheet(
        result: result,
        donorName: donorName,
        isDark: isDark,
      ),
    );
  }

  @override
  ConsumerState<PaymentResultSheet> createState() =>
      _PaymentResultSheetState();
}

class _PaymentResultSheetState extends ConsumerState<PaymentResultSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconCtrl;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut),
    );
    _iconCtrl.forward();
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        top: 16,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            // Animated icon
            ScaleTransition(
              scale: _iconScale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: r.success
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (r.success
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                          .withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  r.success ? Icons.check_rounded : Icons.close_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              r.success ? 'تم الدفع بنجاح!' : 'فشلت عملية الدفع',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              r.success
                  ? 'شكراً لك ${widget.donorName}، تبرعك في طريقه للوصول إلى مستحقيه'
                  : (r.errorMessageAr ?? 'حدث خطأ غير متوقع. يرجى المحاولة مجدداً'),
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : Colors.grey.shade600,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (r.success) ...[
              const SizedBox(height: 24),
              _ReceiptCard(
                  result: r, donorName: widget.donorName, isDark: isDark),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(paymentFlowProvider.notifier).reset();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: r.success
                      ? const Color(0xFF10B981)
                      : const Color(0xFF0F52BA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  r.success ? 'رائع، شكراً!' : 'حسناً',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (!r.success) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(paymentFlowProvider.notifier).retryFromForm();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade700,
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('المحاولة مجدداً'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Receipt Card ──────────────────────────────────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  final PaymentResult result;
  final String donorName;
  final bool isDark;

  const _ReceiptCard({
    required this.result,
    required this.donorName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface =
        isDark ? const Color(0xFF252540) : const Color(0xFFF8FAFF);
    final border =
        isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;
    final session = result.session;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _Row(label: 'اسم المتبرع', value: donorName, isDark: isDark),
          _divider(),
          _Row(
            label: 'المبلغ',
            value: '${_fmtAmount(session?.amount ?? 0)} ${session?.currency.code ?? 'IQD'}',
            isDark: isDark,
            highlight: true,
          ),
          _divider(),
          _Row(
            label: 'رقم المرجع',
            value: result.providerReference ?? '—',
            isDark: isDark,
          ),
          _divider(),
          _Row(
            label: 'معرّف المعاملة',
            value: result.transactionId ?? '—',
            isDark: isDark,
            small: true,
          ),
          _divider(),
          _Row(
            label: 'طريقة الدفع',
            value: session?.method.nameAr ?? '—',
            isDark: isDark,
          ),
          _divider(),
          _Row(
            label: 'التاريخ',
            value: _fmtDate(session?.createdAt ?? DateTime.now()),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
        height: 16,
      );

  String _fmtAmount(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)} مليون';
    return v.toStringAsFixed(0);
  }

  String _fmtDate(DateTime dt) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}، '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;
  final bool small;

  const _Row({
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: highlight
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: small ? 11 : 13,
                fontWeight:
                    highlight ? FontWeight.w800 : FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
