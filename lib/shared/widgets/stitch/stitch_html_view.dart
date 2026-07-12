import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

import '../../../core/design/stitch_screens.dart';
import '../../../core/design/stitch_assets.dart';

// Web iframe renderer (srcdoc) — WebView does not paint reliably on Flutter web.
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
  String? _html;
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
        _html = html;
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
      _html = html;
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
          final scale = constraints.maxWidth / StitchScreens.designWidth;

          Widget content = Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: StitchScreens.designWidth,
                    height: StitchScreens.designHeight,
                    child: kIsWeb && _webViewType != null
                        ? StitchHtmlIframe(viewType: _webViewType!)
                        : _controller != null
                            ? IgnorePointer(
                                ignoring: !widget.interactive,
                                child: WebViewWidget(controller: _controller!),
                              )
                            : const SizedBox.shrink(),
                  ),
                ),
              ),
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

          return content;
        },
      ),
    );
  }
}

void ensureStitchWebViewInitialized() {
  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }
}
