import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/diary/presentation/home_page.dart';
import '../../features/diary/presentation/diary_edit_page.dart';
import '../../features/diary/presentation/diary_detail_page.dart';
import '../../features/diary/presentation/stats_page.dart';
import '../../features/diary/presentation/calendar_page.dart';
import '../../features/diary/presentation/trash_page.dart';
import '../../features/diary/presentation/tags_page.dart';
import '../../features/diary/presentation/goals_page.dart';
import '../../features/settings/presentation/settings_page.dart';

/// 路由 Provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/' : '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/diary/new',
        builder: (context, state) => const DiaryEditPage(),
      ),
      GoRoute(
        path: '/diary/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DiaryDetailPage(diaryId: id);
        },
      ),
      GoRoute(
        path: '/diary/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DiaryEditPage(diaryId: id);
        },
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) => const StatsPage(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarPage(),
      ),
      GoRoute(
        path: '/trash',
        builder: (context, state) => const TrashPage(),
      ),
      GoRoute(
        path: '/tags',
        builder: (context, state) => const TagsPage(),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }

      if (isLoggedIn && isGoingToLogin) {
        return '/';
      }

      return null;
    },
  );
});