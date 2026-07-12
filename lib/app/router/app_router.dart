import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/documents/domain/entities.dart';
import '../../features/documents/presentation/document_detail_screen.dart';
import '../../features/documents/presentation/document_list_screen.dart';
import '../../features/enhance/presentation/enhance_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/paywall/presentation/paywall_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

/// Application routes.
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const paywall = '/paywall';
  static const home = '/home';
  static const library = '/library';
  static const settings = '/settings';
  static const document = '/document/:id';
  static const enhance =
      '/document/:id/page/:pageId/enhance';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.library,
        builder: (context, state) => const DocumentListScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.document,
        builder: (context, state) => DocumentDetailScreen(
          documentId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'page/:pageId/enhance',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final page = extra?['page'] as ScanPage?;
              if (page == null) {
                return const Scaffold(
                  body: Center(child: Text('Page not found')),
                );
              }
              return EnhanceScreen(
                page: page,
                documentId: state.pathParameters['id']!,
                pageNumber: extra?['pageNumber'] as int? ?? 1,
                pageTotal: extra?['pageTotal'] as int? ?? 1,
              );
            },
          ),
        ],
      ),
    ],
  );
});
