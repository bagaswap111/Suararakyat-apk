import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/auth_provider.dart';
import '../core/utils/themes.dart';
import '../features/public/auth/public_login_screen.dart';
import '../features/public/auth/register_screen.dart';
import '../features/public/home/home_screen.dart';
import '../features/public/home/home_shell.dart';
import '../features/public/detail/report_detail_screen.dart';
import '../features/public/create/create_report_screen.dart';
import '../features/public/profile/profile_screen.dart';
import '../features/public/search/search_screen.dart';

class PublicApp extends ConsumerWidget {
  const PublicApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final router = GoRouter(
      initialLocation: '/home',
      redirect: (ctx, state) {
        final isAuth = auth.isAuth;
        final loc = state.uri.toString();
        if (!isAuth && loc != '/login' && loc != '/register') return '/login';
        if (isAuth && (loc == '/login' || loc == '/register')) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const PublicLoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        ShellRoute(
          builder: (ctx, state, child) => HomeShell(child: child),
          routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
        GoRoute(path: '/home/detail/:id', builder: (_, s) => ReportDetailScreen(reportId: s.pathParameters['id']!)),
        GoRoute(path: '/search/detail/:id', builder: (_, s) => ReportDetailScreen(reportId: s.pathParameters['id']!)),
        GoRoute(path: '/create', builder: (_, __) => const CreateReportScreen()),
      ],
    );
    return MaterialApp.router(
      title: 'SuaraRakyat',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(SRColors.publicAccent),
      routerConfig: router,
    );
  }
}
