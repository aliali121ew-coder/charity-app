part of '../pages/location_step_page.dart';

class _LocationBottomCard extends StatelessWidget {
  final String governorate;
  final String area;
  final String address;
  final LatLng coordinates;
  final bool isLoading;
  final bool isDark;
  final bool isRouteMode;
  final bool showTraffic;
  final double distanceKm;
  final int etaMinutes;
  final VoidCallback onManual;
  final VoidCallback onConfirm;
  final VoidCallback onToggleRouteMode;
  final VoidCallback onToggleTraffic;

  const _LocationBottomCard({
    required this.governorate,
    required this.area,
    required this.address,
    required this.coordinates,
    required this.isLoading,
    required this.isDark,
    required this.isRouteMode,
    required this.showTraffic,
    required this.distanceKm,
    required this.etaMinutes,
    required this.onManual,
    required this.onConfirm,
    required this.onToggleRouteMode,
    required this.onToggleTraffic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // ── شريط الخيارات السريعة: تتبع المسار وحركة المرور ──────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                InkWell(
                  onTap: onToggleRouteMode,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isRouteMode
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : (isDark
                              ? AppColors.cardDark
                              : AppColors.backgroundLight),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isRouteMode
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alt_route_rounded,
                          size: 14,
                          color: isRouteMode
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isRouteMode ? 'وضع رسم المسار (مفعّل)' : 'رسم المسار المباشر',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isRouteMode
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onToggleTraffic,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: showTraffic
                          ? AppColors.secondary.withValues(alpha: 0.15)
                          : (isDark
                              ? AppColors.cardDark
                              : AppColors.backgroundLight),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: showTraffic
                            ? AppColors.secondary
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.traffic_rounded,
                          size: 14,
                          color: showTraffic
                              ? AppColors.secondary
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          showTraffic ? 'المرور الحي (مفعّل)' : 'حركة المرور الحية',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: showTraffic
                                ? AppColors.secondary
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── شريط مؤشرات المسافة والوقت المتبقي عند تفعيل وضع المسار ────────────────
          if (isRouteMode && distanceKm > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.secondary.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'الوقت المتوقع: $etaMinutes دقيقة',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  Container(
                      width: 1,
                      height: 16,
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight),
                  Row(
                    children: [
                      const Icon(Icons.navigation_outlined,
                          size: 16, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Text(
                        'المسافة: $distanceKm كم',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // صف المعلومات
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: isRouteMode
                      ? AppColors.gradientGreen
                      : AppColors.gradientPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isRouteMode ? Icons.near_me_rounded : Icons.location_on_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isLoading
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ShimmerLine(width: 120, isDark: isDark),
                          const SizedBox(height: 5),
                          _ShimmerLine(width: 180, isDark: isDark),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$governorate — $area',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            address,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: AppColors.primary
                                  .withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // صف الأزرار
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManual,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.edit_location_alt_outlined,
                      size: 16, color: AppColors.primary),
                  label: Text(
                    'إدخال يدوي',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPurple,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: isLoading ? null : onConfirm,
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'تأكيد الموقع',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  final double width;
  final bool isDark;
  const _ShimmerLine({required this.width, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

// ── Manual Entry Bottom Sheet ─────────────────────────────────────────────────

class _ManualEntrySheet extends StatefulWidget {
  final String initialGov;
  final String initialArea;
  final String initialAddress;
  final void Function(String gov, String area, String address) onConfirm;

  const _ManualEntrySheet({
    required this.initialGov,
    required this.initialArea,
    required this.initialAddress,
    required this.onConfirm,
  });

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  late String _selectedGov;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _selectedGov = _iraqiGovernorates.contains(widget.initialGov)
        ? widget.initialGov
        : 'بغداد';
    _areaCtrl = TextEditingController(text: widget.initialArea);
    _addressCtrl = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding:
          EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPad),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPurple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'إدخال الموقع يدوياً',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'المحافظة',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGov,
                isExpanded: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                dropdownColor:
                    isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                onChanged: (v) =>
                    setState(() => _selectedGov = v ?? _selectedGov),
                items: _iraqiGovernorates
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g,
                              style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight)),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _areaCtrl,
            label: 'المنطقة / الحي',
            hint: 'مثال: الكرخ، المنصور',
            icon: Icons.map_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _addressCtrl,
            label: 'العنوان التفصيلي',
            hint: 'الشارع، رقم البيت، أقرب معلم...',
            icon: Icons.home_outlined,
            isDark: isDark,
            maxLines: 2,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.gradientPurple,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () {
                  final area = _areaCtrl.text.trim();
                  final addr = _addressCtrl.text.trim();
                  if (area.isEmpty) return;
                  widget.onConfirm(_selectedGov, area, addr);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'تأكيد الموقع',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.cairo(
              fontSize: 13,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(
                fontSize: 12,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight),
            prefixIcon: maxLines == 1
                ? Icon(icon,
                    size: 18,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight)
                : null,
            filled: true,
            fillColor: isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
