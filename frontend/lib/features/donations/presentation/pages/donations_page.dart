import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/core/permissions/role.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import '../providers/donations_provider.dart';
import '../providers/payment_flow_provider.dart';
import '../../domain/models/payment_models.dart';
import '../widgets/otp_verification_sheet.dart';
import '../widgets/payment_result_sheet.dart';
import '../widgets/stacked_card_selector.dart';

// ── External Payment App Launcher ─────────────────────────────────────────────

const _appLauncherChannel = MethodChannel('com.charity_app/app_launcher');

Future<void> _openAppOrStore(String packageName, String storeUrl) async {
  try {
    final bool opened = await _appLauncherChannel.invokeMethod(
          'openApp', {'package': packageName}) == true;
    if (!opened) {
      await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
  }
}


// ── Main Page ─────────────────────────────────────────────────────────────────

class DonationsPage extends ConsumerStatefulWidget {
  const DonationsPage({super.key});

  @override
  ConsumerState<DonationsPage> createState() => _DonationsPageState();
}

class _DonationsPageState extends ConsumerState<DonationsPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late AnimationController _counterCtrl;
  late Animation<double> _counterAnim;
  final _customAmountCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _cardHolderCtrl = TextEditingController();
  final _cardExpiryCtrl = TextEditingController();
  final _cardCvvCtrl = TextEditingController();
  final _walletPhoneCtrl = TextEditingController();
  bool _awaitingPaymentReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _counterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _counterAnim =
        CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOutCubic);
    _counterCtrl.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _counterCtrl.dispose();
    _customAmountCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardHolderCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    _walletPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _awaitingPaymentReturn) {
      _awaitingPaymentReturn = false;
      // Payment completion is confirmed server-side (status/webhook), not locally.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transfers = ref.watch(donationsProvider);
    final totalDonated = transfers
        .where((t) => t.status == 'مكتمل')
        .fold(0.0, (s, t) => s + t.amount);
    final donorsCount = transfers.map((t) => t.donor).toSet().length;
    final pendingCount =
        transfers.where((t) => t.status == 'قيد المعالجة').length;
    final monthlyGoal = ref.watch(monthlyGoalProvider);
    final stats = ref.watch(donationStatsProvider);
    final isAdmin = ref.watch(authProvider).user?.role == UserRole.admin;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: _DonationHeader(
            isDark: isDark,
            totalDonated: totalDonated,
            donorsCount: donorsCount,
            pendingCount: pendingCount,
            counterAnim: _counterAnim,
            transfersCount: transfers.length,
            monthlyGoal: monthlyGoal,
            stats: stats,
          ),
        ),
        SliverOverlapAbsorber(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          sliver: SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabController: _tabController,
              isDark: isDark,
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _DonateNowTab(
              isDark: isDark,
              customAmountCtrl: _customAmountCtrl,
              cardNumberCtrl: _cardNumberCtrl,
              cardHolderCtrl: _cardHolderCtrl,
              cardExpiryCtrl: _cardExpiryCtrl,
              cardCvvCtrl: _cardCvvCtrl,
              walletPhoneCtrl: _walletPhoneCtrl,
              tabController: _tabController,
              onAwaitReturn: () {
                setState(() => _awaitingPaymentReturn = true);
              }),
          _TransferHistoryTab(isDark: isDark, isAdmin: isAdmin),
          _OperationsLogTab(isDark: isDark),
        ],
      ),
    );
  }
}

// ── Tab Bar Sliver Delegate ────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final bool isDark;

  const _TabBarDelegate({required this.tabController, required this.isDark});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        labelStyle:
            GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500),
        labelColor: AppColors.primary,
        unselectedLabelColor:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'التبرع الآن'),
          Tab(text: 'سجل التحويلات'),
          Tab(text: 'سجل العمليات'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      isDark != old.isDark || tabController != old.tabController;
}

// ── Animated Counter ──────────────────────────────────────────────────────────

class _AnimatedCounter extends AnimatedWidget {
  final double end;
  final TextStyle style;
  final String suffix;

