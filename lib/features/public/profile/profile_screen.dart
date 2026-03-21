import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/themes.dart';
import '../../../core/widgets/shared_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _State();
}

class _State extends ConsumerState<ProfileScreen> {
  List<Report> _myReports = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    try {
      final res = await ref.read(apiClientProvider).get('/api/reports', params: {'limit': '100'});
      final all = (res.data['reports'] as List).map((j) => Report.fromJson(j)).toList();
      if (mounted) setState(() {
        _myReports = all.where((r) => r.authorDisplayId == auth.user?.displayId).toList();
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final displayId = auth.user?.displayId ?? '';
    return Scaffold(
      backgroundColor: SRColors.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(pinned: true, expandedHeight: 160, backgroundColor: SRColors.bg,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [SRColors.publicAccent, Color(0xFF0A5F9B)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                CircleAvatar(radius: 28, backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(displayId.length >= 2 ? displayId.substring(displayId.length - 2) : '??',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white))),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(displayId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(width: 6),
                  GestureDetector(onTap: () {
                    Clipboard.setData(ClipboardData(text: displayId));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID tersalin!')));
                  }, child: const Icon(Icons.copy, size: 13, color: Colors.white70)),
                ]),
                const SizedBox(height: 12),
              ])),
          ),
          actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (mounted) context.go('/login');
          })],
        ),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          _stat('Laporan', _myReports.length),
          const SizedBox(width: 10),
          _stat('Dilihat', _myReports.fold(0, (a, r) => a + r.viewCount)),
          const SizedBox(width: 10),
          _stat('Dukungan', _myReports.fold(0, (a, r) => a + r.supportCount)),
        ]))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text('Laporan Saya (${_myReports.length})', style: const TextStyle(color: SRColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)))),
        if (_loading) const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: SRColors.publicAccent)))
        else if (_myReports.isEmpty) SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.description_outlined, size: 44, color: SRColors.textMuted),
          const SizedBox(height: 12),
          const Text('Belum ada laporan', style: TextStyle(color: SRColors.textMuted)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => context.push('/create'), child: const Text('Buat Laporan Pertama')),
        ])))
        else SliverList(delegate: SliverChildBuilderDelegate((ctx, i) => ReportCard(r: _myReports[i], routePrefix: '/home'), childCount: _myReports.length)),
      ]),
    );
  }

  Widget _stat(String label, int value) => Expanded(child: Container(padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: SRColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: SRColors.border)),
    child: Column(children: [
      Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: SRColors.textPrimary)),
      Text(label, style: const TextStyle(fontSize: 11, color: SRColors.textMuted)),
    ])));
}
