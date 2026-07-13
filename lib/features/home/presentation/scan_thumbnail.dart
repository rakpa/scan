import 'package:flutter/material.dart';

import 'scan_thumbnail_io.dart'
    if (dart.library.html) 'scan_thumbnail_web.dart' as thumb;

/// Thumbnail for a scanned page — works on mobile and web.
class ScanThumbnail extends StatelessWidget {
  const ScanThumbnail({super.key, this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE8E8EA),
      child: thumb.buildScanThumbnail(path),
    );
  }
}
