import 'package:chattingapp/login/login_screen.dart';
import 'package:chattingapp/room/room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum AppRoute { login, room }

extension AppRouteExtension on AppRoute {
  String get path => switch (this) {
    AppRoute.login => '/login',
    AppRoute.room => '/room',
  };

  String get name => switch (this) {
    AppRoute.login => 'Login',
    AppRoute.room => 'Room',
  };

  Widget Function(BuildContext, GoRouterState) get builder {
    return switch (this) {
      AppRoute.login => (context, state) => const LoginScreen(),
      AppRoute.room => (context, state) => const RoomScreen(),
    };
  }

  GoRoute get route => GoRoute(path: path, name: name, builder: builder);
}

GoRouter createRouter(Ref ref) {
  late final GoRouter router;

  router = GoRouter(
    initialLocation: AppRoute.login.path,
    routes: [AppRoute.login.route, AppRoute.room.route],
  );

  return router;
}

final routerProvider = Provider<GoRouter>((ref) {
  return createRouter(ref);
});
