import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/diary/presentation/home_page.dart';
import '../../features/diary/presentation/diary_edit_page.dart';
import '../../features/diary/presentation/diary_detail_page.dart';
import '../../features/diary/presentation/stats_page.dart';
import '../../features/diary/presentation/calendar_page.dart';
import '../../features/settings/presentation/settings_page.dart';

/// 路由配置
final GoRouter _router = GoRouter(
  initialLocation: '/login',
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
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);

/// 路由 Provider
final routerProvider = Provider<GoRouter>((ref) {
  return _router;
});