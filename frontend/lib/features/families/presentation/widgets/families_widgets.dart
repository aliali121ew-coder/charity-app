part of '../pages/families_page.dart';

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
  final VoidCallback onRefresh;
  const _DelegateCard({required this.delegate, required this.onRefresh});

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
      onTap: () => _showSubscriberSheet(context, delegate, onRefresh),
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
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(gradient: grad),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Photo
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                          ),
                          child: _DelegateAvatar(isFemale: delegate.isFemale, size: 44, index: delegate.colorIndex),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          delegate.name,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          delegate.specialty,
                          style: GoogleFonts.cairo(
                            fontSize: 9.5,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Menu
                  Positioned(
                    left: 2,
                    top: 2,
                    child: PopupMenuButton<String>(
                      iconSize: 18,
                      icon: Icon(Icons.more_vert_rounded, color: Colors.white.withValues(alpha: 0.9), size: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'payment') {
                          _showPaymentSheet(context, delegate);
                        } else if (val == 'addSub') {
                          _showAddSubscriberSheet(context, delegate);
                        } else if (val == 'editDelegate') {
                          _showEditDelegateSheet(context, delegate, onRefresh);
                        } else if (val == 'editSub') {
                          _showEditSubscriberSheet(context, delegate);
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
                        PopupMenuItem(
                          value: 'editDelegate',
                          child: Row(children: [
                            Container(padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary)),
                            const SizedBox(width: 10),
                            Text('تعديل بيانات المندوب', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'editSub',
                          child: Row(children: [
                            Container(padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.manage_accounts_rounded, size: 16, color: Color(0xFF10B981))),
                            const SizedBox(width: 10),
                            Text('تعديل بيانات المشترك', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
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

void _showSubscriberSheet(BuildContext context, _Delegate delegate, VoidCallback onRefresh) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SubscriberSheet(delegate: delegate),
  ).then((_) => onRefresh());
}

class _SubscriberSheet extends StatefulWidget {
  final _Delegate delegate;
  const _SubscriberSheet({required this.delegate});

  @override
  State<_SubscriberSheet> createState() => _SubscriberSheetState();
}

class _SubscriberSheetState extends State<_SubscriberSheet> {
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
                  _DelegateAvatar(isFemale: widget.delegate.isFemale, size: 44, index: widget.delegate.colorIndex),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.delegate.name, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    Text('${widget.delegate.subscribers.length} مشترك • ${widget.delegate.area}',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(children: [
                      const Icon(Icons.home_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'العنوان: ${widget.delegate.address}',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Row(children: [
                    const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'الاشتراك: ${DateFormat('yyyy/MM/dd').format(widget.delegate.joinDate)}',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
              child: Row(children: [
                Expanded(flex: 3, child: Text('الاسم', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                Expanded(child: Text('الأشهر', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                Expanded(child: Text('فئة', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                Expanded(child: Text('الحالة', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: widget.delegate.subscribers.length,
                separatorBuilder: (_, __) => Divider(height: 1, indent: 16, endIndent: 16,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight),
                itemBuilder: (_, i) {
                  final s = widget.delegate.subscribers[i];
                  return InkWell(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _SubscriberDetailPage(
                            subscriber: s,
                            delegate: widget.delegate,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: _SubscriberRow(subscriber: s, isDark: isDark),
                  );
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
          Expanded(child: Text('${subscriber.lastPayment.year == 2026 ? subscriber.lastPayment.month : 0}',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
          Expanded(child: Text(NumberFormat('#,###').format(subscriber.monthlyAmount),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary))),
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