  const _AnimatedCounter({
    required Animation<double> animation,
    required this.end,
    required this.style,
    this.suffix = '',
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final anim = listenable as Animation<double>;
    final value = (anim.value * end).toInt();
    return Text(
      '${NumberFormat('#,###').format(value)}$suffix',
      style: style,
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DonationHeader extends StatelessWidget {
  final bool isDark;
  final double totalDonated;
  final int donorsCount, pendingCount, transfersCount;
  final Animation<double> counterAnim;
  final double monthlyGoal;
  final DonationStats stats;

  const _DonationHeader({
    required this.isDark,
    required this.totalDonated,
    required this.donorsCount,
    required this.pendingCount,
    required this.counterAnim,
    required this.transfersCount,
    required this.monthlyGoal,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
            bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1C1C3A),
                  Color(0xFF3D2B8E),
                  Color(0xFF0D6E5A)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3D2B8E).withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned(
                    right: -25,
                    top: -25,
                    child: _Bubble(size: 120, alpha: 0.07)),
                const Positioned(
                    right: 50,
                    bottom: -15,
                    child: _Bubble(size: 80, alpha: 0.05)),
                const Positioned(
                    left: -15,
                    bottom: -10,
                    child: _Bubble(size: 70, alpha: 0.06)),
                const Positioned(
                    left: 80, top: 10, child: _Bubble(size: 40, alpha: 0.08)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.volunteer_activism_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'إجمالي التبرعات',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 14),
                            _AnimatedCounter(
                              animation: counterAnim,
                              end: totalDonated,
                              suffix: ' د.ع',
                              style: GoogleFonts.cairo(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedBuilder(
                              animation: counterAnim,
                              builder: (_, __) => Text(
                                '≈ \$${NumberFormat('#,###').format((counterAnim.value * totalDonated / 1300).toInt())} USD',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الهدف الشهري: ${NumberFormat('#,###').format(monthlyGoal.toInt())} د.ع',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: AnimatedBuilder(
                                    animation: counterAnim,
                                    builder: (_, __) => LinearProgressIndicator(
                                      value: counterAnim.value *
                                          (totalDonated / monthlyGoal)
                                              .clamp(0.0, 1.0),
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.15),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF00C9A7)),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(children: [
                        _MiniStatCard(
                          label: 'متبرع',
                          value: donorsCount.toString(),
                          icon: Icons.people_rounded,
                          anim: counterAnim,
                        ),
                        const SizedBox(height: 10),
                        _MiniStatCard(
                          label: 'معالجة',
                          value: pendingCount.toString(),
                          icon: Icons.pending_rounded,
                          anim: counterAnim,
                        ),
                        const SizedBox(height: 10),
                        _MiniStatCard(
                          label: 'عملية',
                          value: '$transfersCount',
                          icon: Icons.receipt_long_rounded,
                          anim: counterAnim,
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _StatChip(
                  label: 'هذا الشهر',
                  value: stats.thisMonthLabel,
                  color: AppColors.primary,
                  anim: counterAnim),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'الأسبوع',
                  value: stats.thisWeekLabel,
                  color: AppColors.success,
                  anim: counterAnim),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'اليوم',
                  value: stats.todayLabel,
                  color: AppColors.orange,
                  anim: counterAnim),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'متبرعون جدد',
                  value: stats.newDonorsLabel,
                  color: AppColors.info,
                  anim: counterAnim),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size, alpha;
  const _Bubble({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}

class _MiniStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Animation<double> anim;

  const _MiniStatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.anim});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 9, color: Colors.white.withValues(alpha: 0.7))),
        ]),
      );
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final Animation<double> anim;

  const _StatChip(
      {required this.label,
      required this.value,
      required this.color,
      required this.anim});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: GoogleFonts.cairo(
                fontSize: 10, color: color.withValues(alpha: 0.8))),
      ]),
    );
  }
}

// ── Donate Now Tab ────────────────────────────────────────────────────────────

class _DonateNowTab extends ConsumerWidget {
  final bool isDark;
  final TextEditingController customAmountCtrl;
  final TextEditingController cardNumberCtrl;
  final TextEditingController cardHolderCtrl;
  final TextEditingController cardExpiryCtrl;
  final TextEditingController cardCvvCtrl;
  final TextEditingController walletPhoneCtrl;
  final TabController tabController;
  final VoidCallback onAwaitReturn;

  const _DonateNowTab({
    required this.isDark,
    required this.customAmountCtrl,
    required this.cardNumberCtrl,
    required this.cardHolderCtrl,
    required this.cardExpiryCtrl,
    required this.cardCvvCtrl,
    required this.walletPhoneCtrl,
    required this.tabController,
    required this.onAwaitReturn,
  });

