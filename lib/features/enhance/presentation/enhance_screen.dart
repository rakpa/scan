import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/stitch_assets.dart';
import '../../../core/design/stitch_screens.dart';
import '../../../shared/widgets/stitch/stitch_html_view.dart';
import '../../documents/domain/entities.dart';
import '../../documents/presentation/documents_providers.dart';
import '../data/image_processor.dart';
import '../domain/doc_filter.dart';

/// Filter & Enhance — Stitch PNG with live filter preview overlay.
class EnhanceScreen extends ConsumerStatefulWidget {
  const EnhanceScreen({
    super.key,
    required this.page,
    required this.documentId,
    this.pageNumber = 1,
    this.pageTotal = 1,
  });

  final ScanPage page;
  final String documentId;
  final int pageNumber;
  final int pageTotal;

  @override
  ConsumerState<EnhanceScreen> createState() => _EnhanceScreenState();
}

class _EnhanceScreenState extends ConsumerState<EnhanceScreen> {
  DocFilter _filter = DocFilter.original;
  double _brightness = 0;
  double _contrast = 0;

  Uint8List? _original;
  Uint8List? _preview;
  bool _processing = false;
  bool _saving = false;
  Timer? _debounce;

  static const _carouselFilters = [
    DocFilter.original,
    DocFilter.magic,
    DocFilter.blackWhite,
    DocFilter.grayscale,
    DocFilter.auto,
  ];

  double get _brightnessFactor => 1 + _brightness * 0.5;
  double get _contrastFactor => 1 + _contrast * 0.5;

  bool get _hasEdits =>
      _filter != DocFilter.original || _brightness != 0 || _contrast != 0;

  @override
  void initState() {
    super.initState();
    _loadOriginal();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadOriginal() async {
    final bytes = await File(widget.page.filePath).readAsBytes();
    if (!mounted) return;
    setState(() {
      _original = bytes;
      _preview = bytes;
    });
  }

  Future<void> _regeneratePreview() async {
    final source = _original;
    if (source == null) return;
    setState(() => _processing = true);

    final result = await ref.read(imageProcessorProvider).process(
          bytes: source,
          filter: _filter,
          brightness: _brightnessFactor,
          contrast: _contrastFactor,
          maxDimension: 1080,
          quality: 85,
        );

    if (!mounted) return;
    setState(() {
      _preview = result;
      _processing = false;
    });
  }

  void _onFilterSelected(DocFilter filter) {
    setState(() => _filter = filter);
    _regeneratePreview();
  }

  void _onAdjustmentChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), _regeneratePreview);
  }

  Future<void> _save() async {
    final source = _original;
    if (source == null || _saving) return;

    if (!_hasEdits) {
      if (mounted) context.pop(false);
      return;
    }
    setState(() => _saving = true);

    try {
      final full = await ref.read(imageProcessorProvider).process(
            bytes: source,
            filter: _filter,
            brightness: _brightnessFactor,
            contrast: _contrastFactor,
            maxDimension: 2600,
            quality: 92,
          );
      await File(widget.page.filePath).writeAsBytes(full, flush: true);

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      await ref.read(documentRepositoryProvider).touchDocument(widget.documentId);
      ref.invalidate(documentPagesProvider(widget.documentId));
      ref.invalidate(documentListProvider);

      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterIndex = _carouselFilters.indexOf(_filter).clamp(0, 4);

    Widget? previewOverlay;
    if (_preview != null) {
      previewOverlay = LayoutBuilder(
        builder: (context, c) {
          return Center(
            child: Padding(
              padding: EdgeInsets.only(
                top: c.maxHeight * 0.14,
                bottom: c.maxHeight * 0.32,
                left: c.maxWidth * 0.1,
                right: c.maxWidth * 0.1,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_preview!, fit: BoxFit.contain, gaplessPlayback: true),
                  ),
                  if (_processing)
                    const CircularProgressIndicator(strokeWidth: 2),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: StitchHtmlView(
        htmlAsset: StitchScreens.filterEnhance,
        backgroundColor: const Color(0xFFF9F9FB),
        interactive: false,
        overlay: previewOverlay,
        hotspots: [
          StitchHotspot(
            left: 0.02,
            top: 0.04,
            width: 0.12,
            height: 0.07,
            semanticLabel: 'Cancel',
            onTap: () => context.pop(),
          ),
          StitchHotspot(
            left: 0.78,
            top: 0.04,
            width: 0.18,
            height: 0.07,
            semanticLabel: 'Done',
            onTap: _saving ? () {} : _save,
          ),
          // Filter carousel taps (5 filters across bottom strip)
          for (var i = 0; i < 5; i++)
            StitchHotspot(
              left: 0.06 + i * 0.17,
              top: 0.72,
              width: 0.14,
              height: 0.14,
              semanticLabel: _carouselFilters[i].label,
              onTap: () => _onFilterSelected(_carouselFilters[i]),
            ),
          // Brightness slider region
          StitchHotspot(
            left: 0.1,
            top: 0.88,
            width: 0.8,
            height: 0.04,
            semanticLabel: 'Brightness',
            onTap: () {
              setState(() => _brightness = (_brightness + 0.25).clamp(-1.0, 1.0));
              _onAdjustmentChanged();
            },
          ),
        ],
      ),
    );
  }
}
