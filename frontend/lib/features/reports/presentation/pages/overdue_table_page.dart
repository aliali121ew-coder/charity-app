import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/families/presentation/pages/families_page.dart'; // to get getLateSubscribersData()
import 'package:charity_app/features/families/presentation/pages/analysis_pdf_page.dart';
import 'package:charity_app/features/subscribers/data/mock_subscribers_repository.dart';

part '../widgets/overdue_kpi_card.dart';

class OverdueTablePage extends StatefulWidget {
  const OverdueTablePage({super.key});

  @override
  State<OverdueTablePage> createState() => _OverdueTablePageState();
}

class _OverdueTablePageState extends State<OverdueTablePage> {
  String _searchQuery = '';
  String? _selectedDelegate;
  int? _selectedMonthsFilter; // null = All, 1 = 1 month, 2 = 2 months, 3 = 3+ months

  final List<Map<String, dynamic>> _allData = getLateSubscribersData();

  String _getDelegatePhone(String delegateName) {
    switch (delegateName) {
      case 'أحمد محمد الكريمي': return '07701234567';
      case 'سارة علي الموسوي': return '07702345678';
      case 'حسين رضا الجبوري': return '07703456789';
      case 'نور محمد الهاشمي': return '07704567890';
      case 'علاء الدين فارس': return '07705678901';
      case 'ريم سعد العلي': return '07706789012';
      default: return 'غير متوفر';
    }
  }

  String _getSubscriberPhone(String name) {
    try {
      return mockSubscribers.firstWhere((s) => s.name == name).phone;
    } catch (_) {
      return 'غير متوفر';
    }
  }