  // ── Map PaymentMethod to PaymentMethodType ─────────────────────────────────
  static PaymentMethodType _toMethodType(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.zainCash:
        return PaymentMethodType.zaincash;
      case PaymentMethod.superKi:
        return PaymentMethodType.superki;
      case PaymentMethod.visaCard:
        return PaymentMethodType.visa;
      case PaymentMethod.masterCard:
        return PaymentMethodType.mastercard;
      case PaymentMethod.bankTransfer:
        return PaymentMethodType.bankTransfer;
      case PaymentMethod.cash:
        return PaymentMethodType.cash;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIdx = ref.watch(selectedMethodIndexProvider);
    final selectedAmount = ref.watch(selectedAmountProvider);
    final loading = ref.watch(paymentFlowProvider.select((s) => s.isLoading));
    final method = PaymentMethod.values[selectedIdx];

    // ── Listen for OTP + result sheet transitions ──────────────────────────
    ref.listen<PaymentFlowState>(paymentFlowProvider, (prev, next) {
      if (!context.mounted) return;
      // Show OTP sheet when verifying
      if (next.step == PaymentFlowStep.verifying &&
          prev?.step != PaymentFlowStep.verifying &&
          next.session != null) {
        OtpVerificationSheet.show(context,
            session: next.session!, isDark: isDark);
      }
      // Show result sheet on success or failure
      if ((next.step == PaymentFlowStep.success ||
              next.step == PaymentFlowStep.failure) &&
          prev?.step != next.step &&
          next.result != null) {
        // Clear form fields
        ref.read(selectedAmountProvider.notifier).set(null);
        customAmountCtrl.clear();
        cardNumberCtrl.clear();
        cardHolderCtrl.clear();
        cardExpiryCtrl.clear();
        cardCvvCtrl.clear();
        walletPhoneCtrl.clear();

        final donorName = ref.read(authProvider).user?.name ?? 'متبرع';
        PaymentResultSheet.show(context,
            result: next.result!, donorName: donorName, isDark: isDark);

        if (next.step == PaymentFlowStep.success) {
          tabController.animateTo(1);
        }
      }
    });

    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SectionTitle(
                  title: 'طرق الدفع',
                  icon: Icons.credit_card_rounded,
                  isDark: isDark),
              const SizedBox(height: 14),
              StackedCardSelector(
                cards: kDefaultPaymentCards,
                selectedIndex: selectedIdx,
                onCardSelected: (i) {
                  ref.read(selectedMethodIndexProvider.notifier).set(i);
                  ref.read(selectedAmountProvider.notifier).set(null);
                  customAmountCtrl.clear();
                  cardNumberCtrl.clear();
                  cardHolderCtrl.clear();
                  cardExpiryCtrl.clear();
                  cardCvvCtrl.clear();
                  walletPhoneCtrl.clear();
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
                  ref.read(selectedAmountProvider.notifier).set(a);
                  customAmountCtrl.clear();
                  // حذف أي بيانات دفع تم إدخالها مسبقاً
                  cardNumberCtrl.clear();
                  cardHolderCtrl.clear();
                  cardExpiryCtrl.clear();
                  cardCvvCtrl.clear();
                  walletPhoneCtrl.clear();
                },
              ),
              const SizedBox(height: 14),
              _CustomAmountField(
                isDark: isDark,
                controller: customAmountCtrl,
                onChanged: (_) {
                  ref.read(selectedAmountProvider.notifier).set(null);
                  // حذف أي بيانات دفع تم إدخالها مسبقاً
                  cardNumberCtrl.clear();
                  cardHolderCtrl.clear();
                  cardExpiryCtrl.clear();
                  cardCvvCtrl.clear();
                  walletPhoneCtrl.clear();
                },
              ),
              // ── Visa/MasterCard: info banner (form is in payment gateway) ──
              if (method.requiresCard &&
                  (selectedAmount != null ||
                      customAmountCtrl.text.isNotEmpty)) ...[
                const SizedBox(height: 20),
                _GatewayInfoBanner(isDark: isDark, method: method),
              ],
              // ── Wallet transfer info: ZainCash / SuperKi ──
              if (method.requiresPhone &&
                  (selectedAmount != null ||
                      customAmountCtrl.text.isNotEmpty)) ...[
                const SizedBox(height: 20),
                _WalletTransferCard(
                  isDark: isDark,
                  method: method,
                  amount: selectedAmount ??
                      double.tryParse(
                          customAmountCtrl.text.replaceAll(',', '')),
                ),
              ],
              const SizedBox(height: 24),
              _DonateButton(
                isDark: isDark,
                method: method,
                loading: loading,
                amount: selectedAmount ??
                    double.tryParse(customAmountCtrl.text.replaceAll(',', '')),
                onTap: () async {
                  final amt = selectedAmount ??
                      double.tryParse(
                          customAmountCtrl.text.replaceAll(',', ''));
                  if (amt == null) {
                    _snackErr(context, 'الرجاء اختيار أو إدخال مبلغ');
                    return;
                  }

                  // ── Visa/MasterCard → بوابة دفع خارجية (WebView) ──
                  if (method.requiresCard) {
                    final donorName =
                        ref.read(authProvider).user?.name ?? 'متبرع';

                    // Create checkout session first (should return redirectUrl)
                    final notifier = ref.read(paymentFlowProvider.notifier);
                    notifier.selectCard(selectedIdx, _toMethodType(method));
                    await notifier.startCheckout(
                      amount: amt,
                      currency: PaymentCurrency.iqd,
                      donorName: donorName,
                      donationId:
                          'DON-${DateTime.now().millisecondsSinceEpoch}',
                    );

                    final session = ref.read(paymentFlowProvider).session;
                    final redirectUrl = session?.redirectUrl;
                    if (redirectUrl == null || redirectUrl.isEmpty) {
                      if (context.mounted) {
                        _snackErr(context,
                            'بوابة الدفع غير مهيّأة حالياً (لا يوجد رابط تحويل).');
                      }
                      return;
                    }

                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => _PaymentGatewayPage(
                          method: method,
                          redirectUrl: redirectUrl,
                        ),
                      ),
                    );
                    // Never treat WebView result as success without backend confirmation.
                    final ok = result == true &&
                        session != null &&
                        (await _confirmBackendPaid(ref, session.sessionId));
                    if (ok && context.mounted) {
                      ref.read(donationsProvider.notifier).addTransfer(
                            donor: donorName,
                            amount: amt,
                            method: method,
                          );
                      ref.read(operationsProvider.notifier).addOperation(
                            action: 'تبرع ${method.labelAr}',
                            description:
                                'تبرع ${NumberFormat('#,###', 'ar').format(amt.round())} د.ع عبر ${method.labelAr}',
                            user: donorName,
                            color: method.accentColor,
                            icon: method.icon,
                          );
                      ref.read(selectedAmountProvider.notifier).set(null);
                      customAmountCtrl.clear();
                      tabController.animateTo(1);
                    } else if (result == true && context.mounted) {
                      _snackErr(
                          context, 'لم يتم تأكيد الدفع بعد. حاول مجدداً.');
                    }
                    return;
                  }

                  // ── المحافظ الإلكترونية: تأكيد خارجي ──
                  if (method.requiresPhone) {
                    final donorName =
                        ref.read(authProvider).user?.name ?? 'متبرع';

                    // Create checkout session then open hosted payment page
                    final notifier = ref.read(paymentFlowProvider.notifier);
                    notifier.selectCard(selectedIdx, _toMethodType(method));
                    await notifier.startCheckout(
                      amount: amt,
                      currency: PaymentCurrency.iqd,
                      donorName: donorName,
                      donationId:
                          'DON-${DateTime.now().millisecondsSinceEpoch}',
                    );

                    final session = ref.read(paymentFlowProvider).session;
                    final redirectUrl = session?.redirectUrl;
                    if (redirectUrl == null || redirectUrl.isEmpty) {
                      if (context.mounted) {
                        _snackErr(context,
                            'بوابة الدفع غير مهيّأة حالياً (لا يوجد رابط تحويل).');
                      }
                      return;
                    }

                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => _PaymentGatewayPage(
                          method: method,
                          redirectUrl: redirectUrl,
                        ),
                      ),
                    );

