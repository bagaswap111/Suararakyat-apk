import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/themes.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    int idx = 0;
    if (loc.startsWith('/home')) idx = 0;
    else if (loc.startsWith('/search')) idx = 1;
    else if (loc.startsWith('/profile')) idx = 2;

    return Scaffold(
      body: child,
      floatingActionButton: idx == 0 ? FloatingActionButton(
        onPressed: () => context.push('/create'),
        backgroundColor: SRColors.publicAccent,
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ) : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: SRColors.border))),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) {
            if (i == 0) context.go('/home');
            if (i == 1) context.go('/search');
            if (i == 2) context.go('/profile');
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Cari'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
