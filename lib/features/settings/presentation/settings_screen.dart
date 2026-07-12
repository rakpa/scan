import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/stitch_assets.dart';
import '../../../core/design/stitch_screens.dart';
import '../../../shared/widgets/stitch/stitch_html_view.dart';

/// Settings — Stitch Settings HTML.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: StitchHtmlView(
        htmlAsset: StitchScreens.settings,
        backgroundColor: const Color(0xFFF5F5F7),
        interactive: true,
        hotspots: [
          StitchHotspot(
            left: 0.05,
            top: 0.12,
            width: 0.9,
            height: 0.12,
            semanticLabel: 'Subscription',
            onTap: () => context.push('/paywall'),
          ),
        ],
      ),
    );
  }
}