                    final ok = result == true &&
                        session != null &&
                        (await _confirmBackendPaid(ref, session.sessionId));
                    if (!context.mounted) return;

                    if (ok) {
                      ref.read(donationsProvider.notifier).addTransfer(
                            donor: donorName,
                            amount: amt,
                            method: method,
                          );
                      ref.read(operationsProvider.notifier).addOperation(
                            action: 'تبرع ${method.labelAr}',
                            description:
                                'تبرع ${NumberFormat('#,###', 'ar').format(amt.round())} د.ع عبر ${method.labelAr}',
                            user: donorName,
                            color: method.accentColor,
                            icon: method.icon,
                          );
                      ref.read(selectedAmountProvider.notifier).set(null);
                      customAmountCtrl.clear();
                      tabController.animateTo(1);
                    } else if (result == true) {
                      _snackErr(
                          context, 'لم يتم تأكيد الدفع بعد. حاول مجدداً.');
                    }
                    return;
                  }

                  // ── Build payment input (card / bank / cash) ──
                  final PaymentInput input;
                  if (method == PaymentMethod.bankTransfer) {
                    input = BankTransferPaymentInput(
                      accountHolder:
                          ref.read(authProvider).user?.name ?? 'متبرع',
                      bankName: 'بنك الرشيد',
                    );
                  } else {
                    input = CashPaymentInput(
                      receiverName: ref.read(authProvider).user?.name,
                    );
                  }

                  // ── Start payment flow (card / bank / cash) ──
                  final donorName =
                      ref.read(authProvider).user?.name ?? 'متبرع';
                  final notifier = ref.read(paymentFlowProvider.notifier);

                  notifier.selectCard(selectedIdx, _toMethodType(method));

                  await notifier.startCheckout(
                    amount: amt,
                    currency: PaymentCurrency.iqd,
                    donorName: donorName,
                    donationId: 'DON-${DateTime.now().millisecondsSinceEpoch}',
                  );

                  if (context.mounted) {
                    await notifier.submitPayment(input);
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

  void _snackErr(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
  }
}

// ── Visa/MasterCard Payment Gateway (WebView) ──────────────────────────────────
// بدلاً من إدخال بيانات البطاقة داخل التطبيق، نفتح صفحة ويب (Hosted Page)
// بحيث يتم إدخال بيانات البطاقة وOTP داخل WebView.
class _PaymentGatewayPage extends StatefulWidget {
  final PaymentMethod method;
  final String redirectUrl;

  const _PaymentGatewayPage({
    required this.method,
    required this.redirectUrl,
  });

  @override
  State<_PaymentGatewayPage> createState() => _PaymentGatewayPageState();
}

class _PaymentGatewayPageState extends State<_PaymentGatewayPage> {
  late final WebViewController _controller;
  bool _loading = true;

