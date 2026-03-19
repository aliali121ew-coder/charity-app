import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:charity_app/core/theme/app_colors.dart';


// ── Data Models ───────────────────────────────────────────────────────────────
class _Subscriber {
  final String id, name;
  final int monthsActive;
  final DateTime lastPayment;
  final double monthlyAmount;
  const _Subscriber({
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
  final List<_Subscriber> subscribers;
  const _Delegate({
    required this.id,
    required this.name,
    required this.area,
    required this.phone,
    required this.isFemale,
    required this.specialty,
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
    subscribers: [
      _Subscriber(id: 's16', name: 'مريم عادل التكريتي', monthsActive: 20, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 50000),
      _Subscriber(id: 's17', name: 'دينا وليد الفهد', monthsActive: 5, lastPayment: DateTime(2026, 2, 1), monthlyAmount: 25000),
      _Subscriber(id: 's18', name: 'آلاء ستار العبيدي', monthsActive: 16, lastPayment: DateTime(2026, 3, 1), monthlyAmount: 25000),
    ],
  ),
  _Delegate(
    id: 'd5', name: 'علاء الدين فارس', area: 'الدورة', phone: '07705678901',
    isFemale: false, specialty: 'مشرف ميداني',
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

  List<_Delegate> get _filtered => _mockDelegates
      .where((d) => _query.isEmpty || d.name.contains(_query) || d.area.contains(_query))
      .toList();

  void _showAddDelegate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDelegateSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSubs = _mockDelegates.fold(0, (s, d) => s + d.subscribers.length);

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
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _StatChip(label: 'المندوبين', value: '${_mockDelegates.length}',
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
          child: _filtered.isEmpty
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
                  itemBuilder: (ctx, i) => _DelegateCard(delegate: _filtered[i]),
                ),
        ),
      ],
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatChip({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w900, color: color, height: 1.1)),
                Text(label, style: GoogleFonts.cairo(fontSize: 8, color: color.withValues(alpha: 0.75))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Delegate Card ──────────────────────────────────────────────────────────────
class _DelegateCard extends StatelessWidget {
  final _Delegate delegate;
  const _DelegateCard({required this.delegate});

  static const _gradients = [
    LinearGradient(colors: [Color(0xFF5B4FCF), Color(0xFF3D33A8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF0E7490)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB45309)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  ];

  LinearGradient _gradient(String id) {
    final idx = int.tryParse(id.replaceAll('d', '')) ?? 0;
    return _gradients[(idx - 1) % _gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grad = _gradient(delegate.id);
    final accentColor = grad.colors.first;

    return GestureDetector(
      onTap: () => _showSubscriberSheet(context, delegate),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: isDark ? 0.22 : 0.15)),
          boxShadow: [
            BoxShadow(color: accentColor.withValues(alpha: isDark ? 0.3 : 0.18), blurRadius: 14, spreadRadius: -4, offset: const Offset(0, 7)),
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08), blurRadius: 20, spreadRadius: -5, offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.fromLTRB(12, 14, 8, 12),
                decoration: BoxDecoration(gradient: grad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
                      ),
                      child: _DelegateAvatar(isFemale: delegate.isFemale, size: 52, index: delegate.colorIndex),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(delegate.name,
                              style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white,
                                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)]),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(delegate.specialty,
                              style: GoogleFonts.cairo(fontSize: 9, color: Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                    // Menu
                    PopupMenuButton<String>(
                      iconSize: 18,
                      icon: Icon(Icons.more_vert_rounded, color: Colors.white.withValues(alpha: 0.9), size: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'payment') {
                          _showPaymentSheet(context, delegate);
                        } else if (val == 'addSub') {
                          _showAddSubscriberSheet(context, delegate);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'payment',
                          child: Row(children: [
                            Container(padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.payment_rounded, size: 16, color: Color(0xFF10B981))),
                            const SizedBox(width: 10),
                            Text('تسديد اشتراك', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'addSub',
                          child: Row(children: [
                            Container(padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.person_add_rounded, size: 16, color: AppColors.primary)),
                            const SizedBox(width: 10),
                            Text('إضافة مشترك', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Divider shine
              Container(height: 1, decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  accentColor.withValues(alpha: 0.0), accentColor.withValues(alpha: 0.5), accentColor.withValues(alpha: 0.0),
                ]),
              )),

              // Body
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.location_on_outlined, size: 12, color: accentColor.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(delegate.area, style: GoogleFonts.cairo(fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      ]),
                      const SizedBox(height: 6),
                      // Subscriber count
                      Row(
                        children: [
                          Expanded(child: _MiniCounter(
                            label: 'مشتركين', value: '${delegate.subscribers.length}',
                            color: accentColor, isDark: isDark,
                          )),
                          const SizedBox(width: 6),
                          Expanded(child: _MiniCounter(
                            label: 'مسددين', value: '${delegate.activeCount}',
                            color: const Color(0xFF10B981), isDark: isDark,
                          )),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Status dots
                      _StatusDots(delegate: delegate),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini Counter ──────────────────────────────────────────────────────────────
class _MiniCounter extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _MiniCounter({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900, color: color, height: 1.1)),
          Text(label, style: GoogleFonts.cairo(fontSize: 8, color: color.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}

// ── Status Dots ───────────────────────────────────────────────────────────────
class _StatusDots extends StatelessWidget {
  final _Delegate delegate;
  const _StatusDots({required this.delegate});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 3,
      children: delegate.subscribers.map((s) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: s.statusColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: s.statusColor.withValues(alpha: 0.5), blurRadius: 4)],
        ),
      )).toList(),
    );
  }
}

// ── Subscriber Sheet (bottom sheet) ──────────────────────────────────────────
void _showSubscriberSheet(BuildContext context, _Delegate delegate) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SubscriberSheet(delegate: delegate),
  );
}

class _SubscriberSheet extends StatelessWidget {
  final _Delegate delegate;
  const _SubscriberSheet({required this.delegate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30)],
        ),
        child: Column(
          children: [
            // Handle
            Center(child: Container(margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4, decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2)))),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  _DelegateAvatar(isFemale: delegate.isFemale, size: 44, index: delegate.colorIndex),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(delegate.name, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    Text('${delegate.subscribers.length} مشترك • ${delegate.area}',
                        style: GoogleFonts.cairo(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ])),
                  // Legend
                  const Row(children: [
                    _LegendDot(color: Color(0xFF10B981), label: 'مسدد'),
                    SizedBox(width: 8),
                    _LegendDot(color: Color(0xFFF59E0B), label: '<4ش'),
                    SizedBox(width: 8),
                    _LegendDot(color: Color(0xFFEF4444), label: '>4ش'),
                  ]),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
              child: Row(children: [
                Expanded(flex: 3, child: Text('الاسم', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                Expanded(child: Text('الأشهر', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                Expanded(child: Text('القسط', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                Expanded(child: Text('الحالة', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: delegate.subscribers.length,
                separatorBuilder: (_, __) => Divider(height: 1, indent: 16, endIndent: 16,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight),
                itemBuilder: (_, i) {
                  final s = delegate.subscribers[i];
                  return _SubscriberRow(subscriber: s, isDark: isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 3),
      Text(label, style: GoogleFonts.cairo(fontSize: 9,
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)),
    ]);
  }
}

class _SubscriberRow extends StatelessWidget {
  final _Subscriber subscriber;
  final bool isDark;
  const _SubscriberRow({required this.subscriber, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(subscriber.name,
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(child: Text('${subscriber.monthsActive}',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
          Expanded(child: Text('${(subscriber.monthlyAmount / 1000).toStringAsFixed(0)}K',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary))),
          Expanded(child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: subscriber.statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: subscriber.statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(subscriber.statusLabel,
                  style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.w700, color: subscriber.statusColor)),
            ),
          )),
        ],
      ),
    );
  }
}

// ── Delegate Avatar ────────────────────────────────────────────────────────────
// Each delegate gets a unique color based on their index in the list
const _avatarColors = [
  [Color(0xFF6D28D9), Color(0xFF4F46E5)],
  [Color(0xFF0369A1), Color(0xFF0891B2)],
  [Color(0xFF065F46), Color(0xFF059669)],
  [Color(0xFF92400E), Color(0xFFD97706)],
  [Color(0xFF7C2D12), Color(0xFFEA580C)],
  [Color(0xFF1E3A5F), Color(0xFF2563EB)],
];

class _DelegateAvatar extends StatelessWidget {
  final bool isFemale;
  final double size;
  final int index;
  const _DelegateAvatar({required this.isFemale, required this.size, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final colors = _avatarColors[index % _avatarColors.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colors[0], colors[1]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.62,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }
}

// ── Payment Sheet ──────────────────────────────────────────────────────────────
void _showPaymentSheet(BuildContext context, _Delegate delegate) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentSheet(delegate: delegate),
  );
}

class _PaymentSheet extends StatefulWidget {
  final _Delegate delegate;
  const _PaymentSheet({required this.delegate});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  _Subscriber? _selected;
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('تسديد اشتراك', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            Text('مندوب: ${widget.delegate.name}',
                style: GoogleFonts.cairo(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            const SizedBox(height: 16),
            Text('اختر المشترك', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: DropdownButtonFormField<_Subscriber>(
                initialValue: _selected,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                ),
                hint: Text('اختر مشتركاً', style: GoogleFonts.cairo(fontSize: 12)),
                items: widget.delegate.subscribers.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.name, style: GoogleFonts.cairo(fontSize: 12)),
                )).toList(),
                onChanged: (s) {
                  setState(() {
                    _selected = s;
                    if (s != null) _amountCtrl.text = s.monthlyAmount.toStringAsFixed(0);
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('المبلغ', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.cairo(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'المبلغ بالدينار العراقي',
                hintStyle: GoogleFonts.cairo(fontSize: 12),
                suffixText: 'د.ع',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selected == null ? null : () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✓ تم تسجيل تسديد ${_selected!.name}',
                        style: GoogleFonts.cairo(color: Colors.white)),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: Text('تأكيد التسديد', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Add Subscriber Sheet ───────────────────────────────────────────────────────
void _showAddSubscriberSheet(BuildContext context, _Delegate delegate) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddSubscriberSheet(delegate: delegate),
  );
}

class _AddSubscriberSheet extends StatelessWidget {
  final _Delegate delegate;
  const _AddSubscriberSheet({required this.delegate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '25000');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('إضافة مشترك جديد', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            Text('مندوب: ${delegate.name}',
                style: GoogleFonts.cairo(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            const SizedBox(height: 16),
            _FormField(label: 'الاسم الكامل', controller: nameCtrl, hint: 'اسم المشترك', isDark: isDark, icon: Icons.person_rounded),
            const SizedBox(height: 10),
            _FormField(label: 'رقم الهاتف', controller: phoneCtrl, hint: '07X XXXX XXXX', isDark: isDark,
                icon: Icons.phone_rounded, inputType: TextInputType.phone),
            const SizedBox(height: 10),
            _FormField(label: 'القسط الشهري (د.ع)', controller: amountCtrl, hint: 'المبلغ',
                isDark: isDark, icon: Icons.monetization_on_rounded, inputType: TextInputType.number),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✓ تمت إضافة المشترك بنجاح', style: GoogleFonts.cairo(color: Colors.white)),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: Text('إضافة المشترك', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final bool isDark;
  final IconData icon;
  final TextInputType inputType;
  const _FormField({required this.label, required this.hint, required this.controller,
      required this.isDark, required this.icon, this.inputType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: inputType,
          style: GoogleFonts.cairo(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(fontSize: 12),
            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

// ── Add Delegate Sheet ─────────────────────────────────────────────────────────
class _AddDelegateSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final specialtyCtrl = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(gradient: AppColors.gradientPurple, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.badge_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Text('إضافة مندوب جديد', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            ]),
            const SizedBox(height: 20),
            _FormField(label: 'الاسم الكامل', controller: nameCtrl, hint: 'اسم المندوب', isDark: isDark, icon: Icons.person_rounded),
            const SizedBox(height: 10),
            _FormField(label: 'المنطقة', controller: areaCtrl, hint: 'المنطقة المسؤول عنها', isDark: isDark, icon: Icons.location_on_rounded),
            const SizedBox(height: 10),
            _FormField(label: 'رقم الهاتف', controller: phoneCtrl, hint: '07X XXXX XXXX', isDark: isDark,
                icon: Icons.phone_rounded, inputType: TextInputType.phone),
            const SizedBox(height: 10),
            _FormField(label: 'المسمى الوظيفي', controller: specialtyCtrl, hint: 'مثال: مشرف اشتراكات', isDark: isDark, icon: Icons.work_rounded),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✓ تمت إضافة المندوب بنجاح', style: GoogleFonts.cairo(color: Colors.white)),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text('حفظ المندوب', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
