import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_color_tokens.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/neu_decorations.dart';
import '../../../shared/widgets/stitch/stitch_widgets.dart';
import '../../documents/domain/entities.dart';
import '../../documents/presentation/documents_providers.dart';
import '../data/image_processor.dart';
import '../domain/doc_filter.dart';

/// Filter & Enhance editor — Stitch design with existing image processing logic.
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
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          StitchTransactionalHeader(
            title: 'Enhance Scan',
            subtitle: 'Page ${widget.pageNumber} of ${widget.pageTotal}',
            onBack: () => context.pop(),
            actionLabel: 'Done',
            onAction: _preview == null || _saving ? null : _save,
            busy: _saving,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                decoration: NeuDecorations.card(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_preview != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _preview!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      )
                    else
                      const CircularProgressIndicator(),
                    if (_processing && _preview != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    // Corner crop markers from Stitch design
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _CropCornerPainter()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _FilterCarousel(
            filters: _carouselFilters,
            selected: _filter,
            previewBytes: _original,
            onSelected: _onFilterSelected,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                _SliderRow(
                  icon: Icons.brightness_6_outlined,
                  label: 'Brightness',
                  value: _brightness,
                  onChanged: (v) {
                    setState(() => _brightness = v);
                    _onAdjustmentChanged();
                  },
                ),
                _SliderRow(
                  icon: Icons.contrast_outlined,
                  label: 'Contrast',
                  value: _contrast,
                  onChanged: (v) {
                    setState(() => _contrast = v);
                    _onAdjustmentChanged();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterCarousel extends StatelessWidget {
  const _FilterCarousel({
    required this.filters,
    required this.selected,
    required this.previewBytes,
    required this.onSelected,
  });

  final List<DocFilter> filters;
  final DocFilter selected;
  final Uint8List? previewBytes;
  final ValueChanged<DocFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.tokens.surfaceSunken,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: context.colors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                final filter = filters[i];
                final active = filter == selected;
                return GestureDetector(
                  onTap: () => onSelected(filter),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.colors.surface,
                              boxShadow: NeuDecorations.flat(),
                              border: Border.all(
                                color: active
                                    ? context.colors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: previewBytes != null
                                  ? Image.memory(previewBytes!, fit: BoxFit.cover)
                                  : Icon(Icons.image_outlined,
                                      color: context.colors.onSurfaceVariant),
                            ),
                          ),
                          if (active)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: context.colors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        filter.label,
                        style: context.text.labelSmall?.copyWith(
                          color: active
                              ? context.colors.primary
                              : context.colors.onSurfaceVariant,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 8),
        SizedBox(width: 72, child: Text(label, style: context.text.bodySmall)),
        Expanded(
          child: Slider(
            value: value,
            min: -1,
            max: 1,
            activeColor: context.colors.primary,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _CropCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BrandColors.secondary.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const len = 16.0;
    const inset = 8.0;

    void corner(double x, double y, bool top, bool left) {
      final path = Path();
      if (top && left) {
        path.moveTo(x, y + len);
        path.lineTo(x, y);
        path.lineTo(x + len, y);
      } else if (top && !left) {
        path.moveTo(x - len, y);
        path.lineTo(x, y);
        path.lineTo(x, y + len);
      } else if (!top && left) {
        path.moveTo(x, y - len);
        path.lineTo(x, y);
        path.lineTo(x + len, y);
      } else {
        path.moveTo(x - len, y);
        path.lineTo(x, y);
        path.lineTo(x, y - len);
      }
      canvas.drawPath(path, paint);
    }

    corner(inset, inset, true, true);
    corner(size.width - inset, inset, true, false);
    corner(inset, size.height - inset, false, true);
    corner(size.width - inset, size.height - inset, false, false);
  }

  @override
  bool shouldRepaint(_CropCornerPainter oldDelegate) => false;
}