  // Adjust these to match your payment provider's final redirect URLs.
  static const _successPath = '/payment/success';
  static const _cancelPath = '/payment/cancel';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final url = req.url;
            if (url.contains(_successPath)) {
              if (mounted) Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            if (url.contains(_cancelPath)) {
              if (mounted) Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title =
        widget.method == PaymentMethod.visaCard ? 'Visa' : 'MasterCard';

    return Scaffold(
      appBar: AppBar(
        title: Text('بوابة دفع آمنة — $title',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                )),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            Container(
              color: (isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight)
                  .withValues(alpha: 0.6),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

Future<bool> _confirmBackendPaid(WidgetRef ref, String sessionId) async {
  try {
    final registry = ref.read(paymentProviderRegistryProvider);
    // Use backend provider (supports redirect flows)
    final provider = registry.forMethod(PaymentMethodType.visa) ??
        registry.forMethod(PaymentMethodType.zaincash);
    if (provider == null) return false;
    final s = await provider.checkStatus(sessionId);
    return s.status == PaymentSessionStatus.completed;
  } catch (_) {
    return false;
  }
}

// ── Wallet Transfer Card (ZainCash / SuperKi) ────────────────────────────────
// الأرقام الرسمية للمؤسسة — يجب تحديثها بالأرقام الحقيقية
const _kZainCashOfficialNumber = '07808337805';
const _kSuperKiOfficialNumber = '2012741358';

class _WalletTransferCard extends StatelessWidget {
  final bool isDark;
  final PaymentMethod method;
  final double? amount;

  const _WalletTransferCard({
    required this.isDark,
    required this.method,
    this.amount,
  });

  String get _officialNumber => method == PaymentMethod.zainCash
      ? _kZainCashOfficialNumber
      : _kSuperKiOfficialNumber;

  String get _appLabel =>
      method == PaymentMethod.zainCash ? 'تطبيق زين كاش' : 'تطبيق سوبر كي';

  Future<void> _openApp(BuildContext context) async {
    final packageName = method == PaymentMethod.zainCash
        ? 'mobi.foo.zaincash'
        : 'iq.qicard.qipay.prod';
    final storeUrl = method == PaymentMethod.zainCash
        ? 'https://play.google.com/store/apps/details?id=mobi.foo.zaincash'
        : 'https://play.google.com/store/apps/details?id=iq.qicard.qipay.prod';
    await _openAppOrStore(packageName, storeUrl);
  }

  @override
  Widget build(BuildContext context) {
    final accent = method.accentColor;
    final amtText = amount != null
        ? NumberFormat('#,###', 'ar').format(amount!.round())
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(method.icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Text('حوّل عبر ${method.labelAr}',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              )),
        ]),
        const SizedBox(height: 16),

        // الرقم الرسمي + نسخ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('حوّل إلى رقم المؤسسة',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight)),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Text(_officialNumber,
                          style: GoogleFonts.robotoMono(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: accent,
                              letterSpacing: 2)),
                    ),
                  ]),
            ),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _officialNumber));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('تم نسخ الرقم', style: GoogleFonts.cairo()),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(12),
                ));
              },
              icon: Icon(Icons.copy_rounded, color: accent, size: 20),
              tooltip: 'نسخ الرقم',
              style: IconButton.styleFrom(
                backgroundColor: accent.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ]),
        ),

        // المبلغ
        if (amtText != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('المبلغ المطلوب',
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight)),
                  Text('$amtText د.ع',
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: accent)),
                ]),
          ),
        ],
        const SizedBox(height: 14),

        // زر فتح التطبيق
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openApp(context),
            icon: Icon(Icons.open_in_new_rounded, size: 16, color: accent),
            label: Text('فتح $_appLabel',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700, color: accent)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: accent, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, color: accent, size: 13),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'افتح $_appLabel وحوّل المبلغ إلى الرقم أعلاه، ثم اضغط "تبرع الآن" لتسجيل التبرع.',
              style:
                  GoogleFonts.cairo(fontSize: 10, color: accent, height: 1.5),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Card Details Form ──────────────────────────────────────────────────────────

class _CardDetailsForm extends StatelessWidget {
  final bool isDark;
  final PaymentMethod method;
  final TextEditingController cardNumberCtrl;
  final TextEditingController cardHolderCtrl;
  final TextEditingController cardExpiryCtrl;
  final TextEditingController cardCvvCtrl;

