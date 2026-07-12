import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

// NOTE: Do NOT import 'package:webview_flutter_web/webview_flutter_web.dart' here.
// That package (and its transitive dep 'web') pull in dart:js_interop / dart:ui_web
// which are web-only and cause compile errors on iOS/Android builds.
// Web-specific initialization must be done from main.dart (or a web-only entrypoint).

import '../../../core/design/stitch_assets.dart';

import 'stitch_html_view_web.dart' if (dart.library.io) 'stitch_html_view_stub.dart';

/// Renders original Stitch HTML (pixel-perfect) with optional tap hotspots.
class StitchHtmlView extends StatefulWidget {
  const StitchHtmlView({
    super.key,
    required this.htmlAsset,
    this.hotspots = const [],
    this.overlay,
    this.interactive = true,
    this.backgroundColor = Colors.black,
  });

  final String htmlAsset;
  final List<StitchHotspot> hotspots;
  final Widget? overlay;
  final bool interactive;
  final Color backgroundColor;

  @override
  State<StitchHtmlView> createState() => _StitchHtmlViewState();
}

class _StitchHtmlViewState extends State<StitchHtmlView> {
  WebViewController? _controller;
  String? _webViewType;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant StitchHtmlView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlAsset != widget.htmlAsset) {
      _loading = true;
      _init();
    }
  }

  Future<void> _init() async {
    final html = await rootBundle.loadString(widget.htmlAsset);
    if (!mounted) return;

    if (kIsWeb) {
      final viewType = await registerStitchHtmlIframe(html);
      if (!mounted) return;
      setState(() {
        _webViewType = viewType;
        _controller = null;
        _loading = false;
      });
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      );

    await controller.loadHtmlString(html);

    if (!mounted) return;
    setState(() {
      _controller = controller;
      _webViewType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The Stitch exports are responsive mobile pages (viewport meta,
          // dvh heights, centred max-width) — render them at the widget's own
          // size like a phone browser. No Transform.scale: Flutter transforms
          // don't apply to platform views (iframes/WebViews), which showed up
          // as a "cropped" top-left corner on web.
          return Stack(
            fit: StackFit.expand,
            children: [
              kIsWeb && _webViewType != null
                  ? StitchHtmlIframe(viewType: _webViewType!)
                  : _controller != null
                      ? IgnorePointer(
                          ignoring: !widget.interactive,
                          child: WebViewWidget(controller: _controller!),
                        )
                      : const SizedBox.shrink(),
              if (_loading)
                const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (widget.overlay != null) Positioned.fill(child: widget.overlay!),
              ...widget.hotspots.map((h) {
                return Positioned(
                  left: h.left * constraints.maxWidth,
                  top: h.top * constraints.maxHeight,
                  width: h.width * constraints.maxWidth,
                  height: h.height * constraints.maxHeight,
                  child: Semantics(
                    button: true,
                    label: h.semanticLabel,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(onTap: h.onTap),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/// Call this once early in your app (e.g. in main.dart) if you use StitchHtmlView on web.
/// The actual WebWebViewPlatform registration must live in a file that is only
/// imported on web (or inside if (kIsWeb) after a conditional import of webview_flutter_web).
void ensureStitchWebViewInitialized() {
  // Web-specific WebViewPlatform setup has been moved out of this file
  // to prevent pulling web-only packages (webview_flutter_web + web + dart:js_interop*)
  // into iOS/Android builds.
  //
  // Recommended: put the following in your main.dart (or main_web.dart):
  //
  // import 'package:flutter/foundation.dart';
  // import 'package:webview_flutter/webview_flutter.dart';
  // import 'package:webview_flutter_web/webview_flutter_web.dart' show WebWebViewPlatform;
  //
  // void main() {
  //   if (kIsWeb) {
  //     WebViewPlatform.instance = WebWebViewPlatform();
  //   }
  //   runApp(const MyApp());
  // }
}
