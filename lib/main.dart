import 'package:chattingapp/util/api/loading_provider.dart';
import 'package:chattingapp/util/route/router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

  class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isLoading = ref.watch(isGlobalLoadingProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (isLoading) const _GlobalLoadingOverlay(),
          ],
        );
      },
      );
  }
}
class _GlobalLoadingOverlay extends StatelessWidget {
  const _GlobalLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.15),
      child: Center(
        child: CupertinoActivityIndicator(
          color: Colors.grey[300],
          radius: 16,
        ),
      ),
    );
  }
}
