part of '../pages/donations_page.dart';

class _OperationsLogTab extends ConsumerWidget {
  final bool isDark;

  const _OperationsLogTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operations = ref.watch(operationsProvider);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: AppColors.indigo.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(children: [
              const Icon(Icons.history_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('سجل العمليات',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            color:
                                Colors.white.withValues(alpha: 0.8))),
                    Text('تتبع كامل لجميع العمليات المنجزة',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ])),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('${operations.length} عملية',
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _OperationItem(
                operation: operations[i],
                isDark: isDark,
                isLast: i == operations.length - 1,
              ),
              childCount: operations.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _OperationItem extends StatelessWidget {
  final OperationRecord operation;
  final bool isDark, isLast;

  const _OperationItem(
      {required this.operation,
      required this.isDark,
      required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Timeline line
        if (!isLast)
          Positioned.directional(
            textDirection: Directionality.of(context),
            start: 19,
            top: 36,
            bottom: 0,
            width: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    operation.color.withValues(alpha: 0.4),
                    operation.color.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),

        // Content card & Icon
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                width: 40,
                alignment: Alignment.topCenter,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: operation.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: operation.color.withValues(alpha: 0.4),
                        width: 1.5),
                  ),
                  child: Icon(operation.icon,
                      size: 16, color: operation.color),
                ),
              ),
              const SizedBox(width: 12),
              // Content Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark
                        : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: operation.color.withValues(
                            alpha: isDark ? 0.2 : 0.1)),
                    boxShadow: [
                      BoxShadow(
                          color: operation.color
                              .withValues(alpha: 0.08),
                          blurRadius: 8,
                          spreadRadius: -2,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(operation.action,
                                style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight))),
                        Text(
                            DateFormat('dd/MM')
                                .format(operation.date),
                            style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight)),
                      ]),
                      const SizedBox(height: 6),
                      Text(operation.description,
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              height: 1.5)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.person_outline_rounded,
                            size: 12,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight),
                        const SizedBox(width: 4),
                        Text(operation.user,
                            style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight)),
                        const Spacer(),
                        Text(
                            DateFormat('hh:mm a')
                                .format(operation.date),
                            style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight)),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