  const _CardDetailsForm({
    required this.isDark,
    required this.method,
    required this.cardNumberCtrl,
    required this.cardHolderCtrl,
    required this.cardExpiryCtrl,
    required this.cardCvvCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final accent = method == PaymentMethod.visaCard
        ? const Color(0xFFFFD700)
        : const Color(0xFFFF6B6B);
    final bg =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final labelStyle = GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight);
    final inputStyle = GoogleFonts.robotoMono(
        fontSize: 14,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    InputDecoration fieldDeco(String hint, IconData icon) => InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.robotoMono(
              fontSize: 13,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight),
          prefixIcon: Icon(icon, color: accent, size: 18),
          filled: true,
          fillColor: bg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.5)),
        );

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.07 : 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.lock_rounded, color: accent, size: 16),
              ),
              const SizedBox(width: 10),
              Text('بيانات البطاقة',
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.shield_rounded,
                      color: Color(0xFF10B981), size: 11),
                  const SizedBox(width: 4),
                  Text('SSL 256-bit',
                      style: GoogleFonts.cairo(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981))),
                ]),
              ),
            ]),
            const SizedBox(height: 14),

            // Card number
            Text('رقم البطاقة', style: labelStyle),
            const SizedBox(height: 6),
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: TextFormField(
                controller: cardNumberCtrl,
                style: inputStyle,
                keyboardType: TextInputType.number,
                maxLength: 19, // 16 digits + 3 spaces
                decoration:
                    fieldDeco('XXXX XXXX XXXX XXXX', Icons.credit_card_rounded)
                        .copyWith(counterText: ''),
                onChanged: (v) {
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  final formatted = _formatCardNumber(digits);
                  if (formatted != v) {
                    cardNumberCtrl.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // Card holder name
            Text('اسم حامل البطاقة', style: labelStyle),
            const SizedBox(height: 6),
            TextFormField(
              controller: cardHolderCtrl,
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.characters,
              decoration: fieldDeco('CARD HOLDER NAME', Icons.person_rounded),
            ),
            const SizedBox(height: 12),

            // Expiry + CVV row
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تاريخ الانتهاء', style: labelStyle),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: cardExpiryCtrl,
                      style: inputStyle,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      decoration:
                          fieldDeco('MM/YY', Icons.calendar_month_rounded)
                              .copyWith(counterText: ''),
                      onChanged: (v) {
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        String formatted = digits;
                        if (digits.length >= 2) {
                          formatted =
                              '${digits.substring(0, 2)}/${digits.substring(2)}';
                        }
                        if (formatted != v) {
                          cardExpiryCtrl.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                                offset: formatted.length),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('رمز CVV', style: labelStyle),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: cardCvvCtrl,
                      style: inputStyle,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      obscureText: true,
                      decoration: fieldDeco('•••', Icons.security_rounded)
                          .copyWith(counterText: ''),
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 10),
            // Hint about test cards
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.amber, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'بطاقة وهمية ستُرفض. استخدم بيانات بطاقة حقيقية وصالحة.',
                    style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.amber.shade700,
                        height: 1.4),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCardNumber(String digits) {
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

// ── Method Info Card ──────────────────────────────────────────────────────────

class _MethodInfoCard extends StatelessWidget {
  final PaymentMethod method;
  final bool isDark;

  const _MethodInfoCard({required this.method, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, instructions) = _getDetails(method);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(method),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: method.accentColor.withValues(alpha: isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: method.accentColor.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: method.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(method.icon, color: method.accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight)),
              Text(subtitle,
                  style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight)),
            ]),
          ]),
          const SizedBox(height: 12),
          ...instructions.map((ins) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin:
                            const EdgeInsets.only(top: 6, left: 8, right: 2),
                        decoration: BoxDecoration(
                            color: method.accentColor, shape: BoxShape.circle),
                      ),
                      Expanded(
                          child: Text(ins,
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                  height: 1.5))),
                    ]),
              )),
        ]),
      ),
    );
  }

  (String, String, List<String>) _getDetails(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.zainCash:
        return (
          'زين كاش',
          'المحفظة الإلكترونية',
          [
            'رقم المحفظة: 0781-884-712',
            'ستصلك رسالة تأكيد فورية',
            'عمولة: 0.5% من قيمة التبرع'
          ]
        );
      case PaymentMethod.superKi:
        return (
          'سوبر كي',
          'محفظة سوبر كي',
          [
            'رقم محفظة سوبر كي للاستلام',
            'ستصلك رسالة تأكيد فورية',
            'عمولة: 0.5% من قيمة التبرع'
          ]
        );
      case PaymentMethod.visaCard:
        return (
          'Visa Card',
          'بطاقة فيزا',
          [
            'مدعوم ببطاقات البنوك العراقية',
            'تشفير SSL 256-bit',
            'عمولة: 1.5% من قيمة التبرع'
          ]
        );
      case PaymentMethod.masterCard:
        return (
          'MasterCard',
          'بطاقة ماستركارد',
          [
            'يدعم MasterCard & Maestro',
            'حماية 3D Secure',
            'عمولة: 1.5% من قيمة التبرع'
          ]
        );
      case PaymentMethod.bankTransfer:
        return (
          'تحويل بنكي',
          'التحويل المباشر',
          [
            'اسم المستفيد: جمعية الخير الخيرية',
            'IBAN: IQ72NBIQ000000020001',
            'أرسل الإيصال بعد التحويل'
          ]
        );
      case PaymentMethod.cash:
        return (
          'نقداً',
          'التسليم المباشر',
          [
            'العنوان: بغداد – الكرادة، ش 14 رمضان',
            'ساعات العمل: 9 ص – 5 م',
            'يُمنح إيصال رسمي فور الاستلام'
          ]
        );
    }
  }
}

// ── Quick Amounts ─────────────────────────────────────────────────────────────

class _QuickAmounts extends StatelessWidget {
  final double? selected;
  final ValueChanged<double> onSelect;

  const _QuickAmounts({required this.selected, required this.onSelect});

  static const _amounts = [
    25000.0,
    50000.0,
    100000.0,
    250000.0,
    500000.0,
    1000000.0
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _amounts.map((a) {
        final isSel = selected == a;
        final label = a >= 1000000
            ? '${(a / 1000000).toStringAsFixed(0)}M'
            : NumberFormat('#,###').format(a);
        return GestureDetector(
          onTap: () => onSelect(a),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSel
                  ? const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)
                  : null,
              color: isSel
                  ? null
                  : (isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSel
                      ? Colors.transparent
                      : (isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight)),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]
                  : null,
            ),
            child: Column(children: [
              Text(label,
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSel
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight))),
              Text('د.ع',
                  style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: isSel
                          ? Colors.white.withValues(alpha: 0.75)
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight))),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Custom Amount Field ───────────────────────────────────────────────────────

class _CustomAmountField extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CustomAmountField(
      {required this.isDark,
      required this.controller,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: 'أو أدخل مبلغاً مخصصاً...',
        hintStyle: GoogleFonts.cairo(
            fontSize: 14,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight),
        suffixText: 'د.ع',
        suffixStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary),
        prefixIcon:
            const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Donate Button ─────────────────────────────────────────────────────────────

class _DonateButton extends StatelessWidget {
  final bool isDark, loading;
  final PaymentMethod method;
  final double? amount;
  final VoidCallback onTap;

  const _DonateButton(
      {required this.isDark,
      required this.loading,
      required this.method,
      required this.amount,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final amountText = amount != null
        ? '${NumberFormat('#,###').format(amount)} د.ع'
        : 'اختر مبلغاً';
    final hasAmount = amount != null;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: hasAmount
                  ? const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF059669)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight)
                  : null,
              color: hasAmount
                  ? null
                  : (isDark
                      ? AppColors.surfaceVariantDark
                      : const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: hasAmount
                  ? [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6))
                    ]
                  : null,
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(method.icon,
                          color: hasAmount
                              ? Colors.white
                              : AppColors.textSecondaryLight,
                          size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'تبرع الآن — $amountText',
                        style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: hasAmount
                                ? Colors.white
                                : AppColors.textSecondaryLight),
                      ),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Security Note ─────────────────────────────────────────────────────────────

