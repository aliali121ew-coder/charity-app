import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/shared/models/subscriber_model.dart';
import 'package:charity_app/features/subscribers/data/supabase_subscribers_repository.dart';

part '../widgets/families_widgets.dart';
part '../widgets/families_sheets.dart';
part '../widgets/subscriber_detail.dart';

// ── Supabase → _Delegate/_Subscriber mapping ──────────────────────────────────
// Groups a flat list of SubscriberModel (from Supabase) into the private
// _Delegate/_Subscriber shapes that the existing widgets consume, WITHOUT
// touching those classes or their getters. See fields not present in the data
// (phone/specialty/joinDate/address/monthsActive) which get faithful placeholders.
List<_Delegate> _buildDelegatesFromModels(List<SubscriberModel> models) {
  // Preserve first-seen order of delegate names so colorIndex stays stable.
  final Map<String, List<SubscriberModel>> grouped = {};
  for (final m in models) {
    final key = (m.delegate == null || m.delegate!.isEmpty) ? 'غير محدد' : m.delegate!;
    grouped.putIfAbsent(key, () => []).add(m);
  }

  final List<_Delegate> delegates = [];
  var n = 0;
  grouped.forEach((delegateName, subs) {
    n++;
    // Most common area among this delegate's subscribers (fallback: first).
    final Map<String, int> areaCounts = {};
    for (final s in subs) {
      if (s.area.isNotEmpty) {
        areaCounts[s.area] = (areaCounts[s.area] ?? 0) + 1;
      }
    }
    String area = subs.isNotEmpty ? subs.first.area : '';
    var best = -1;
    areaCounts.forEach((a, c) {
      if (c > best) {
        best = c;
        area = a;
      }
    });

    delegates.add(
      _Delegate(
        id: 'd$n',
        name: delegateName,
        area: area,
        phone: '',
        isFemale: false,
        specialty: 'مندوب',
        joinDate: DateTime(2024, 1, 1),
        address: '',
        subscribers: subs.map(_subscriberFromModel).toList(),
      ),
    );
  });
  return delegates;
}

// Maps a single SubscriberModel to _Subscriber. `lastPayment` is synthesized so
// that the EXISTING _Subscriber.monthsLate getter (which measures against
// month 3 / 2026) returns exactly s.overdueMonths. e.g. overdueMonths=3 →
// DateTime(2026, 0, 1) → Dec 2025 → (2026-2025)*12 + (3-12) = 3.
_Subscriber _subscriberFromModel(SubscriberModel s) => _Subscriber(
      id: s.id,
      name: s.name,
      monthsActive: 12, // not present in data; constant placeholder.
      lastPayment: DateTime(2026, 3 - s.overdueMonths, 1),
      monthlyAmount: s.subscriptionAmount,
    );

// Async variant of getLateSubscribersData() backed by real Supabase data.
// Returns the SAME List<Map> shape (delegateName / subscriberName /
// monthlyAmount / unpaidMonths) used by overdue_table_page + analysis PDF.
// unpaidMonths is the last `overdueMonths` month-numbers ending at 3
// (e.g. overdueMonths=2 → [2, 3]); subscribers with overdueMonths=0 are skipped.
Future<List<Map<String, dynamic>>> fetchLateSubscribersData() async {
  final models = await SupabaseSubscribersRepository().getAll();
  final delegates = _buildDelegatesFromModels(models);
  return getLateSubscribersData(delegates);
}

// Builds the late-subscribers rows from a given list of delegates (same logic
// as the legacy no-arg reader below, parameterized so callers can pass real
// grouped data). Kept private-typed since _Delegate is library-private.
List<Map<String, dynamic>> _lateSubscribersFrom(List<_Delegate> delegates) {
  final List<Map<String, dynamic>> list = [];
  for (final delegate in delegates) {
    for (final subscriber in delegate.subscribers) {
      const now = 3; // March 2026 = month 3
      final List<int> unpaid = [];
      final lastPaid = subscriber.lastPayment;
      final startMonth = lastPaid.year == 2026 ? lastPaid.month + 1 : 1;
      for (int m = startMonth; m <= now; m++) {
        unpaid.add(m);
      }
      if (unpaid.isNotEmpty) {
        list.add({
          'delegateName': delegate.name,
          'subscriberName': subscriber.name,
          'monthlyAmount': subscriber.monthlyAmount,
          'unpaidMonths': unpaid,
        });
      }
    }
  }
  return list;
}

// Legacy no-arg signature preserved for existing sync callers (analysis PDF).
// Now delegates to the parameterized builder; the optional argument lets newer
// callers pass real Supabase-derived delegates instead of the mock list.
List<Map<String, dynamic>> getLateSubscribersData([List<_Delegate>? delegates]) {
  return _lateSubscribersFrom(delegates ?? _mockDelegates);
}

// ── Data Models ───────────────────────────────────────────────────────────────
class _Subscriber {
  final String id, name;
  int monthsActive;
  DateTime lastPayment;
  final double monthlyAmount;
  _Subscriber({
    required this.id,
    required this.name,
    required this.monthsActive,
    required this.lastPayment,
    required this.monthlyAmount,
  });

