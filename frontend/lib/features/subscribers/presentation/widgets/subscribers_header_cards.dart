part of '../pages/subscribers_page.dart';

class _PageHeader extends StatelessWidget {
  final bool isDark;
  final int totalFamilies;
  final int eligibleCount;
  final int totalMembers;
  final TextEditingController searchController;
  final FamilyStatus? statusFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<FamilyStatus?> onStatusFilter;
  final VoidCallback onAddFamily;

  const _PageHeader({
    required this.isDark,
    required this.totalFamilies,
    required this.eligibleCount,
    required this.totalMembers,
    required this.searchController,
    required this.statusFilter,
    required this.onSearch,
    required this.onStatusFilter,
    required this.onAddFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات العوائل',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'إدارة ومتابعة بيانات العوائل المستفيدة',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onAddFamily,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPurple,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        'إضافة عائلة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'إجمالي العوائل',
                  value: '$totalFamilies',
                  icon: Icons.home_rounded,
                  gradient: AppColors.gradientPurple,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'العوائل المؤهلة',
                  value: '$eligibleCount',
                  icon: Icons.check_circle_rounded,
                  gradient: AppColors.gradientGreen,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'إجمالي الأفراد',
                  value: '$totalMembers',
                  icon: Icons.people_rounded,
                  gradient: AppColors.gradientBlue,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search + filter row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearch,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'بحث عن عائلة...',
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 13,
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusFilterDropdown(
                value: statusFilter,
                onChanged: onStatusFilter,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  height: 1.1,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Status Filter Dropdown ─────────────────────────────────────────────────────
class _StatusFilterDropdown extends StatelessWidget {
  final FamilyStatus? value;
  final ValueChanged<FamilyStatus?> onChanged;
  final bool isDark;

  const _StatusFilterDropdown({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FamilyStatus?>(
          value: value,
          isDense: true,
          hint: Text(
            'الكل',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          dropdownColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('الكل', style: GoogleFonts.cairo(fontSize: 12)),
            ),
            ...FamilyStatus.values.map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(s.labelAr, style: GoogleFonts.cairo(fontSize: 12)),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Family Card ───────────────────────────────────────────────────────────────
class _FamilyCard extends StatelessWidget {
  final FamilyModel family;
  final bool isDark;
  final bool single;
  final VoidCallback? onView;
  final VoidCallback? onEdit;

  const _FamilyCard({required this.family, required this.isDark, this.single = false, this.onView, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return single ? _buildHorizontal(context) : _buildVertical(context);
  }

  // ── Horizontal card (single column) ──────────────────────────────────────
  Widget _buildHorizontal(BuildContext context) {
    const gradient = LinearGradient(
      colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    );
    const accentColor = Color(0xFF6D28D9);
    final rating = _familyRating(family.incomeLevel);
    final ratingColor = _ratingColor(family.incomeLevel);
    final occupation = _occupation(family);
    final initials = _initials();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: isDark ? 0.25 : 0.14)),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: isDark ? 0.18 : 0.1),
              blurRadius: 14, spreadRadius: -3, offset: const Offset(0, 6)),
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left gradient panel ──────────────────────────────────
              Container(
                width: 88,
                decoration: const BoxDecoration(gradient: gradient),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.25),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2),
                      ),
                      child: Center(child: Text(initials,
                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white))),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ratingColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: Text(rating, style: GoogleFonts.cairo(
                          fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ],
                ),
              ),

              // ── Right content ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + status chip
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(family.headName,
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 6),
                          _StatusChipWidget(status: family.status),
                        ],
                      ),
                    ),

                    // Info grid 2-per-row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          Row(children: [
                            Expanded(child: _InfoChip(icon: Icons.calendar_today_rounded,
                                text: DateFormat('dd/MM/yy').format(family.registrationDate), isDark: isDark)),
                            Expanded(child: _InfoChip(icon: Icons.people_rounded,
                                text: '${family.membersCount} أفراد', isDark: isDark)),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            Expanded(child: _InfoChip(icon: Icons.location_on_rounded,
                                text: family.area, isDark: isDark)),
                            Expanded(child: _InfoChip(icon: Icons.work_rounded,
                                text: occupation, isDark: isDark)),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            Expanded(child: _InfoChip(icon: Icons.person_outline_rounded,
                                text: 'المندوب: ${family.delegateName ?? "غير محدد"}', isDark: isDark)),
                          ]),
                          const SizedBox(height: 6),
                          _InfoChip(icon: Icons.volunteer_activism_rounded,
                              text: 'إجمالي المساعدات: ${_formatAmount(family.totalAidAmount)}',
                              isDark: isDark, valueColor: AppColors.success, fullWidth: true),
                        ],
                      ),
                    ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 12, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _ActionBtn(icon: Icons.visibility_rounded, color: AppColors.info, onTap: onView),
                          const SizedBox(width: 8),
                          _ActionBtn(icon: Icons.edit_rounded, color: AppColors.success, onTap: onEdit),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Vertical card (multi-column grid) ────────────────────────────────────
  Widget _buildVertical(BuildContext context) {
    const gradient = LinearGradient(
      colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    );
    const accentColor = Color(0xFF6D28D9);
    final rating = _familyRating(family.incomeLevel);
    final ratingColor = _ratingColor(family.incomeLevel);
    final initials = _initials();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12)),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
              blurRadius: 14, spreadRadius: -4, offset: const Offset(0, 6)),
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header
            Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              decoration: const BoxDecoration(gradient: gradient),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
                  ),
                  child: Center(child: Text(initials,
                      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white))),
                ),
                const SizedBox(width: 9),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(family.headName,
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ratingColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(rating, style: GoogleFonts.cairo(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ])),
              ]),
            ),

            // Body
            Expanded(child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _CardInfoRow(icon: Icons.calendar_today_rounded,
                    text: DateFormat('dd/MM/yyyy').format(family.registrationDate), isDark: isDark),
                const SizedBox(height: 7),
                _CardInfoRow(icon: Icons.people_rounded,
                    text: '${family.membersCount} أفراد', isDark: isDark),
                const SizedBox(height: 7),
                _CardInfoRow(icon: Icons.location_on_rounded,
                    text: family.area, isDark: isDark),
                const SizedBox(height: 7),
                _CardInfoRow(icon: Icons.person_outline_rounded,
                    text: family.delegateName ?? 'غير محدد', isDark: isDark, label: 'المندوب'),
                const SizedBox(height: 7),
                _CardInfoRow(icon: Icons.volunteer_activism_rounded,
                    text: _formatAmount(family.totalAidAmount),
                    isDark: isDark, label: 'المساعدات', valueColor: AppColors.success),
              ]),
            )),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusChipWidget(status: family.status),
                  Row(children: [
                    _ActionBtn(icon: Icons.visibility_rounded, color: AppColors.info, onTap: onView),
                    const SizedBox(width: 6),
                    _ActionBtn(icon: Icons.edit_rounded, color: AppColors.success, onTap: onEdit),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials() => family.headName.trim().split(' ').take(2)
      .map((w) => w.isNotEmpty ? w[0] : '').join();

  String _formatAmount(double amount) {
    if (amount == 0) return 'لا يوجد';
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)} م.د';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K د.ع';
    return '${amount.toStringAsFixed(0)} د.ع';
  }
}