class _SecurityNote extends StatelessWidget {
  final bool isDark;
  const _SecurityNote({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.lock_rounded, size: 15, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
            'جميع معاملاتك محمية بتشفير SSL 256-bit. بياناتك في أمان تام.',
            style: GoogleFonts.cairo(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          )),
        ]),
      );
}

class _GatewayInfoBanner extends StatelessWidget {
  final bool isDark;
  final PaymentMethod method;

  const _GatewayInfoBanner({required this.isDark, required this.method});

  @override
  Widget build(BuildContext context) {
    final accent = method.accentColor;
    final bg = accent.withValues(alpha: isDark ? 0.10 : 0.08);
    final border = accent.withValues(alpha: 0.28);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.lock_rounded, color: accent, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدخال بيانات البطاقة والـ OTP داخل بوابة دفع آمنة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'لن يتم إدخال بيانات البطاقة داخل التطبيق.',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  height: 1.4,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Transfer History Tab ──────────────────────────────────────────────────────

class _TransferHistoryTab extends ConsumerStatefulWidget {
  final bool isDark;
  final bool isAdmin;

  const _TransferHistoryTab({required this.isDark, required this.isAdmin});

  @override
  ConsumerState<_TransferHistoryTab> createState() =>
      _TransferHistoryTabState();
}

class _TransferHistoryTabState extends ConsumerState<_TransferHistoryTab> {
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
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        // ── Summary card ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            color: Colors.white.withValues(alpha: 0.8))),
                    Text('${NumberFormat('#,###').format(totalCompleted)} د.ع',
                        style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ])),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    onTap: () => _showAddDonationDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
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
                onChanged: (v) =>
                    ref.read(donationSearchProvider.notifier).set(v),
                style: GoogleFonts.cairo(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'بحث عن متبرع أو رقم مرجعي...',
                  hintStyle: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 1.5)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _FilterChip(
                    label: 'الكل',
                    selected: statusFilter == null && methodFilter == null,
                    color: AppColors.primary,
                    onTap: () {
                      ref.read(donationStatusFilterProvider.notifier).set(null);
                      ref.read(donationMethodFilterProvider.notifier).set(null);
                    },
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'مكتمل',
                    selected: statusFilter == 'مكتمل',
                    color: AppColors.success,
                    onTap: () => ref
                        .read(donationStatusFilterProvider.notifier)
                        .set(statusFilter == 'مكتمل' ? null : 'مكتمل'),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'قيد المعالجة',
                    selected: statusFilter == 'قيد المعالجة',
                    color: AppColors.warning,
                    onTap: () => ref
                        .read(donationStatusFilterProvider.notifier)
                        .set(statusFilter == 'قيد المعالجة'
                            ? null
                            : 'قيد المعالجة'),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'مرفوض',
                    selected: statusFilter == 'مرفوض',
                    color: AppColors.error,
                    onTap: () => ref
                        .read(donationStatusFilterProvider.notifier)
                        .set(statusFilter == 'مرفوض' ? null : 'مرفوض'),
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
                            .read(donationMethodFilterProvider.notifier)
                            .set(methodFilter == m ? null : m),
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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                    onTap: () => _showDetailSheet(ctx, transfers[i]),
                  ),
                ),
                childCount: transfers.length,
              ),
            ),
          ),
      ],
    );
  }

  void _showDetailSheet(BuildContext context, TransferRecord t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TransferDetailSheet(
          transfer: t, isDark: widget.isDark, isAdmin: widget.isAdmin),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: donorCtrl,
                decoration: InputDecoration(
                  labelText: 'اسم المتبرع',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                style: GoogleFonts.cairo(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'المبلغ (د.ع)',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
                style: GoogleFonts.cairo(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: selectedMethod,
                onChanged: (v) => setDlgState(() => selectedMethod = v!),
                decoration: InputDecoration(
                  labelText: 'طريقة الدفع',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: PaymentMethod.values
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.labelAr, style: GoogleFonts.cairo()),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                onChanged: (v) => setDlgState(() => selectedStatus = v!),
                decoration: InputDecoration(
                  labelText: 'الحالة',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: ['مكتمل', 'قيد المعالجة', 'مرفوض']
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, style: GoogleFonts.cairo()),
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
                final amt = double.tryParse(amountCtrl.text.trim());
                if (donorCtrl.text.trim().isNotEmpty && amt != null) {
                  ref.read(donationsProvider.notifier).addTransfer(
                        donor: donorCtrl.text.trim(),
                        amount: amt,
                        method: selectedMethod,
                        status: selectedStatus,
                      );
                  ref.read(operationsProvider.notifier).addOperation(
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
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child:
                  Text('إضافة', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final TransferRecord transfer;
  final bool isDark, isAdmin;
  final VoidCallback onTap;

  const _TransferCard(
      {required this.transfer,
      required this.isDark,
      required this.isAdmin,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                spreadRadius: -3,
                offset: const Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  transfer.avatarColor,
                  transfer.avatarColor.withValues(alpha: 0.7)
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: transfer.avatarColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Center(
                  child: Text(transfer.avatarInitials,
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transfer.donor,
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: transfer.method.accentColor
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(transfer.method.labelAr,
                            style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: transfer.method.accentColor,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Text(transfer.reference,
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight)),
                    ]),
                  ]),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(NumberFormat('#,###').format(transfer.amount),
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight)),
              Text('د.ع',
                  style: GoogleFonts.cairo(
                      fontSize: 9,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: transfer.statusBg,
                    borderRadius: BorderRadius.circular(7)),
                child: Text(transfer.status,
                    style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: transfer.statusColor)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Transfer Detail Bottom Sheet ──────────────────────────────────────────────

class _TransferDetailSheet extends ConsumerWidget {
  final TransferRecord transfer;
  final bool isDark, isAdmin;

  const _TransferDetailSheet(
      {required this.transfer, required this.isDark, required this.isAdmin});

  void _showReceiptDialog(BuildContext context, TransferRecord t, bool dark) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 12),
            Text('إيصال التبرع',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('منظمة الخيرية',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
            const Divider(height: 24),
            _ReceiptRow(label: 'المتبرع', value: t.donor, isDark: dark),
            _ReceiptRow(
                label: 'المبلغ',
                value: '${NumberFormat('#,###').format(t.amount)} د.ع',
                isDark: dark),
            _ReceiptRow(
                label: 'طريقة الدفع', value: t.method.labelAr, isDark: dark),
            _ReceiptRow(label: 'رقم المرجع', value: t.reference, isDark: dark),
            _ReceiptRow(label: 'رقم العملية', value: t.id, isDark: dark),
            _ReceiptRow(
                label: 'التاريخ',
                value: DateFormat('dd/MM/yyyy – hh:mm a').format(t.date),
                isDark: dark),
            _ReceiptRow(label: 'الحالة', value: t.status, isDark: dark),
            const Divider(height: 24),
            Text('شكراً لتبرعكم الكريم',
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text('إغلاق',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                transfer.avatarColor,
                transfer.avatarColor.withValues(alpha: 0.7)
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: transfer.avatarColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Center(
                child: Text(transfer.avatarInitials,
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white))),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(transfer.donor,
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight)),
                Text(transfer.method.labelAr,
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: transfer.method.accentColor,
                        fontWeight: FontWeight.w600)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: transfer.statusBg,
                borderRadius: BorderRadius.circular(10)),
            child: Text(transfer.status,
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: transfer.statusColor)),
          ),
        ]),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: transfer.method.cardGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: transfer.method.accentColor.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Column(children: [
            Text('المبلغ المحوّل',
                style: GoogleFonts.cairo(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
            const SizedBox(height: 4),
            Text('${NumberFormat('#,###').format(transfer.amount)} د.ع',
                style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          ),
          child: Column(children: [
            _DetailRow(
                label: 'رقم المرجع', value: transfer.reference, isDark: isDark),
            const SizedBox(height: 10),
            _DetailRow(
                label: 'طريقة الدفع',
                value: transfer.method.labelAr,
                isDark: isDark),
            const SizedBox(height: 10),
            _DetailRow(
                label: 'التاريخ',
                value: DateFormat('dd/MM/yyyy').format(transfer.date),
                isDark: isDark),
            const SizedBox(height: 10),
            _DetailRow(
                label: 'الوقت',
                value: DateFormat('hh:mm a').format(transfer.date),
                isDark: isDark),
            const SizedBox(height: 10),
            _DetailRow(
                label: 'رقم العملية', value: transfer.id, isDark: isDark),
          ]),
        ),
        // Admin: change status
        if (isAdmin && transfer.status == 'قيد المعالجة') ...[
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ref
                      .read(donationsProvider.notifier)
                      .updateStatus(transfer.id, 'مرفوض');
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text('رفض',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700, color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(donationsProvider.notifier)
                      .updateStatus(transfer.id, 'مكتمل');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('تم تأكيد التحويل', style: GoogleFonts.cairo()),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: Text('تأكيد',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ],
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: Text('إغلاق',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showReceiptDialog(context, transfer, isDark);
              },
              icon: const Icon(Icons.receipt_long_rounded, size: 16),
              label: Text('طباعة الإيصال',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool isDark;

  const _DetailRow(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: GoogleFonts.cairo(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight)),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight)),
      ]);
}

// ── Operations Log Tab ────────────────────────────────────────────────────────

class _OperationsLogTab extends ConsumerWidget {
  final bool isDark;

  const _OperationsLogTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operations = ref.watch(operationsProvider);
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              const Icon(Icons.history_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('سجل العمليات',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8))),
                    Text('تتبع كامل لجميع العمليات المنجزة',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ])),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
      {required this.operation, required this.isDark, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 40,
          child: Column(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: operation.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: operation.color.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Icon(operation.icon, size: 16, color: operation.color),
            ),
            if (!isLast)
              Expanded(
                  child: Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      operation.color.withValues(alpha: 0.4),
                      operation.color.withValues(alpha: 0.05)
                    ],
                  ),
                ),
              )),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color:
                        operation.color.withValues(alpha: isDark ? 0.2 : 0.1)),
                boxShadow: [
                  BoxShadow(
                      color: operation.color.withValues(alpha: 0.08),
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
                      Text(DateFormat('dd/MM').format(operation.date),
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
                      Text(DateFormat('hh:mm a').format(operation.date),
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight)),
                    ]),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Receipt Row ───────────────────────────────────────────────────────────────

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _ReceiptRow(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade600)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87)),
            ),
          ],
        ),
      );
}

// ── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _SectionTitle(
      {required this.title, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight)),
      ]);
}
