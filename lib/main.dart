import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

/// Entry point.
///
/// The whole widget tree is wrapped in a [ProviderScope] so Riverpod can own
/// app-wide singletons (database, repositories, services).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DocScannerApp()));
}