// ── Card Info Row ──────────────────────────────────────────────────────────────
class _CardInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final String? label;
  final Color? valueColor;

  const _CardInfoRow({
    required this.icon,
    required this.text,
    required this.isDark,
    this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 13,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: GoogleFonts.cairo(
                    fontSize: 9,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  ),
                ),
              Text(
                text,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: valueColor ??
                      (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info Chip (used in horizontal card) ───────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final Color? valueColor;
  final bool fullWidth;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.isDark,
    this.valueColor,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = valueColor ??
        (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    final iconColor = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    return Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Status Chip ───────────────────────────────────────────────────────────────
class _StatusChipWidget extends StatelessWidget {
  final FamilyStatus status;

  const _StatusChipWidget({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (status) {
      case FamilyStatus.eligible:
        bg = AppColors.statusActiveBg;
        text = AppColors.statusActiveText;
        break;
      case FamilyStatus.ineligible:
        bg = AppColors.statusRejectedBg;
        text = AppColors.statusRejectedText;
        break;
      case FamilyStatus.pending:
        bg = AppColors.statusPendingBg;
        text = AppColors.statusPendingText;
        break;
      case FamilyStatus.suspended:
        bg = AppColors.statusInactiveBg;
        text = AppColors.statusInactiveText;
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      bg = bg.withValues(alpha: 0.15);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.labelAr,
        style: GoogleFonts.cairo(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