  int get monthsLate {
    const now = 3; // March 2026 = month 3
    const nowYear = 2026;
    final diff = ((nowYear - lastPayment.year) * 12) + (now - lastPayment.month);
    return diff.clamp(0, 999);
  }

  Color get statusColor {
    final late = monthsLate;
    if (late == 0) return const Color(0xFF10B981);
    if (late < 4) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get statusLabel {
    final late = monthsLate;
    if (late == 0) return 'مسدد';
    if (late < 4) return 'متأخر $lateش';
    return 'متأخر $lateش';
  }
}

class _Delegate {
  final String id, name, area, phone;
  final bool isFemale;
  final String specialty;
  final DateTime joinDate;
  final String address;
  final List<_Subscriber> subscribers;
  const _Delegate({
    required this.id,
    required this.name,
    required this.area,
    required this.phone,
    required this.isFemale,
    required this.specialty,
    required this.joinDate,
    required this.address,
    required this.subscribers,
  });

  int get colorIndex => (int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1) - 1;
  int get activeCount => subscribers.where((s) => s.monthsLate == 0).length;
  int get lateCount => subscribers.where((s) => s.monthsLate > 0).length;
  double get totalMonthly => subscribers.fold(0, (s, e) => s + e.monthlyAmount);
}

// ── Mock Data ─────────────────────────────────────────────────────────────────
final _mockDelegates = [
  _Delegate(
    id: 'd1', name: 'أحمد محمد الكريمي', area: 'الكرخ', phone: '07701234567',
    isFemale: false, specialty: 'مشرف اشتراكات',
    joinDate: DateTime(2023, 5, 12), address: 'بغداد، شارع فلسطين، محلة 502',
    subscribers: [
      _Subscriber(id: 's1', name: 'علي حسين العامري', monthsActive: 18, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 25000),
      _Subscriber(id: 's2', name: 'كريم طالب الصفار', monthsActive: 12, lastPayment: DateTime(2026, 2, 1), monthlyAmount: 25000),
      _Subscriber(id: 's3', name: 'حيدر جاسم الزيدي', monthsActive: 24, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 50000),
      _Subscriber(id: 's4', name: 'محمد عبد الرضا', monthsActive: 8, lastPayment: DateTime(2025, 10, 1), monthlyAmount: 25000),
      _Subscriber(id: 's5', name: 'سلام ياسر الدليمي', monthsActive: 30, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 50000),
    ],
  ),
  _Delegate(
    id: 'd2', name: 'سارة علي الموسوي', area: 'الرصافة', phone: '07702345678',
    isFemale: false, specialty: 'مندوبة ميدانية',
    joinDate: DateTime(2024, 1, 10), address: 'بغداد، الكرادة، قرب ساحة الحرية',
    subscribers: [
      _Subscriber(id: 's6', name: 'زينب عدنان الحسني', monthsActive: 15, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 25000),
      _Subscriber(id: 's7', name: 'رنا صبحي الراوي', monthsActive: 9, lastPayment: DateTime(2026, 1, 1), monthlyAmount: 25000),
      _Subscriber(id: 's8', name: 'فاطمة كامل السلطاني', monthsActive: 22, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 50000),
      _Subscriber(id: 's9', name: 'نور خليل العزاوي', monthsActive: 6, lastPayment: DateTime(2025, 9, 1), monthlyAmount: 25000),
    ],
  ),
  _Delegate(
    id: 'd3', name: 'حسين رضا الجبوري', area: 'الأعظمية', phone: '07703456789',
    isFemale: false, specialty: 'منسق اشتراكات',
    joinDate: DateTime(2024, 8, 22), address: 'بغداد، الأعظمية، شارع عمر بن عبد العزيز',
    subscribers: [
      _Subscriber(id: 's10', name: 'باسم طارق الطائي', monthsActive: 36, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 100000),
      _Subscriber(id: 's11', name: 'عمر صالح الجنابي', monthsActive: 14, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 50000),
      _Subscriber(id: 's12', name: 'ليث قاسم الشمري', monthsActive: 7, lastPayment: DateTime(2026, 2, 1), monthlyAmount: 25000),
      _Subscriber(id: 's13', name: 'تامر حامد البغدادي', monthsActive: 11, lastPayment: DateTime(2025, 11, 1), monthlyAmount: 25000),
      _Subscriber(id: 's14', name: 'وائل صادق الخفاجي', monthsActive: 28, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 50000),
      _Subscriber(id: 's15', name: 'مالك فؤاد الربيعي', monthsActive: 3, lastPayment: DateTime(2025, 7, 1), monthlyAmount: 25000),
    ],
  ),
  _Delegate(
    id: 'd4', name: 'نور محمد الهاشمي', area: 'الكاظمية', phone: '07704567890',
    isFemale: false, specialty: 'مندوبة خدمات',
    joinDate: DateTime(2025, 2, 5), address: 'بغداد، الكاظمية، محلة 204',
    subscribers: [
      _Subscriber(id: 's16', name: 'مريم عادل التكريتي', monthsActive: 20, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 50000),
      _Subscriber(id: 's17', name: 'دينا وليد الفهد', monthsActive: 5, lastPayment: DateTime(2026, 2, 1), monthlyAmount: 25000),
      _Subscriber(id: 's18', name: 'آلاء ستار العبيدي', monthsActive: 16, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 25000),
    ],
  ),
  _Delegate(
    id: 'd5', name: 'علاء الدين فارس', area: 'الدورة', phone: '07705678901',
    isFemale: false, specialty: 'مشرف ميداني',
    joinDate: DateTime(2023, 11, 30), address: 'بغداد، الدورة، حي الجمعية',
    subscribers: [
      _Subscriber(id: 's19', name: 'سيف عزيز النوري', monthsActive: 42, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 100000),
      _Subscriber(id: 's20', name: 'أمير بشير المعموري', monthsActive: 10, lastPayment: DateTime(2025, 12, 1), monthlyAmount: 25000),
      _Subscriber(id: 's21', name: 'بلال ريان السامرائي', monthsActive: 18, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 50000),
      _Subscriber(id: 's22', name: 'كريم حارث الجميلي', monthsActive: 8, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 25000),
      _Subscriber(id: 's23', name: 'عبدالله مصطفى الزبيدي', monthsActive: 25, lastPayment: DateTime(2025, 8, 1), monthlyAmount: 50000),
    ],
  ),
  _Delegate(
    id: 'd6', name: 'ريم سعد العلي', area: 'الشعب', phone: '07706789012',
    isFemale: false, specialty: 'مندوبة اشتراكات',
    joinDate: DateTime(2025, 6, 15), address: 'بغداد، الشعب، قرب السوق الكبير',
    subscribers: [
      _Subscriber(id: 's24', name: 'هند جلال الساعدي', monthsActive: 13, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 25000),
      _Subscriber(id: 's25', name: 'شيماء فيصل الكناني', monthsActive: 7, lastPayment: DateTime(2026, 1, 1), monthlyAmount: 25000),
      _Subscriber(id: 's26', name: 'لمياء قيس الحيالي', monthsActive: 31, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 50000),
      _Subscriber(id: 's27', name: 'منى وسام الأنصاري', monthsActive: 4, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 25000),
    ],
  ),
];

// ── Main Page ─────────────────────────────────────────────────────────────────
class FamiliesPage extends ConsumerStatefulWidget {
  const FamiliesPage({super.key});

