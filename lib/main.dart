import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/backend.dart';
import 'data/firebase/firebase_backend.dart';
import 'providers.dart';

/// Backend selection: `--dart-define=BACKEND=memory` (default) or `firebase`.
const _backend = String.fromEnvironment('BACKEND', defaultValue: 'memory');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppRepositories repositories;
  if (_backend == 'firebase') {
    repositories = await buildFirebaseRepositories();
  } else {
    repositories = AppRepositories.memory();
  }

  runApp(
    ProviderScope(
      overrides: [repositoriesProvider.overrideWithValue(repositories)],
      child: const CanteenApp(),
    ),
  );
}
