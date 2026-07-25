import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/core/permissions/role.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import '../providers/donations_provider.dart';

part '../widgets/donations_header.dart';
part '../widgets/donate_now_tab.dart';
part '../widgets/donate_card.dart';
part '../widgets/donate_form.dart';
part '../widgets/transfer_history_tab.dart';
part '../widgets/transfer_card.dart';
part '../widgets/transfer_detail.dart';
part '../widgets/operations_log_tab.dart';

// ── Main Page ─────────────────────────────────────────────────────────────────

class DonationsPage extends ConsumerStatefulWidget {
  const DonationsPage({super.key});

  @override
  ConsumerState<DonationsPage> createState() => _DonationsPageState();
}

class _DonationsPageState extends ConsumerState<DonationsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _counterCtrl;
  late Animation<double> _counterAnim;
  final _customAmountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    _tabController.dispose();
    _counterCtrl.dispose();
    _customAmountCtrl.dispose();
    super.dispose();
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
    final isAdmin =
        ref.watch(authProvider).user?.role == UserRole.admin;

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
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            tabController: _tabController,
            isDark: isDark,
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _DonateNowTab(
              isDark: isDark,
              customAmountCtrl: _customAmountCtrl,
              tabController: _tabController),
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
        labelStyle:
            GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w500),
        labelColor: AppColors.primary,
        unselectedLabelColor:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
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
