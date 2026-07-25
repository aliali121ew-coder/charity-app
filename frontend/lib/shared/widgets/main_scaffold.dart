import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/core/localization/app_localizations.dart';
import 'package:charity_app/core/router/app_router.dart';
import 'package:charity_app/core/permissions/role.dart';
import 'package:charity_app/shared/providers/app_providers.dart';

part 'main_scaffold_bottom_nav.dart';
part 'main_scaffold_top_bar.dart';
part 'main_scaffold_drawer.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  final String currentPath;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final isRtl = locale.languageCode == 'ar';

    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final topBarHeight = 56.0 + topPadding;
    final bottomBarHeight = 64.0 + (bottomPadding > 0 ? bottomPadding + 2.0 : 8.0);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: _AppDrawer(currentPath: widget.currentPath),
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.vertical) {
              if (notification is ScrollStartNotification) {
                _controller.stop();
              } else if (notification is ScrollUpdateNotification &&
                  notification.scrollDelta != null) {
                final delta = notification.scrollDelta!;
                if (topBarHeight > 0) {
                  _controller.value =
                      (_controller.value - delta / topBarHeight).clamp(0.0, 1.0);
                }
              } else if (notification is ScrollEndNotification) {
                // إكمال الظهور/الإخفاء بنعومة وبطء مريح (لا بسرعة).
                const snap = Duration(milliseconds: 420);
                if (notification.metrics.pixels <= 0) {
                  _controller.animateTo(1.0, duration: snap, curve: Curves.easeOutCubic);
                } else if (_controller.value > 0.5) {
                  _controller.animateTo(1.0, duration: snap, curve: Curves.easeOutCubic);
                } else {
                  _controller.animateTo(0.0, duration: snap, curve: Curves.easeOutCubic);
                }
              }
            }
            return false;
          },
          child: Column(
            children: [
              SizedBox(
                height: topBarHeight * _controller.value,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: 0.0,
                    maxHeight: topBarHeight,
                    child: _AppTopBar(currentPath: widget.currentPath),
                  ),
                ),
              ),
              Expanded(
                child: widget.child,
              ),
              Builder(
                builder: (context) {
                  // الشريط ينزلق صاعداً من الحافة السفلية (نقطة ثابتة) حسب التمرير،
                  // ويختفي تماماً عند التمرير للأسفل — كسلوك فيسبوك.
                  final reveal = _controller.value.clamp(0.0, 1.0);
                  return SizedBox(
                    height: bottomBarHeight * reveal,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        minHeight: 0.0,
                        maxHeight: bottomBarHeight,
                        child: _BottomNavBar(currentPath: widget.currentPath),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────
