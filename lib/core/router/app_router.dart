import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/pedigree/presentation/screens/dashboard_screen.dart';
import '../../features/pedigree/presentation/screens/dog_detail_screen.dart';
import '../../features/pedigree/presentation/screens/add_dog_screen.dart';
import '../../features/pedigree/presentation/screens/litter_form_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const DashboardScreen();
        },
      ),
      GoRoute(
        path: '/dog/new',
        builder: (BuildContext context, GoRouterState state) {
          return const AddDogScreen();
        },
      ),
      GoRoute(
        path: '/dog/:id',
        builder: (BuildContext context, GoRouterState state) {
          final idStr = state.pathParameters['id'];
          final id = int.tryParse(idStr ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid dog ID')),
            );
          }
          return DogDetailScreen(dogId: id);
        },
      ),
      GoRoute(
        path: '/litter/new',
        builder: (BuildContext context, GoRouterState state) {
          return const LitterFormScreen();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsScreen();
        },
      ),
    ],
  );
}
