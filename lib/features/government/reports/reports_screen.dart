import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/themes.dart';
import '../../../core/widgets/shared_widgets.dart';

class GovReportsScreen extends ConsumerStatefulWidget {
  const GovReportsScreen({super.key});
  @override
  ConsumerState<GovReportsScreen> createState() => _State();
}

class _State extends ConsumerState<GovReportsScreen> {
  List<Report> _reports = [];
  bool _loading = true;
  String _status = '', _priority = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final params = <String, String>{'limit': '50'};
    if (_status.isNotEmpty) params['status'] = _status;
    if (_priority.isNotEmpty) params['priority'] = _priority;
    if (_searchCtrl.text.isNotEmpty) params['search'] = _searchCtrl.text.trim();
    try {
      final res = await ref.read(apiClientProvider).get('/api/government/reports', params: params);
      if (mounted) setState(() { _reports = (res.data['reports'] as List).map((j) => Report.fromJson(j)).toList(); _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SRColors.bg,
      appBar: AppBar(
        title: const Text('Semua Laporan'),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(108), child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 6), child: TextField(
            controller: _searchCtrl, style: const TextStyle(color: SRColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(hintText: 'Cari laporan...', isDense: true, prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: IconButton(icon: const Icon(Icons.search, size: 18), onPressed: _load)),
            onSubmitted: (_) => _load())),
          SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chip('', 'Semua', _status, (v) { setState(() => _status = v); _load(); }),
              _chip('pending', 'Menunggu', _status, (v) { setState(() => _status = v); _load(); }),
              _chip('investigating', 'Diinvestigasi', _status, (v) { setState(() => _status = v); _load(); }),
              _chip('resolved', 'Selesai', _status, (v) { setState(() => _status = v); _load(); }),
              _chip('rejected', 'Ditolak', _status, (v) { setState(() => _status = v); _load(); }),
              const VerticalDivider(width: 16),
              _chip('critical', '🔴 Kritis', _priority, (v) { setState(() => _priority = v); _load(); }),
              _chip('high', '🟠 Tinggi', _priority, (v) { setState(() => _priority = v); _load(); }),
            ])),
        ])),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: SRColors.govAccent))
        : RefreshIndicator(onRefresh: _load, color: SRColors.govAccent,
            child: _reports.isEmpty
              ? const Center(child: Text('Tidak ada laporan', style: TextStyle(color: SRColors.textMuted)))
              : ListView.builder(itemCount: _reports.length, itemBuilder: (ctx, i) => ReportCard(r: _reports[i], routePrefix: '/reports'))),
    );
  }

  Widget _chip(String val, String label, String current, Function(String) onTap) {
    final active = current == val;
    return GestureDetector(onTap: () => onTap(active ? '' : val),
      child: Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? SRColors.govAccent : SRColors.bgSecondary,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: active ? SRColors.govAccent : SRColors.border)),
        child: Text(label, style: TextStyle(color: active ? Colors.white : SRColors.textMuted, fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500))));
  }
}
