import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/features/auth/presentation/pages/login_page.dart';
import 'package:charity_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:charity_app/features/subscribers/presentation/pages/subscribers_page.dart';
import 'package:charity_app/features/families/presentation/pages/families_page.dart';
import 'package:charity_app/features/aid/presentation/pages/aid_page.dart';
import 'package:charity_app/features/logs/presentation/pages/logs_page.dart';
import 'package:charity_app/features/reports/presentation/pages/reports_page.dart';
import 'package:charity_app/features/settings/presentation/pages/settings_page.dart';
import 'package:charity_app/features/works/presentation/pages/works_page.dart';
import 'package:charity_app/features/works/presentation/pages/feed_page.dart';
import 'package:charity_app/features/works/presentation/pages/post_detail_page.dart';
import 'package:charity_app/features/works/presentation/pages/create_post_page.dart';
import 'package:charity_app/features/help_requests/presentation/pages/help_requests_list_page.dart';
import 'package:charity_app/features/donations/presentation/pages/donations_page.dart';
import 'package:charity_app/features/help_requests/presentation/pages/location_step_page.dart';
import 'package:charity_app/features/help_requests/presentation/pages/request_type_selector_page.dart';
import 'package:charity_app/features/help_requests/presentation/pages/help_request_form_page.dart';
import 'package:charity_app/features/help_requests/presentation/pages/help_request_details_page.dart';
import 'package:charity_app/shared/widgets/main_scaffold.dart';
import 'package:charity_app/features/splash/presentation/pages/splash_page.dart';

// ── Route Names ──────────────────────────────────────────────────────────────
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String subscribers = '/subscribers';
  static const String families = '/families';
  static const String aid = '/aid';
  static const String logs = '/logs';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String works = '/works';
  static const String feed = '/feed';
  static const String feedDetail = '/feed/post';
  static const String feedCreate = '/feed/create';
  static const String helpRequests = '/help-requests';
  static const String helpRequestLocation = '/help-requests/location';
  static const String helpRequestType = '/help-requests/type';
  static const String donations = '/donations';
}

// ── Router Provider ───────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(authRouterNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider).isAuthenticated;
      final onSplash = state.matchedLocation == AppRoutes.splash;
      final onLogin = state.matchedLocation == AppRoutes.login;

      // Let splash play freely; do not redirect away from it
      if (onSplash) return null;
      if (!isLoggedIn && !onLogin) return AppRoutes.login;
      if (isLoggedIn && onLogin) return AppRoutes.works;
      return null;
    },
    routes: [
      // ── Splash ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // ── Auth ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // ── Main Shell ────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => PopScope(
          canPop: false,
          child: MainScaffold(currentPath: state.matchedLocation, child: child),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.subscribers,
            name: 'subscribers',
            builder: (context, state) => const SubscribersPage(),
          ),
          GoRoute(
            path: AppRoutes.families,
            name: 'families',
            builder: (context, state) => const FamiliesPage(),
          ),
          GoRoute(
            path: AppRoutes.aid,
            name: 'aid',
            builder: (context, state) => const AidPage(),
          ),
          GoRoute(
            path: AppRoutes.logs,
            name: 'logs',
            builder: (context, state) => const LogsPage(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.works,
            name: 'works',
            builder: (context, state) => const WorksPage(),
          ),
          GoRoute(
            path: AppRoutes.helpRequests,
            name: 'helpRequests',
            builder: (context, state) => const HelpRequestsListPage(),
          ),
          GoRoute(
            path: AppRoutes.donations,
            name: 'donations',
            builder: (context, state) => const DonationsPage(),
          ),
          GoRoute(
            path: AppRoutes.feed,
            name: 'feed',
            builder: (context, state) => const FeedPage(),
          ),
        ],
      ),

      // ── Feed routes (outside shell, full screen) ───────────────────────
      GoRoute(
        path: '${AppRoutes.feedDetail}/:id',
        name: 'feedDetail',
        builder: (context, state) => PostDetailPage(
          postId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.feedCreate,
        name: 'feedCreate',
        builder: (context, state) => const CreatePostPage(),
      ),

      // ── Help Requests multi-step flow (outside shell) ──────────────────
      GoRoute(
        path: AppRoutes.helpRequestLocation,
        name: 'helpRequestLocation',
        builder: (context, state) => const LocationStepPage(),
      ),
      GoRoute(
        path: AppRoutes.helpRequestType,
        name: 'helpRequestType',
        builder: (context, state) => const RequestTypeSelectorPage(),
      ),
      GoRoute(
        path: '/help-requests/form/:type',
        name: 'helpRequestForm',
        builder: (context, state) => HelpRequestFormPage(
          typeName: state.pathParameters['type'] ?? 'generalHelp',
        ),
      ),
      GoRoute(
        path: '/help-requests/:id',
        name: 'helpRequestDetails',
        builder: (context, state) => HelpRequestDetailsPage(
          requestId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/help-requests/:id/edit',
        name: 'helpRequestEdit',
        builder: (context, state) => HelpRequestFormPage(
          typeName: 'generalHelp',
          editId: state.pathParameters['id'],
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
