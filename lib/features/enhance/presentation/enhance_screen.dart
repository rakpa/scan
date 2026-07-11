import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/domain/entities.dart';
import '../../documents/presentation/documents_providers.dart';
import '../data/image_processor.dart';
import '../domain/doc_filter.dart';

/// Per-page enhancement editor: pick a filter, nudge brightness/contrast, and
/// save back over the page image. Preview generation runs on a background
/// isolate (see [ImageProcessor]); slider changes are debounced.
class EnhanceScreen extends ConsumerStatefulWidget {
  const EnhanceScreen({
    super.key,
    required this.page,
    required this.documentId,
  });

  final ScanPage page;
  final String documentId;

  @override
  ConsumerState<EnhanceScreen> createState() => _EnhanceScreenState();
}

class _EnhanceScreenState extends ConsumerState<EnhanceScreen> {
  DocFilter _filter = DocFilter.original;
  double _brightness = 0; // slider range -1..1, 0 == neutral
  double _contrast = 0;

  Uint8List? _original; // source bytes, loaded once
  Uint8List? _preview; // latest processed preview
  bool _processing = false;
  bool _saving = false;
  Timer? _debounce;

  // Map slider values (-1..1) to multipliers (0.5..1.5) where 1.0 == neutral.
  double get _brightnessFactor => 1 + _brightness * 0.5;
  double get _contrastFactor => 1 + _contrast * 0.5;

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

  bool get _hasEdits =>
      _filter != DocFilter.original || _brightness != 0 || _contrast != 0;

  Future<void> _loadOriginal() async {
    final bytes = await File(widget.page.filePath).readAsBytes();
    if (!mounted) return;
    // Show the captured page instantly. The default filter (Original) with
    // neutral sliders needs no processing, so we skip the isolate entirely
    // until the user actually picks a filter or moves a slider.
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
          maxDimension: 1080, // preview resolution — fast to compute & decode
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
    // Debounce: sliders fire rapidly; only reprocess once they settle briefly.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), _regeneratePreview);
  }

  Future<void> _save() async {
    final source = _original;
    if (source == null || _saving) return;

    // Nothing changed — don't needlessly recompress/overwrite the page.
    if (!_hasEdits) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _saving = true);

    try {
      // Re-render at high quality and a larger cap before overwriting.
      final full = await ref.read(imageProcessorProvider).process(
            bytes: source,
            filter: _filter,
            brightness: _brightnessFactor,
            contrast: _contrastFactor,
            maxDimension: 2600,
            quality: 92,
          );
      await File(widget.page.filePath).writeAsBytes(full, flush: true);

      // The file path is unchanged, so Flutter's image cache still holds the
      // old pixels — clear it so the new image shows everywhere.
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      await ref.read(documentRepositoryProvider).touchDocument(widget.documentId);
      ref.invalidate(documentPagesProvider(widget.documentId));
      ref.invalidate(documentListProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhance'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _preview == null ? null : _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          // --- Preview ---
          Expanded(
            child: Container(
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_preview != null)
                    Image.memory(
                      _preview!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true, // avoid flicker between updates
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
                          color: theme.colorScheme.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // --- Controls ---
          Material(
            elevation: 3,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FilterStrip(
                      selected: _filter,
                      onSelected: _onFilterSelected,
                    ),
                    _AdjustmentSlider(
                      icon: Icons.brightness_6_outlined,
                      label: 'Brightness',
                      value: _brightness,
                      onChanged: (v) {
                        setState(() => _brightness = v);
                        _onAdjustmentChanged();
                      },
                    ),
                    _AdjustmentSlider(
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal strip of selectable filter chips.
class _FilterStrip extends StatelessWidget {
  const _FilterStrip({required this.selected, required this.onSelected});

  final DocFilter selected;
  final ValueChanged<DocFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: DocFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = DocFilter.values[index];
          return ChoiceChip(
            label: Text(filter.label),
            selected: filter == selected,
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}

/// A labelled slider for a -1..1 adjustment with a reset-to-centre baseline.
class _AdjustmentSlider extends StatelessWidget {
  const _AdjustmentSlider({
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          SizedBox(width: 76, child: Text(label)),
          Expanded(
            child: Slider(
              value: value,
              min: -1,
              max: 1,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
