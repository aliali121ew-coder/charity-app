import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:charity_app/features/auth/presentation/pages/login_page.dart';
import 'package:charity_app/features/subscribers/presentation/pages/subscribers_page.dart';
import 'package:charity_app/features/families/presentation/pages/families_page.dart';
import 'package:charity_app/features/aid/presentation/pages/aid_page.dart';
import 'package:charity_app/features/logs/presentation/pages/logs_page.dart';
import 'package:charity_app/features/reports/presentation/pages/reports_page.dart';
import 'package:charity_app/features/settings/presentation/pages/settings_page.dart';
import 'package:charity_app/features/works/presentation/pages/works_page.dart';
import 'package:charity_app/features/help_requests/presentation/pages/help_requests_list_page.dart';
import 'package:charity_app/features/donations/presentation/pages/donations_page.dart';
import 'package:charity_app/features/competitions/presentation/pages/competitions_page.dart';
import 'package:charity_app/features/ibadat/presentation/pages/ibadat_page.dart';
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
  static const String subscribers = '/subscribers';
  static const String families = '/families';
  static const String aid = '/aid';
  static const String logs = '/logs';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String works = '/works';
  static const String helpRequests = '/help-requests';
  static const String helpRequestLocation = '/help-requests/location';
  static const String helpRequestType = '/help-requests/type';
  static const String donations = '/donations';
  static const String competitions = '/competitions';
  static const String ibadat = '/ibadat';
  static const String authEmail = '/auth/email';
  static const String authForgot = '/auth/forgot';
  static const String feedCreate = '/works/create';
  static const String feedDetail = '/works/detail';
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
      // StatefulShellRoute keeps each tab's page alive in an IndexedStack, so
      // switching between pages no longer destroys and rebuilds them. Branches
      // are built lazily on first visit and preserved thereafter.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => PopScope(
          canPop: false,
          child: MainScaffold(
            currentPath: state.matchedLocation,
            child: navigationShell,
          ),
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.subscribers,
              name: 'subscribers',
              builder: (context, state) => const SubscribersPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.families,
              name: 'families',
              builder: (context, state) => const FamiliesPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.aid,
              name: 'aid',
              builder: (context, state) => const AidPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.logs,
              name: 'logs',
              builder: (context, state) => const LogsPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.reports,
              name: 'reports',
              builder: (context, state) => const ReportsPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.works,
              name: 'works',
              builder: (context, state) => const WorksPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.competitions,
              name: 'competitions',
              builder: (context, state) => const CompetitionsPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.ibadat,
              name: 'ibadat',
              builder: (context, state) => const IbadatPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.helpRequests,
              name: 'helpRequests',
              builder: (context, state) => const HelpRequestsListPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.donations,
              name: 'donations',
              builder: (context, state) => const DonationsPage(),
            ),
          ]),
        ],
      ),

      // ── Help Requests multi-step flow (outside shell) ──────────────────
      GoRoute(
        path: '/help-requests/location/:type',
        name: 'helpRequestLocation',
        builder: (context, state) => LocationStepPage(
          typeName: state.pathParameters['type'] ?? 'generalHelp',
        ),
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
