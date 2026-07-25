part of '../pages/donations_page.dart';

class _CreditCard extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;

  const _CreditCard(
      {required this.method, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 180,
      decoration: BoxDecoration(
        gradient: method.cardGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: method.accentColor
                .withValues(alpha: isSelected ? 0.5 : 0.2),
            blurRadius: isSelected ? 28 : 12,
            spreadRadius: isSelected ? -2 : -6,
            offset: Offset(0, isSelected ? 12 : 6),
          ),
          BoxShadow(
            color: Colors.black
                .withValues(alpha: isSelected ? 0.4 : 0.2),
            blurRadius: 16,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ],
        border: isSelected
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5)
            : null,
      ),
      child: Stack(children: [
        const Positioned(
            right: -30,
            top: -30,
            child: _Bubble(size: 140, alpha: 0.07)),
        const Positioned(
            left: -20,
            bottom: -20,
            child: _Bubble(size: 100, alpha: 0.05)),
        const Positioned(
            right: 40,
            bottom: 10,
            child: _Bubble(size: 60, alpha: 0.06)),
        Positioned(
          left: 24,
          top: 24,
          child: Container(
            width: 42,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade300,
                  Colors.amber.shade600
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: CustomPaint(painter: _ChipPainter()),
          ),
        ),
        if (isSelected)
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 11),
                const SizedBox(width: 4),
                Text('محدد',
                    style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.number,
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      color:
                          Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('طريقة الدفع',
                                style: GoogleFonts.cairo(
                                    fontSize: 9,
                                    color: Colors.white
                                        .withValues(alpha: 0.6))),
                            Text(method.labelAr,
                                style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ]),
                      Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text('الصلاحية',
                                style: GoogleFonts.cairo(
                                    fontSize: 9,
                                    color: Colors.white
                                        .withValues(alpha: 0.6))),
                            Text(method.expiry,
                                style: GoogleFonts.robotoMono(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ]),
                    ],
                  ),
                ]),
          ),
        ),
        Positioned(
            right: 16,
            bottom: 18,
            child: _CardLogo(method: method)),
      ]),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.shade800.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        paint);
    canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint);
    canvas.drawLine(
        const Offset(0, 0),
        Offset(size.width / 2, size.height / 2),
        paint);
    canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width / 2, size.height / 2),
        paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CardLogo extends StatelessWidget {
  final PaymentMethod method;
  const _CardLogo({required this.method});

  @override
  Widget build(BuildContext context) {
    switch (method) {
      case PaymentMethod.visaCard:
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6)),
          child: Text('VISA',
              style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1F71),
                  letterSpacing: 1)),
        );
      case PaymentMethod.masterCard:
        return SizedBox(
            width: 40,
            height: 26,
            child: Stack(children: [
              Positioned(
                  left: 0,
                  child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xCCEB001B)))),
              Positioned(
                  right: 0,
                  child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xCCF79E1B)))),
            ]));
      case PaymentMethod.zainCash:
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Text('ZAIN',
              style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Method Info Card ──────────────────────────────────────────────────────────

class _MethodInfoCard extends StatelessWidget {
  final PaymentMethod method;
  final bool isDark;

  const _MethodInfoCard(
      {required this.method, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, instructions) = _getDetails(method);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                  .animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(method),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: method.accentColor
              .withValues(alpha: isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: method.accentColor.withValues(alpha: 0.3)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: method.accentColor
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(method.icon,
                      color: method.accentColor, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight)),
                      Text(subtitle,
                          style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight)),
                    ]),
              ]),
              const SizedBox(height: 12),
              ...instructions.map((ins) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(
                                top: 6, left: 8, right: 2),
                            decoration: BoxDecoration(
                                color: method.accentColor,
                                shape: BoxShape.circle),
                          ),
                          Expanded(
                              child: Text(ins,
                                  style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors
                                              .textSecondaryDark
                                          : AppColors
                                              .textSecondaryLight,
                                      height: 1.5))),
                        ]),
                  )),
            ]),
      ),
    );
  }

  (String, String, List<String>) _getDetails(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.zainCash:
        return ('زين كاش', 'المحفظة الإلكترونية', [
          'رقم المحفظة: 0781-884-712',
          'ستصلك رسالة تأكيد فورية',
          'عمولة: 0.5% من قيمة التبرع'
        ]);
      case PaymentMethod.visaCard:
        return ('Visa Card', 'بطاقة فيزا', [
          'مدعوم ببطاقات البنوك العراقية',
          'تشفير SSL 256-bit',
          'عمولة: 1.5% من قيمة التبرع'
        ]);
      case PaymentMethod.masterCard:
        return ('MasterCard', 'بطاقة ماستركارد', [
          'يدعم MasterCard & Maestro',
          'حماية 3D Secure',
          'عمولة: 1.5% من قيمة التبرع'
        ]);
      case PaymentMethod.bankTransfer:
        return ('تحويل بنكي', 'التحويل المباشر', [
          'اسم المستفيد: جمعية الخير الخيرية',
          'IBAN: IQ72NBIQ000000020001',
          'أرسل الإيصال بعد التحويل'
        ]);
      case PaymentMethod.cash:
        return ('نقداً', 'التسليم المباشر', [
          'العنوان: بغداد – الكرادة، ش 14 رمضان',
          'ساعات العمل: 9 ص – 5 م',
          'يُمنح إيصال رسمي فور الاستلام'
        ]);
    }
  }
}

// ── Quick Amounts ─────────────────────────────────────────────────────────────

