part of '../pages/donations_page.dart';

class _TransferHistoryTab extends ConsumerStatefulWidget {
  final bool isDark;
  final bool isAdmin;

  const _TransferHistoryTab(
      {required this.isDark, required this.isAdmin});

  @override
  ConsumerState<_TransferHistoryTab> createState() =>
      _TransferHistoryTabState();
}

class _TransferHistoryTabState
    extends ConsumerState<_TransferHistoryTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transfers = ref.watch(filteredDonationsProvider);
    final allTransfers = ref.watch(donationsProvider);
    final statusFilter = ref.watch(donationStatusFilterProvider);
    final methodFilter = ref.watch(donationMethodFilterProvider);
    final totalCompleted = allTransfers
        .where((t) => t.status == 'مكتمل')
        .fold(0.0, (s, t) => s + t.amount);
    final isDark = widget.isDark;
    final isAdmin = widget.isAdmin;

    return CustomScrollView(
      slivers: [
        // ── Summary card ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF00C9A7), Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(children: [
              const Icon(Icons.swap_horiz_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('إجمالي التحويلات المكتملة',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.white
                                .withValues(alpha: 0.8))),
                    Text(
                        '${NumberFormat('#,###').format(totalCompleted)} د.ع',
                        style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ])),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('${allTransfers.length} عملية',
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        _showAddDonationDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ]),
            ]),
          ),
        ),

        // ── Search & Filters ──────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => ref
                    .read(donationSearchProvider.notifier)
                    .state = v,
                style: GoogleFonts.cairo(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'بحث عن متبرع أو رقم مرجعي...',
                  hintStyle: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight),
                  prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.5)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _FilterChip(
                    label: 'الكل',
                    selected: statusFilter == null &&
                        methodFilter == null,
                    color: AppColors.primary,
                    onTap: () {
                      ref
                          .read(donationStatusFilterProvider
                              .notifier)
                          .state = null;
                      ref
                          .read(donationMethodFilterProvider
                              .notifier)
                          .state = null;
                    },
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'مكتمل',
                    selected: statusFilter == 'مكتمل',
                    color: AppColors.success,
                    onTap: () => ref
                        .read(donationStatusFilterProvider
                            .notifier)
                        .state = statusFilter == 'مكتمل'
                        ? null
                        : 'مكتمل',
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'قيد المعالجة',
                    selected: statusFilter == 'قيد المعالجة',
                    color: AppColors.warning,
                    onTap: () => ref
                        .read(donationStatusFilterProvider
                            .notifier)
                        .state =
                        statusFilter == 'قيد المعالجة'
                            ? null
                            : 'قيد المعالجة',
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'مرفوض',
                    selected: statusFilter == 'مرفوض',
                    color: AppColors.error,
                    onTap: () => ref
                        .read(donationStatusFilterProvider
                            .notifier)
                        .state = statusFilter == 'مرفوض'
                        ? null
                        : 'مرفوض',
                  ),
                  const SizedBox(width: 6),
                  ...PaymentMethod.values.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _FilterChip(
                        label: m.labelAr,
                        selected: methodFilter == m,
                        color: m.accentColor,
                        onTap: () => ref
                            .read(donationMethodFilterProvider
                                .notifier)
                            .state =
                            methodFilter == m ? null : m,
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),

        // ── List or empty state ───────────────────────────────
        if (transfers.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Icon(Icons.search_off_rounded,
                    size: 48,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight),
                const SizedBox(height: 12),
                Text('لا توجد نتائج',
                    style: GoogleFonts.cairo(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)),
              ]),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: EdgeInsets.only(
                      bottom: i < transfers.length - 1 ? 10 : 0),
                  child: _TransferCard(
                    transfer: transfers[i],
                    isDark: isDark,
                    isAdmin: isAdmin,
                    onTap: () => _showDetailSheet(
                        ctx, transfers[i]),
                  ),
                ),
                childCount: transfers.length,
              ),
            ),
          ),
      ],
    );
  }

  void _showDetailSheet(
      BuildContext context, TransferRecord t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TransferDetailSheet(
          transfer: t,
          isDark: widget.isDark,
          isAdmin: widget.isAdmin),
    );
  }

  void _showAddDonationDialog(BuildContext context) {
    final donorCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    PaymentMethod selectedMethod = PaymentMethod.cash;
    String selectedStatus = 'مكتمل';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('إضافة تبرع يدوي',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: donorCtrl,
                decoration: InputDecoration(
                  labelText: 'اسم المتبرع',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon:
                      const Icon(Icons.person_outline_rounded),
                ),
                style: GoogleFonts.cairo(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: InputDecoration(
                  labelText: 'المبلغ (د.ع)',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon:
                      const Icon(Icons.attach_money_rounded),
                ),
                style: GoogleFonts.cairo(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentMethod>(
                value: selectedMethod,
                onChanged: (v) =>
                    setDlgState(() => selectedMethod = v!),
                decoration: InputDecoration(
                  labelText: 'طريقة الدفع',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: PaymentMethod.values
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.labelAr,
                              style: GoogleFonts.cairo()),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                onChanged: (v) =>
                    setDlgState(() => selectedStatus = v!),
                decoration: InputDecoration(
                  labelText: 'الحالة',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: ['مكتمل', 'قيد المعالجة', 'مرفوض']
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s,
                              style: GoogleFonts.cairo()),
                        ))
                    .toList(),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () {
                final amt =
                    double.tryParse(amountCtrl.text.trim());
                if (donorCtrl.text.trim().isNotEmpty &&
                    amt != null) {
                  ref
                      .read(donationsProvider.notifier)
                      .addTransfer(
                        donor: donorCtrl.text.trim(),
                        amount: amt,
                        method: selectedMethod,
                        status: selectedStatus,
                      );
                  ref
                      .read(operationsProvider.notifier)
                      .addOperation(
                        action: 'إضافة تبرع يدوي',
                        description:
                            'تم تسجيل تبرع ${NumberFormat('#,###').format(amt)} د.ع من ${donorCtrl.text.trim()} عبر ${selectedMethod.labelAr}',
                        user: 'المدير',
                        color: AppColors.logAdd,
                        icon: Icons.add_card_rounded,
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم إضافة التبرع بنجاح',
                          style: GoogleFonts.cairo()),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: Text('إضافة',
                  style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

