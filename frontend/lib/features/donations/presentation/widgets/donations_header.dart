part of '../pages/donations_page.dart';

class _AnimatedCounter extends AnimatedWidget {
  final double end;
  final TextStyle style;
  final String suffix;

  const _AnimatedCounter({
    required Animation<double> animation,
    required this.end,
    required this.style,
    this.suffix = '',
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final anim = listenable as Animation<double>;
    final value = (anim.value * end).toInt();
    return Text(
      '${NumberFormat('#,###').format(value)}$suffix',
      style: style,
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DonationHeader extends StatelessWidget {
  final bool isDark;
  final double totalDonated;
  final int donorsCount, pendingCount, transfersCount;
  final Animation<double> counterAnim;

  const _DonationHeader({
    required this.isDark,
    required this.totalDonated,
    required this.donorsCount,
    required this.pendingCount,
    required this.counterAnim,
    required this.transfersCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
            bottom: BorderSide(
                color:
                    isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1C1C3A),
                  Color(0xFF3D2B8E),
                  Color(0xFF0D6E5A)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color(0xFF3D2B8E).withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned(
                    right: -25,
                    top: -25,
                    child: _Bubble(size: 120, alpha: 0.07)),
                const Positioned(
                    right: 50,
                    bottom: -15,
                    child: _Bubble(size: 80, alpha: 0.05)),
                const Positioned(
                    left: -15,
                    bottom: -10,
                    child: _Bubble(size: 70, alpha: 0.06)),
                const Positioned(
                    left: 80,
                    top: 10,
                    child: _Bubble(size: 40, alpha: 0.08)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.volunteer_activism_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'إجمالي التبرعات',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: Colors.white
                                      .withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 14),
                            _AnimatedCounter(
                              animation: counterAnim,
                              end: totalDonated,
                              suffix: ' د.ع',
                              style: GoogleFonts.cairo(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedBuilder(
                              animation: counterAnim,
                              builder: (_, __) => Text(
                                '≈ \$${NumberFormat('#,###').format((counterAnim.value * totalDonated / 1300).toInt())} USD',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.white
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الهدف الشهري: 15,000,000 د.ع',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: Colors.white
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(4),
                                  child: AnimatedBuilder(
                                    animation: counterAnim,
                                    builder: (_, __) =>
                                        LinearProgressIndicator(
                                      value: counterAnim.value *
                                          (totalDonated / 15000000)
                                              .clamp(0.0, 1.0),
                                      backgroundColor: Colors.white
                                          .withValues(alpha: 0.15),
                                      valueColor:
                                          const AlwaysStoppedAnimation<
                                                  Color>(
                                              Color(0xFF00C9A7)),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(children: [
                        _MiniStatCard(
                          label: 'متبرع',
                          value: donorsCount.toString(),
                          icon: Icons.people_rounded,
                          anim: counterAnim,
                        ),
                        const SizedBox(height: 10),
                        _MiniStatCard(
                          label: 'معالجة',
                          value: pendingCount.toString(),
                          icon: Icons.pending_rounded,
                          anim: counterAnim,
                        ),
                        const SizedBox(height: 10),
                        _MiniStatCard(
                          label: 'عملية',
                          value: '$transfersCount',
                          icon: Icons.receipt_long_rounded,
                          anim: counterAnim,
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _StatChip(
                  label: 'هذا الشهر',
                  value: '8.8M',
                  color: AppColors.primary,
                  anim: counterAnim),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'الأسبوع',
                  value: '2.4M',
                  color: AppColors.success,
                  anim: counterAnim),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'اليوم',
                  value: '750K',
                  color: AppColors.orange,
                  anim: counterAnim),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'متبرعون جدد',
                  value: '+3',
                  color: AppColors.info,
                  anim: counterAnim),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size, alpha;
  const _Bubble({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}

class _MiniStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Animation<double> anim;

  const _MiniStatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.anim});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.7))),
        ]),
      );
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final Animation<double> anim;

  const _StatChip(
      {required this.label,
      required this.value,
      required this.color,
      required this.anim});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.8))),
          ]),
    );
  }
}

// ── Donate Now Tab ────────────────────────────────────────────────────────────

