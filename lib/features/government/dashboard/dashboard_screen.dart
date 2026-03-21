import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/themes.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _State();
}

class _State extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ref.read(apiClientProvider).get('/api/government/dashboard');
      if (mounted) setState(() { _stats = res.data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final official = auth.official;
    return Scaffold(
      backgroundColor: SRColors.bg,
      body: RefreshIndicator(onRefresh: () async { setState(() => _loading = true); await _load(); }, color: SRColors.govAccent,
        child: CustomScrollView(slivers: [
          SliverAppBar(pinned: true, backgroundColor: SRColors.bg,
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: SRColors.textPrimary)),
              if (official != null) Text(official.agency, style: const TextStyle(color: SRColors.textMuted, fontSize: 11)),
            ]),
          ),
          if (_loading) const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: SRColors.govAccent)))
          else if (_stats == null) const SliverFillRemaining(child: Center(child: Text('Gagal memuat', style: TextStyle(color: SRColors.textMuted))))
          else SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverList(delegate: SliverChildListDelegate([
            // Welcome card
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
              gradient: LinearGradient(colors: [SRColors.govAccent.withOpacity(0.2), SRColors.govAccent.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(16), border: Border.all(color: SRColors.govAccent.withOpacity(0.2))),
              child: Row(children: [
                CircleAvatar(backgroundColor: SRColors.govAccent.withOpacity(0.2), radius: 24,
                  child: Text(official?.fullName.isNotEmpty == true ? official!.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: SRColors.govAccent, fontWeight: FontWeight.w800, fontSize: 18))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Halo, ${official?.fullName.split(' ').first ?? ''}!', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: SRColors.textPrimary)),
                  Text(official?.role.toUpperCase() ?? '', style: const TextStyle(color: SRColors.govAccent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ])),
              ])),
            const SizedBox(height: 20),

            // KPI grid
            const Text('Ringkasan', style: TextStyle(color: SRColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            ..._buildKpis(),
            const SizedBox(height: 20),

            // Status breakdown
            const Text('Status Laporan', style: TextStyle(color: SRColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            ..._buildStatus(),
            const SizedBox(height: 20),

            // Recent
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Terbaru', style: TextStyle(color: SRColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
              TextButton(onPressed: () => context.go('/reports'), child: const Text('Lihat Semua', style: TextStyle(color: SRColors.govAccent))),
            ]),
            const SizedBox(height: 8),
            ..._buildRecent(),
          ]))),
        ]),
      ),
    );
  }

  List<Widget> _buildKpis() {
    final total = _stats!['total'] ?? 0;
    final byStatus = (_stats!['byStatus'] as List? ?? []);
    int resolved = 0, pending = 0;
    for (final s in byStatus) {
      if (s['status'] == 'resolved') resolved = int.tryParse(s['count'].toString()) ?? 0;
      if (s['status'] == 'pending') pending = int.tryParse(s['count'].toString()) ?? 0;
    }
    final rate = total > 0 ? (resolved / total * 100).toStringAsFixed(0) : '0';
    return [Row(children: [
      _kpi('Total', '$total', Icons.description_outlined, SRColors.publicAccent),
      const SizedBox(width: 10),
      _kpi('Resolusi', '$rate%', Icons.check_circle_outline, SRColors.success),
    ]), const SizedBox(height: 10), Row(children: [
      _kpi('Menunggu', '$pending', Icons.hourglass_empty, SRColors.warning),
      const SizedBox(width: 10),
      _kpi('Selesai', '$resolved', Icons.task_alt, SRColors.govAccent),
    ])];
  }

  Widget _kpi(String label, String val, IconData icon, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
    child: Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(val, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: SRColors.textMuted, fontSize: 11)),
      ])])));

  List<Widget> _buildStatus() {
    final byStatus = (_stats!['byStatus'] as List? ?? []);
    final total = (_stats!['total'] as num?)?.toDouble() ?? 1.0;
    final cfg = {'pending': ('Menunggu', SRColors.warning), 'verified': ('Terverifikasi', SRColors.success), 'investigating': ('Ditindaklanjuti', SRColors.publicAccent), 'resolved': ('Selesai', SRColors.govAccent), 'rejected': ('Ditolak', SRColors.danger)};
    return byStatus.map<Widget>((s) {
      final status = s['status'] as String? ?? '';
      final count = int.tryParse(s['count'].toString()) ?? 0;
      final label = cfg[status]?.$1 ?? status;
      final color = cfg[status]?.$2 ?? SRColors.textMuted;
      final pct = count / total;
      return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: SRColors.bgSecondary, borderRadius: BorderRadius.circular(10), border: Border.all(color: SRColors.border)),
        child: Column(children: [
          Row(children: [Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)), const Spacer(), Text('$count', style: const TextStyle(color: SRColors.textPrimary, fontWeight: FontWeight.w700))]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: pct, backgroundColor: SRColors.border, color: color, minHeight: 4)),
        ]));
    }).toList();
  }

  List<Widget> _buildRecent() {
    final recent = (_stats!['recentReports'] as List? ?? []).take(3);
    return recent.map<Widget>((r) => InkWell(
      onTap: () => context.push('/reports/detail/${r['id']}'),
      child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: SRColors.bgSecondary, borderRadius: BorderRadius.circular(10), border: Border.all(color: SRColors.border)),
        child: Row(children: [
          Expanded(child: Text(r['title'] ?? '', style: const TextStyle(color: SRColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right, color: SRColors.textMuted, size: 18),
        ])))).toList();
  }
}
