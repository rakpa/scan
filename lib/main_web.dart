import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/theme/app_theme.dart';
import 'core/design/stitch_assets.dart';
import 'core/design/stitch_screens.dart';
import 'features/documents/domain/entities.dart';
import 'features/documents/presentation/documents_providers.dart';
import 'features/home/presentation/home_dashboard_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'shared/widgets/stitch/stitch_html_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ensureStitchWebViewInitialized();
  runApp(
    ProviderScope(
      overrides: [
        documentListProvider.overrideWith(
          (ref) => Stream.value(_demoDocuments),
        ),
      ],
      child: const _WebPreviewApp(),
    ),
  );
}

final _demoDocuments = [
  DocumentSummary(
    document: ScanDocument(
      id: 'demo-1',
      title: 'Scan 2024-10-24 09:15',
      createdAt: DateTime(2024, 10, 24, 9, 15),
      updatedAt: DateTime(2024, 10, 24, 9, 15),
    ),
    pageCount: 2,
    thumbnailPath: null,
  ),
  DocumentSummary(
    document: ScanDocument(
      id: 'demo-2',
      title: 'Scan 2024-10-23 14:02',
      createdAt: DateTime(2024, 10, 23, 14, 2),
      updatedAt: DateTime(2024, 10, 23, 14, 2),
    ),
    pageCount: 1,
    thumbnailPath: null,
  ),
];

final _webRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
    GoRoute(
      path: '/home',
      builder: (c, s) => const _WebHomePreview(),
    ),
    GoRoute(
      path: '/document/:id',
      builder: (c, s) => const _WebDocumentDemo(),
    ),
  ],
);

class _WebHomePreview extends StatefulWidget {
  const _WebHomePreview();

  @override
  State<_WebHomePreview> createState() => _WebHomePreviewState();
}

class _WebHomePreviewState extends State<_WebHomePreview> {
  var _scanBusy = false;

  Future<void> _scan() async {
    setState(() => _scanBusy = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _scanBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanner opens on the installed app.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeDashboardScreen(
      onScan: _scan,
      scanBusy: _scanBusy,
      selectedTab: 0,
    );
  }
}

class _WebDocumentDemo extends StatelessWidget {
  const _WebDocumentDemo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StitchHtmlView(
        htmlAsset: StitchScreens.documentExport,
        backgroundColor: const Color(0xFFF9F9FB),
        interactive: false,
        hotspots: [
          StitchHotspot(
            left: 0.02,
            top: 0.04,
            width: 0.12,
            height: 0.07,
            semanticLabel: 'Back',
            onTap: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _WebPreviewApp extends StatelessWidget {
  const _WebPreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Scanella preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _webRouter,
      builder: (context, child) {
        final size = MediaQuery.sizeOf(context);
        final frameHeight = (size.height * 0.92).clamp(640.0, 920.0);
        final frameWidth =
            frameHeight * (StitchScreens.designWidth / StitchScreens.designHeight);

        return ColoredBox(
          color: const Color(0xFF1a1a1a),
          child: Center(
            child: SizedBox(
              width: frameWidth,
              height: frameHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