  Widget _verticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 20,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }



  String _formatMonthsRange(List<int> months) {
    if (months.isEmpty) return '';
    if (months.length == 1) {
      return '2026-${months.first}-1';
    }
    return '2026-${months.first}-1 - 2026-${months.last}-1';
  }

  List<Map<String, dynamic>> get _filteredData {
    return _allData.where((item) {
      final name = (item['subscriberName'] as String).toLowerCase();
      final delegate = (item['delegateName'] as String).toLowerCase();
      final unpaid = item['unpaidMonths'] as List<int>;
      final query = _searchQuery.toLowerCase();

      final matchesSearch = name.contains(query) || delegate.contains(query);

      final matchesDelegate = _selectedDelegate == null || item['delegateName'] == _selectedDelegate;

      bool matchesMonths = true;
      if (_selectedMonthsFilter != null) {
        if (_selectedMonthsFilter == 1) {
          matchesMonths = unpaid.length == 1;
        } else if (_selectedMonthsFilter == 2) {
          matchesMonths = unpaid.length == 2;
        } else if (_selectedMonthsFilter == 3) {
          matchesMonths = unpaid.length >= 3;
        }
      }

      return matchesSearch && matchesDelegate && matchesMonths;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredData;

    // Calculate metrics
    final totalLateCount = filtered.length;
    final totalAmountLate = filtered.fold<double>(
      0.0,
      (sum, item) => sum + ((item['monthlyAmount'] as double) * (item['unpaidMonths'] as List<int>).length),
    );
    final avgMonthsLate = totalLateCount == 0
        ? 0.0
        : filtered.fold<int>(0, (sum, item) => sum + (item['unpaidMonths'] as List<int>).length) / totalLateCount;

    // Get unique delegates for the filter dropdown
    final delegates = _allData.map((e) => e['delegateName'] as String).toSet().toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تقرير المتأخرين عن السداد',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            tooltip: 'تصدير PDF / معاينة الطباعة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalysisPdfPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Title Block ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'قائمة المتلكئين عن السداد لعام 2026',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          'عرض وتحليل البيانات المالية للمشتركين المتأخرين',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AnalysisPdfPage()),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.white),
                    label: Text(
                      'تصدير PDF',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── KPI Summary Cards ────────────────────────────────────────
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _KpiCard(
                        title: 'إجمالي المتأخرين',
                        value: '$totalLateCount مشترك',
                        icon: Icons.people_outline_rounded,
                        gradient: AppColors.gradientRed,
                        glowColor: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        title: 'إجمالي المتأخرات',
                        value: '${NumberFormat('#,###').format(totalAmountLate)} د.ع',
                        icon: Icons.account_balance_wallet_outlined,
                        gradient: AppColors.gradientPurple,
                        glowColor: const Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        title: 'معدل التأخير',
                        value: '${avgMonthsLate.toStringAsFixed(1)} شهر',
                        icon: Icons.hourglass_empty_rounded,
                        gradient: AppColors.gradientOrange,
                        glowColor: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Filters Section ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: GoogleFonts.cairo(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'البحث عن مشترك أو مندوب...',
                        hintStyle: GoogleFonts.cairo(
                          fontSize: 12.5,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter dropdowns
                    Row(
                      children: [
                        // Delegate Filter
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _selectedDelegate,
                                hint: Text(
                                  'تصفية حسب المندوب',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                                items: [
                                  DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('جميع المندوبين', style: GoogleFonts.cairo(fontSize: 12)),
                                  ),
                                  ...delegates.map(
                                    (d) => DropdownMenuItem<String?>(
                                      value: d,
                                      child: Text(d, style: GoogleFonts.cairo(fontSize: 12)),
                                    ),
                                  ),
                                ],
                                onChanged: (v) => setState(() => _selectedDelegate = v),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Severity / Months Filter
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int?>(
                                value: _selectedMonthsFilter,
                                hint: Text(
                                  'تصفية حسب شدة التأخير',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                                items: [
                                  DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('جميع الحالات', style: GoogleFonts.cairo(fontSize: 12)),
                                  ),
                                  DropdownMenuItem<int?>(
                                    value: 1,
                                    child: Text('متأخر شهر واحد', style: GoogleFonts.cairo(fontSize: 12)),
                                  ),
                                  DropdownMenuItem<int?>(
                                    value: 2,
                                    child: Text('متأخر شهرين', style: GoogleFonts.cairo(fontSize: 12)),
                                  ),
                                  DropdownMenuItem<int?>(
                                    value: 3,
                                    child: Text('متأخر 3 أشهر أو أكثر', style: GoogleFonts.cairo(fontSize: 12)),
                                  ),
                                ],
                                onChanged: (v) => setState(() => _selectedMonthsFilter = v),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Data Table ───────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 700,
                      child: Column(
                        children: [
                          // Table header row
                          Container(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '#',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                _verticalDivider(isDark),
                                SizedBox(
                                  width: 140,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'المشترك',
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                _verticalDivider(isDark),
                                SizedBox(
                                  width: 140,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'المندوب',
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                _verticalDivider(isDark),
                                SizedBox(
                                  width: 100,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'فئة الاشتراك',
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                _verticalDivider(isDark),
                                SizedBox(
                                  width: 180,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'أشهر التأخير (2026)',
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                _verticalDivider(isDark),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    'عمل',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),

                          // Empty state inside table
                          if (filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Column(
                                children: [
                                  Icon(Icons.person_off_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'لم يتم العثور على أي نتائج مطابقة للتصفية',
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            // Table content
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final seq = index + 1;
                                final unpaidMonths = item['unpaidMonths'] as List<int>;
                                final severityColor = _getSeverityColor(unpaidMonths.length);

                                final isEven = index % 2 == 0;
                                final rowBg = isEven
                                    ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                    : (isDark ? const Color(0xFF151D2A) : const Color(0xFFF8FAFC));

                                return Container(
                                  color: rowBg,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 16),
                                      // Seq No.
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '$seq',
                                          style: GoogleFonts.cairo(
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      _verticalDivider(isDark),

                                      // Subscriber Name
                                      SizedBox(
                                        width: 140,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            item['subscriberName'],
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      _verticalDivider(isDark),

                                      // Delegate
                                      SizedBox(
                                        width: 140,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 10,
                                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                                child: Text(
                                                  (item['delegateName'] as String).substring(0, 1),
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  item['delegateName'],
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      _verticalDivider(isDark),

                                      // Subscription Fee
                                      SizedBox(
                                        width: 100,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            '${NumberFormat('#,###').format(item['monthlyAmount'])} د.ع',
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      _verticalDivider(isDark),

                                      // Overdue Months
                                      SizedBox(
                                        width: 180,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: severityColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: severityColor.withValues(alpha: 0.3),
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  _formatMonthsRange(unpaidMonths),
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: severityColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      _verticalDivider(isDark),

                                      // Action
                                      SizedBox(
                                        width: 60,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.info_outline_rounded, size: 16),
                                              color: AppColors.primary,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                _showDetailDialog(context, item);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(int monthsCount) {
    if (monthsCount == 1) return const Color(0xFFF59E0B); // Orange / Warning
    if (monthsCount == 2) return const Color(0xFFE11D48); // Rose
    return const Color(0xFFEF4444); // Red / Critical
  }



  void _showDetailDialog(BuildContext context, Map<String, dynamic> item) {
    final unpaid = item['unpaidMonths'] as List<int>;
    final totalAmount = (item['monthlyAmount'] as double) * unpaid.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subPhone = _getSubscriberPhone(item['subscriberName']);
    final delPhone = _getDelegatePhone(item['delegateName']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'تفاصيل المتأخرات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogDetailRow('المشترك:', item['subscriberName'] as String, subPhone, isDark),
            const SizedBox(height: 8),
            _dialogDetailRow('المندوب المسؤول:', item['delegateName'] as String, delPhone, isDark),
            const SizedBox(height: 8),
            _dialogDetailRow('القسط الشهري:', '${NumberFormat('#,###').format(item['monthlyAmount'])} د.ع', null, isDark),
            const SizedBox(height: 8),
            _dialogDetailRow('عدد أشهر التأخر:', '${unpaid.length} أشهر', null, isDark),
            const SizedBox(height: 8),
            _dialogDetailRow(
              'الأشهر المتأخرة:',
              _formatMonthsRange(unpaid),
              null,
              isDark,
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المبلغ المتأخر الكلي:',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(totalAmount)} د.ع',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إغلاق',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogDetailRow(String label, String value, String? phone, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
        if (phone != null && phone != 'غير متوفر') ...[
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.phone_iphone_rounded, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'الهاتف: $phone',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

