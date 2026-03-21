import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/themes.dart';
import '../../../core/widgets/shared_widgets.dart';

final _categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/api/categories');
  return (res.data['categories'] as List).map((j) => Category.fromJson(j)).toList();
});

final _feedProvider = FutureProvider.family<List<Report>, String>((ref, filter) async {
  final params = <String, String>{'limit': '30'};
  if (filter.isNotEmpty) params['category'] = filter;
  final res = await ref.read(apiClientProvider).get('/api/reports', params: params);
  return (res.data['reports'] as List).map((j) => Report.fromJson(j)).toList();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _State();
}

class _State extends ConsumerState<HomeScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(_feedProvider(_filter));
    final cats = ref.watch(_categoriesProvider);
    return Scaffold(
      backgroundColor: SRColors.bg,
      body: RefreshIndicator(
        onRefresh: () async { ref.invalidate(_feedProvider(_filter)); },
        color: SRColors.publicAccent,
        child: CustomScrollView(slivers: [
          SliverAppBar(floating: true, snap: true, backgroundColor: SRColors.bg,
            title: const Text('SuaraRakyat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: SRColors.textPrimary)),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(48),
              child: cats.when(
                data: (list) => SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [_chip('', 'Semua'), ...list.map((c) => _chip(c.slug, c.name))])),
                loading: () => const SizedBox(height: 48),
                error: (_, __) => const SizedBox(height: 48),
              )),
          ),
          feed.when(
            data: (reports) => reports.isEmpty
              ? const SliverFillRemaining(child: Center(child: Text('Belum ada laporan', style: TextStyle(color: SRColors.textMuted))))
              : SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => ReportCard(r: reports[i], routePrefix: '/home'),
                  childCount: reports.length)),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: SRColors.publicAccent))),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('$e', style: const TextStyle(color: SRColors.danger)))),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String slug, String label) {
    final active = _filter == slug;
    return GestureDetector(
      onTap: () => setState(() => _filter = slug),
      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? SRColors.publicAccent : SRColors.bgSecondary,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: active ? SRColors.publicAccent : SRColors.border),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : SRColors.textMuted, fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500))),
    );
  }
}
