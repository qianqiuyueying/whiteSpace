import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/services/database_service.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/diary/presentation/home_page.dart';
import 'features/diary/presentation/diary_edit_page.dart';
import 'features/diary/presentation/diary_detail_page.dart';
import 'features/diary/presentation/stats_page.dart';
import 'features/settings/presentation/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化数据库
  await DatabaseService.getInstance();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return MaterialApp.router(
      title: '留白日记',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _buildRouter(authState.isAuthenticated),
    );
  }

  GoRouter _buildRouter(bool isAuthenticated) {
    return GoRouter(
      initialLocation: isAuthenticated ? '/' : '/login',
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
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
      redirect: (context, state) {
        final isLoggedIn = isAuthenticated;
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
  }
}