  @override
  ConsumerState<FamiliesPage> createState() => _FamiliesPageState();
}

class _FamiliesPageState extends ConsumerState<FamiliesPage> {
  String _query = '';

  // Real Supabase-backed delegates (grouped from SubscriberModel list).
  List<_Delegate>? _delegates;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final models = await SupabaseSubscribersRepository().getAll();
      final delegates = _buildDelegatesFromModels(models);
      if (!mounted) return;
      setState(() {
        _delegates = delegates;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<_Delegate> get _filtered => (_delegates ?? const <_Delegate>[])
      .where((d) => _query.isEmpty || d.name.contains(_query) || d.area.contains(_query))
      .toList();

  void _showAddDelegate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDelegateSheet(
        // TODO(supabase): creating a delegate requires a staff/auth account
        // (make_staff); not persisted yet. Reloading re-reads real subscribers.
        onSaved: () => _load(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loadedDelegates = _delegates ?? const <_Delegate>[];
    final totalSubs = loadedDelegates.fold(0, (s, d) => s + d.subscribers.length);

    return Column(
      children: [
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('المندوبين',
                            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                        Text('إدارة المندوبين وسجلات مشتركيهم',
                            style: GoogleFonts.cairo(fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _showAddDelegate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPurple,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(children: [
                            const Icon(Icons.person_add_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('إضافة مندوب', style: GoogleFonts.cairo(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _StatChip(label: 'المندوبين', value: '${loadedDelegates.length}',
                      color: AppColors.primary, icon: Icons.badge_rounded),
                  const SizedBox(width: 8),
                  _StatChip(label: 'المشتركين', value: '$totalSubs',
                      color: const Color(0xFF10B981), icon: Icons.people_rounded),
                ],
              ),
              const SizedBox(height: 10),

              // Search
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search_rounded, size: 18,
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: GoogleFonts.cairo(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'بحث باسم المندوب أو المنطقة...',
                          hintStyle: GoogleFonts.cairo(fontSize: 12,
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 40,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          const SizedBox(height: 10),
                          Text('تعذّر تحميل البيانات',
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text('إعادة المحاولة',
                                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filtered.isEmpty
                      ? Center(child: Text('لا توجد نتائج', style: GoogleFonts.cairo(fontSize: 14)))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) => _DelegateCard(
                            delegate: _filtered[i],
                            onRefresh: () => setState(() {}),
                          ),
                        ),
        ),
      ],
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────
