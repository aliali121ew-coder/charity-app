part of '../pages/families_page.dart';

class _SubscriberDetailPage extends StatefulWidget {
  final _Subscriber subscriber;
  final _Delegate delegate;

  const _SubscriberDetailPage({
    required this.subscriber,
    required this.delegate,
  });

  @override
  State<_SubscriberDetailPage> createState() => _SubscriberDetailPageState();
}

class _SubscriberDetailPageState extends State<_SubscriberDetailPage> {
  final Set<int> _paidMonths = {};

  @override
  void initState() {
    super.initState();
    // Pre-populate paid months based on widget.subscriber.lastPayment
    final lastPaidMonth = widget.subscriber.lastPayment.year == 2026
        ? widget.subscriber.lastPayment.month
        : 0;
    for (int i = 1; i <= lastPaidMonth; i++) {
      _paidMonths.add(i);
    }
  }

  void _confirmPayment(BuildContext context, int monthNum, String monthName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.payment_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 10),
            Text(
              'تسديد الاشتراك',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
        content: Text(
          'هل تريد تسديد اشتراك شهر $monthName بقيمة ${NumberFormat('#,###').format(widget.subscriber.monthlyAmount)} د.ع؟',
          style: GoogleFonts.cairo(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _paidMonths.add(monthNum);
                final prevPayment = widget.subscriber.lastPayment;
                final newPayment = DateTime(2026, monthNum, 5);
                if (newPayment.isAfter(prevPayment)) {
                  final monthsDiff = ((newPayment.year - prevPayment.year) * 12) + (newPayment.month - prevPayment.month);
                  widget.subscriber.monthsActive += monthsDiff;
                  widget.subscriber.lastPayment = newPayment;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('✓ تم تسديد شهر $monthName بنجاح', style: GoogleFonts.cairo(color: Colors.white)),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('تأكيد التسديد', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Generate months list
    final months = [
      'كانون الثاني (1)',
      'شباط (2)',
      'آذار (3)',
      'نيسان (4)',
      'أيار (5)',
      'حزيران (6)',
      'تموز (7)',
      'آب (8)',
      'أيلول (9)',
      'تشرين الأول (10)',
      'تشرين الثاني (11)',
      'كانون الأول (12)',
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'تفاصيل المشترك',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Section: Premium Profile Card ───────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFEEF2F6), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: Border.all(
                  color: isDark ? const Color(0xFF312E81) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Upper Profile Info with Gradient Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar with glowing ring
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white24,
                          ),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.subscriber.name,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        // Status capsule
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'مشترك نشط',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Metadata Tiles in Grid
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _premiumInfoTile(
                                label: 'الرقم التسلسلي',
                                value: '#${widget.subscriber.id}',
                                icon: Icons.tag_rounded,
                                iconColor: const Color(0xFF6366F1),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _premiumInfoTile(
                                label: 'رقم الهاتف',
                                value: '0770 111 2223',
                                icon: Icons.phone_rounded,
                                iconColor: const Color(0xFF06B6D4),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _premiumInfoTile(
                                label: 'العنوان',
                                value: widget.delegate.area,
                                icon: Icons.location_on_rounded,
                                iconColor: const Color(0xFFEF4444),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _premiumInfoTile(
                                label: 'فئة الاشتراك',
                                value: '${NumberFormat('#,###').format(widget.subscriber.monthlyAmount)} د.ع',
                                icon: Icons.payments_rounded,
                                iconColor: const Color(0xFF10B981),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _premiumInfoTile(
                                label: 'الأشهر المسددة',
                                value: '${_paidMonths.length} شهر',
                                icon: Icons.calendar_month_rounded,
                                iconColor: const Color(0xFFF59E0B),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _premiumInfoTile(
                                label: 'حالة الدفع',
                                value: _dynamicStatusLabel,
                                icon: Icons.info_outline_rounded,
                                iconColor: _dynamicStatusColor,
                                isDark: isDark,
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
            const SizedBox(height: 24),
            
            // ── Second Section: Payments Table Header ────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'جدول الأشهر المسددة لعام 2026',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                // Indicator info
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('غير مسدد', style: GoogleFonts.cairo(fontSize: 10, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Payments List Table
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // Table Header Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'الشهر',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'تاريخ التسديد',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text(
                              'الحالة / الإجراء',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Table Rows with alternating colors
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDark ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.borderLight.withValues(alpha: 0.5),
                      ),
                      itemBuilder: (_, index) {
                        final monthNum = index + 1;
                        final isPaid = _paidMonths.contains(monthNum);
                        final isFuture = monthNum > 3; // current mock month is 3
                        
                        String dateLabel;
                        final rowBgColor = index % 2 == 0
                            ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01))
                            : Colors.transparent;

                        if (isPaid) {
                          dateLabel = '2026/0$monthNum/05';
                        } else {
                          dateLabel = '-';
                        }

                        return Container(
                          color: rowBgColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  months[index],
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  dateLabel,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isPaid) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'مسدد',
                                          style: GoogleFonts.cairo(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      // Unpaid Month State
                                      if (!isFuture) ...[
                                        // Late Alert
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.warning_amber_rounded, size: 10, color: Color(0xFFEF4444)),
                                              const SizedBox(width: 3),
                                              Text(
                                                'متأخر',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFFEF4444),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ] else ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'قادم',
                                            style: GoogleFonts.cairo(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 6),
                                      // Pay Button
                                      GestureDetector(
                                        onTap: () => _confirmPayment(context, monthNum, months[index]),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                                          ),
                                          child: Text(
                                            'تسديد',
                                            style: GoogleFonts.cairo(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  String get _dynamicStatusLabel {
    // Current mock month is 3 (March 2026)
    final unpaidCount = [1, 2, 3].where((m) => !_paidMonths.contains(m)).length;
    if (unpaidCount == 0) return 'مسدد';
    return 'متأخر $unpaidCountش';
  }

  Color get _dynamicStatusColor {
    final unpaidCount = [1, 2, 3].where((m) => !_paidMonths.contains(m)).length;
    if (unpaidCount == 0) return const Color(0xFF10B981);
    if (unpaidCount < 4) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _premiumInfoTile({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
