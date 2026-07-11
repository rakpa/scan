import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/documents/presentation/document_detail_screen.dart';
import '../../features/documents/presentation/document_list_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/paywall/presentation/paywall_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

/// Application routes.
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const paywall = '/paywall';
  static const home = '/home';
  static const library = '/library';
  static const document = '/document/:id';
}

/// go_router instance exposed as a provider so future guards (e.g. app-lock)
/// can read other providers.
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
        path: Routes.document,
        builder: (context, state) => DocumentDetailScreen(
          documentId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
