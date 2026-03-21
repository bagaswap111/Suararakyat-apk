import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/models/models.dart';
import '../core/utils/themes.dart';

class GovShell extends StatelessWidget {
  final Widget child;
  final GovOfficial? official;
  const GovShell({super.key, required this.child, this.official});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    int idx = 0;
    if (loc.startsWith('/dashboard')) idx = 0;
    else if (loc.startsWith('/reports')) idx = 1;
    else if (loc.startsWith('/officials')) idx = 2;
    else if (loc.startsWith('/profile')) idx = official?.isAdmin == true ? 3 : 2;

    final isAdmin = official?.isAdmin == true;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: SRColors.border))),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) {
            if (i == 0) context.go('/dashboard');
            if (i == 1) context.go('/reports');
            if (isAdmin && i == 2) context.go('/officials');
            if ((!isAdmin && i == 2) || (isAdmin && i == 3)) context.go('/profile');
          },
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            const BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Laporan'),
            if (isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Pejabat'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
