part of '../pages/subscribers_page.dart';

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom_rounded,
            size: 64,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد عوائل',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'لم يتم العثور على نتائج مطابقة',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Family View Sheet ─────────────────────────────────────────────────────────
class _FamilyViewSheet extends StatelessWidget {
  final FamilyModel family;
  final bool isDark;
  const _FamilyViewSheet({required this.family, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rating = _familyRating(family.incomeLevel);
    final ratingColor = _ratingColor(family.incomeLevel);
    final statusColor = _statusHeaderColor(family.status);
    final initials = family.headName.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
    const cardGradient = LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Handle
          Center(child: Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
              decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: cardGradient, borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    // Avatar
                    Container(width: 72, height: 72,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2)),
                      child: Center(child: Text(initials, style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white))),
                    ),
                    const SizedBox(height: 12),
                    Text(family.headName, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      // Status
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                        child: Text(family.status.labelAr, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      // Rating
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: ratingColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                        child: Text('تقييم: $rating', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Quick stats
                    Row(children: [
                      Expanded(child: _ViewStat(label: 'عدد الأفراد', value: '${family.membersCount}', icon: Icons.people_rounded)),
                      Expanded(child: _ViewStat(label: 'المساعدات', value: '${family.aidCount}', icon: Icons.volunteer_activism_rounded)),
                      Expanded(child: _ViewStat(label: 'إجمالي الصرف', value: family.totalAidAmount >= 1000 ? '${(family.totalAidAmount/1000).toStringAsFixed(0)}K' : '${family.totalAidAmount.toStringAsFixed(0)}', icon: Icons.payments_rounded)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),

                // Section: بيانات أساسية
                _ViewSection(title: 'البيانات الأساسية', isDark: isDark, children: [
                  _ViewRow(icon: Icons.location_on_rounded, label: 'المنطقة', value: family.area, isDark: isDark),
                  _ViewRow(icon: Icons.home_rounded, label: 'العنوان التفصيلي', value: family.address, isDark: isDark),
                  _ViewRow(icon: Icons.person_outline_rounded, label: 'المندوب المسؤول', value: family.delegateName ?? 'غير محدد', isDark: isDark),
                  if (family.phone != null)
                    _ViewRow(icon: Icons.phone_rounded, label: 'رقم الهاتف', value: family.phone!, isDark: isDark),
                  _ViewRow(icon: Icons.calendar_today_rounded, label: 'تاريخ التسجيل', value: DateFormat('dd/MM/yyyy').format(family.registrationDate), isDark: isDark),
                ]),
                const SizedBox(height: 14),

                // Section: الحالة الاجتماعية
                _ViewSection(title: 'الحالة الاجتماعية والمالية', isDark: isDark, children: [
                  _ViewRow(icon: Icons.favorite_rounded, label: 'الحالة الاجتماعية', value: family.maritalStatus.labelAr, isDark: isDark),
                  _ViewRow(icon: Icons.trending_up_rounded, label: 'مستوى الدخل', value: family.incomeLevel.labelAr, isDark: isDark),
                  _ViewRow(icon: Icons.work_rounded, label: 'طبيعة العمل', value: _occupation(family), isDark: isDark),
                ]),
                const SizedBox(height: 14),

                // Notes
                if (family.notes != null && family.notes!.isNotEmpty) ...[
                  _ViewSection(title: 'ملاحظات', isDark: isDark, children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(family.notes!, style: GoogleFonts.cairo(fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ),
                  ]),
                ],
              ]),
            ),
          ),
          // Close button
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(backgroundColor: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('إغلاق', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ViewStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _ViewStat({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.85)),
    const SizedBox(height: 4),
    Text(value, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
    Text(label, style: GoogleFonts.cairo(fontSize: 9, color: Colors.white.withValues(alpha: 0.7))),
  ]);
}

class _ViewSection extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget> children;
  const _ViewSection({required this.title, required this.isDark, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Text(title, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight))),
      Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
      Padding(padding: const EdgeInsets.all(14), child: Column(children: children)),
    ]),
  );
}

class _ViewRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isDark;
  const _ViewRow({required this.icon, required this.label, required this.value, required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF6D28D9).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: const Color(0xFF6D28D9))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 10, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)),
        Text(value, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
      ])),
    ]),
  );
}

// ── Family Edit Sheet ─────────────────────────────────────────────────────────
