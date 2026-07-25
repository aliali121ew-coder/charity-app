part of '../pages/donations_page.dart';

class _DonateNowTab extends ConsumerWidget {
  final bool isDark;
  final TextEditingController customAmountCtrl;
  final TabController tabController;

  const _DonateNowTab({
    required this.isDark,
    required this.customAmountCtrl,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIdx = ref.watch(selectedMethodIndexProvider);
    final selectedAmount = ref.watch(selectedAmountProvider);
    final loading = ref.watch(donationLoadingProvider);
    final method = PaymentMethod.values[selectedIdx];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SectionTitle(
                  title: 'طرق الدفع',
                  icon: Icons.credit_card_rounded,
                  isDark: isDark),
              const SizedBox(height: 14),
              _StackedCards(
                selectedIdx: selectedIdx,
                onSelect: (i) {
                  ref.read(selectedMethodIndexProvider.notifier).state = i;
                  ref.read(selectedAmountProvider.notifier).state = null;
                },
              ),
              const SizedBox(height: 22),
              _MethodInfoCard(method: method, isDark: isDark),
              const SizedBox(height: 22),
              _SectionTitle(
                  title: 'اختر مبلغ التبرع',
                  icon: Icons.monetization_on_rounded,
                  isDark: isDark),
              const SizedBox(height: 12),
              _QuickAmounts(
                selected: selectedAmount,
                onSelect: (a) {
                  ref.read(selectedAmountProvider.notifier).state = a;
                  customAmountCtrl.clear();
                },
              ),
              const SizedBox(height: 14),
              _CustomAmountField(
                isDark: isDark,
                controller: customAmountCtrl,
                onChanged: (_) {
                  ref.read(selectedAmountProvider.notifier).state = null;
                },
              ),
              const SizedBox(height: 24),
          _DonateButton(
            isDark: isDark,
            method: method,
            loading: loading,
            amount: selectedAmount ??
                double.tryParse(
                    customAmountCtrl.text.replaceAll(',', '')),
            onTap: () async {
              final amt = selectedAmount ??
                  double.tryParse(
                      customAmountCtrl.text.replaceAll(',', ''));
              if (amt == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('الرجاء اختيار أو إدخال مبلغ',
                      style: GoogleFonts.cairo()),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
                return;
              }
              ref.read(donationLoadingProvider.notifier).state = true;
              await Future.delayed(
                  const Duration(milliseconds: 1600));
              ref.read(donationLoadingProvider.notifier).state =
                  false;
              ref.read(selectedAmountProvider.notifier).state = null;
              customAmountCtrl.clear();

              // Add to donations list
              final user =
                  ref.read(authProvider).user?.name ?? 'متبرع';
              ref.read(donationsProvider.notifier).addTransfer(
                    donor: user,
                    amount: amt,
                    method: method,
                    status: method == PaymentMethod.bankTransfer
                        ? 'قيد المعالجة'
                        : 'مكتمل',
                  );
              // Add to operations log
              ref.read(operationsProvider.notifier).addOperation(
                    action: 'تبرع جديد',
                    description:
                        'تم تسجيل تبرع ${NumberFormat('#,###').format(amt)} د.ع عبر ${method.labelAr}',
                    user: user,
                    color: AppColors.logApprove,
                    icon: Icons.volunteer_activism_rounded,
                  );

              if (context.mounted) {
                _showSuccessSheet(context, method, amt,
                    tabController: tabController);
              }
            },
          ),
              const SizedBox(height: 14),
              _SecurityNote(isDark: isDark),
            ]),
          ),
        ),
      ],
    );
  }

  void _showSuccessSheet(
    BuildContext context,
    PaymentMethod method,
    double amount, {
    required TabController tabController,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(
        method: method,
        amount: amount,
        onViewHistory: () {
          Navigator.pop(context);
          tabController.animateTo(1);
        },
      ),
    );
  }
}

// ── Stacked Cards ─────────────────────────────────────────────────────────────

class _StackedCards extends StatefulWidget {
  final int selectedIdx;
  final ValueChanged<int> onSelect;

  const _StackedCards(
      {required this.selectedIdx, required this.onSelect});

  @override
  State<_StackedCards> createState() => _StackedCardsState();
}

class _StackedCardsState extends State<_StackedCards>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400));
    _anim =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_StackedCards old) {
    super.didUpdateWidget(old);
    if (old.selectedIdx != widget.selectedIdx) {
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const methods = PaymentMethod.values;
    final selected = widget.selectedIdx;
    final orderedIndices = <int>[];
    for (int i = 0; i < methods.length; i++) {
      if (i != selected) orderedIndices.add(i);
    }
    orderedIndices.add(selected);

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: orderedIndices.asMap().entries.map((e) {
          final stackPos = e.key;
          final methodIdx = e.value;
          final isSelected = methodIdx == selected;
          final depth = orderedIndices.length - 1 - stackPos;
          final double yOffset =
              isSelected ? 0 : (depth * 14.0).toDouble();
          final double xOffset = isSelected
              ? 0
              : (stackPos.isEven ? -1.0 : 1.0) * depth * 4;
          final double rotation = isSelected
              ? 0
              : (stackPos.isEven ? -1 : 1) * depth * 0.025;
          final double scale = isSelected
              ? 1.0
              : (1.0 - depth * 0.04).clamp(0.80, 1.0);
          final double opacity = isSelected
              ? 1.0
              : (1.0 - depth * 0.18).clamp(0.3, 1.0);

          return AnimatedBuilder(
            animation: _anim,
            builder: (_, child) {
              double animYOffset = yOffset;
              double animScale = scale;
              if (isSelected) {
                animYOffset = -20 * (1 - _anim.value);
                animScale = 0.9 + 0.1 * _anim.value;
              }
              return Transform.translate(
                offset: Offset(xOffset, animYOffset),
                child: Transform.rotate(
                  angle: rotation,
                  child: Transform.scale(
                    scale: animScale,
                    child: Opacity(
                        opacity: opacity, child: child),
                  ),
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                if (isSelected) {
                  widget.onSelect((methodIdx + 1) % methods.length);
                } else {
                  widget.onSelect(methodIdx);
                }
              },
              child: _CreditCard(
                method: methods[methodIdx],
                isSelected: isSelected,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

