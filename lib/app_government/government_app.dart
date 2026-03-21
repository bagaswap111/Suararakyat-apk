import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/auth_provider.dart';
import '../core/utils/themes.dart';
import '../features/government/auth/gov_login_screen.dart';
import '../features/government/dashboard/dashboard_screen.dart';
import '../features/government/reports/reports_screen.dart';
import '../features/government/reports/report_detail_screen.dart';
import '../features/government/officials/officials_screen.dart';
import '../features/government/profile/gov_profile_screen.dart';
import 'gov_shell.dart';

class GovernmentApp extends ConsumerWidget {
  const GovernmentApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final router = GoRouter(
      initialLocation: '/dashboard',
      redirect: (ctx, state) {
        final isAuth = auth.isAuth;
        final loc = state.uri.toString();
        if (!isAuth && loc != '/login') return '/login';
        if (isAuth && loc == '/login') return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const GovLoginScreen()),
        ShellRoute(
          builder: (ctx, state, child) => GovShell(child: child, official: auth.official),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
            GoRoute(path: '/reports', builder: (_, __) => const GovReportsScreen()),
            GoRoute(path: '/officials', builder: (_, __) => const OfficialsScreen()),
            GoRoute(path: '/profile', builder: (_, __) => const GovProfileScreen()),
          ],
        ),
        GoRoute(path: '/reports/detail/:id', builder: (_, s) => GovReportDetailScreen(reportId: s.pathParameters['id']!)),
      ],
    );
    return MaterialApp.router(
      title: 'Portal Pejabat',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(SRColors.govAccent),
      routerConfig: router,
    );
  }
}
