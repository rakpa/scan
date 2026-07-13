import 'dart:io';

import 'package:flutter/material.dart';

Widget buildScanThumbnail(String? path) {
  if (path != null && File(path).existsSync()) {
    return Image.file(File(path), width: double.infinity, fit: BoxFit.cover);
  }
  return const Center(
    child: Icon(
      Icons.description_outlined,
      size: 36,
      color: Color(0xFF737785),
    ),
  );
}
