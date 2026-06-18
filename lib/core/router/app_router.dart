import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/pedigree/presentation/screens/dashboard_screen.dart';
import '../../features/pedigree/presentation/screens/dog_detail_screen.dart';
import '../../features/pedigree/presentation/screens/add_dog_screen.dart';
import '../../features/pedigree/presentation/screens/edit_dog_screen.dart';
import '../../features/pedigree/presentation/screens/litter_form_screen.dart';
import '../../features/pedigree/presentation/screens/litter_list_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/kennel_profile_screen.dart';
import '../../features/settings/presentation/screens/backup_migration_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/appearance_screen.dart';
import '../../features/settings/presentation/screens/financials_screen.dart';
import '../../features/settings/presentation/screens/add_transaction_screen.dart';
import '../../features/pedigree/presentation/screens/add_health_record_screen.dart';
import '../../features/pedigree/presentation/screens/matchmaker_screen.dart';
import '../../features/pedigree/presentation/screens/add_show_record_screen.dart';

int? _parseId(GoRouterState state, {String key = 'id'}) {
  final idStr = state.pathParameters[key];
  return int.tryParse(idStr ?? '');
}

Widget _invalidIdScreen() => const Scaffold(
  body: Center(child: Text('Invalid dog ID')),
);

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
          final extra = state.extra as Map<String, dynamic>?;
          return AddDogScreen(
            childId: extra?['childId'] as int?,
            isSire: extra?['isSire'] as bool?,
          );
        },
      ),
      GoRoute(
        path: '/dog/:id',
        builder: (BuildContext context, GoRouterState state) {
          final id = _parseId(state);
          if (id == null) return _invalidIdScreen();
          return DogDetailScreen(dogId: id);
        },
      ),
      GoRoute(
        path: '/dog/:id/edit',
        builder: (BuildContext context, GoRouterState state) {
          final id = _parseId(state);
          if (id == null) return _invalidIdScreen();
          return EditDogScreen(dogId: id);
        },
      ),
      GoRoute(
        path: '/dog/:id/health/new',
        builder: (BuildContext context, GoRouterState state) {
          final id = _parseId(state);
          if (id == null) return _invalidIdScreen();
          return AddHealthRecordScreen(dogId: id);
        },
      ),
      GoRoute(
        path: '/dog/:id/show/new',
        builder: (BuildContext context, GoRouterState state) {
          final id = _parseId(state);
          if (id == null) return _invalidIdScreen();
          return AddShowRecordScreen(dogId: id);
        },
      ),
      GoRoute(
        path: '/litter/new',
        builder: (BuildContext context, GoRouterState state) {
          return const LitterFormScreen();
        },
      ),
      GoRoute(
        path: '/litters',
        builder: (BuildContext context, GoRouterState state) {
          return const LitterListScreen();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsScreen();
        },
      ),
      GoRoute(
        path: '/settings/kennel',
        builder: (BuildContext context, GoRouterState state) {
          return const KennelProfileScreen();
        },
      ),
      GoRoute(
        path: '/settings/financials',
        builder: (BuildContext context, GoRouterState state) {
          return const FinancialsScreen();
        },
      ),
      GoRoute(
        path: '/settings/financials/new',
        builder: (BuildContext context, GoRouterState state) {
          return const AddTransactionScreen();
        },
      ),
      GoRoute(
        path: '/settings/backup',
        builder: (BuildContext context, GoRouterState state) {
          return const BackupMigrationScreen();
        },
      ),
      GoRoute(
        path: '/settings/appearance',
        builder: (BuildContext context, GoRouterState state) {
          return const AppearanceScreen();
        },
      ),
      GoRoute(
        path: '/matchmaker',
        builder: (BuildContext context, GoRouterState state) {
          return const MatchmakerScreen();
        },
      ),
      GoRoute(
        path: '/about',
        builder: (BuildContext context, GoRouterState state) {
          return const AboutScreen();
        },
      ),
    ],
  );
}
