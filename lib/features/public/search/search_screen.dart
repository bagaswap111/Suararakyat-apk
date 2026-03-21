import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/themes.dart';
import '../../../core/widgets/shared_widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _State();
}

class _State extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  List<Report> _results = [];
  bool _loading = false, _searched = false;

  Future<void> _search() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _searched = true; });
    try {
      final res = await ref.read(apiClientProvider).get('/api/reports', params: {'search': _ctrl.text.trim(), 'limit': '30'});
      if (mounted) setState(() { _results = (res.data['reports'] as List).map((j) => Report.fromJson(j)).toList(); _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SRColors.bg,
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          style: const TextStyle(color: SRColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Cari laporan...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
          onSubmitted: (_) => _search(),
          autofocus: true,
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: _search)],
      ),
      body: !_searched
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.search, size: 48, color: SRColors.textMuted),
            SizedBox(height: 12),
            Text('Ketik untuk mencari laporan', style: TextStyle(color: SRColors.textMuted)),
          ]))
        : _loading ? const Center(child: CircularProgressIndicator(color: SRColors.publicAccent))
        : _results.isEmpty ? const Center(child: Text('Tidak ada hasil', style: TextStyle(color: SRColors.textMuted)))
        : ListView.builder(itemCount: _results.length, itemBuilder: (ctx, i) => ReportCard(r: _results[i], routePrefix: '/search')),
    );
  }
}
