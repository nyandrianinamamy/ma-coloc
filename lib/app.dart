import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'src/theme/app_theme.dart';

class MaColocApp extends ConsumerWidget {
  const MaColocApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'MaColoc',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
