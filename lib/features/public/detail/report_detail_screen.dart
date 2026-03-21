import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/themes.dart';
import '../../../core/widgets/shared_widgets.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});
  @override
  ConsumerState<ReportDetailScreen> createState() => _State();
}

class _State extends ConsumerState<ReportDetailScreen> {
  Report? _report;
  List<Comment> _comments = [];
  List<ReportMedia> _media = [];
  Map<String, int> _reactions = {};
  final _commentCtrl = TextEditingController();
  bool _loading = true, _submitting = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.get('/api/reports/${widget.reportId}');
      final mRes = await api.get('/api/upload/report/${widget.reportId}');
      final rxMap = <String, int>{};
      for (final rx in (res.data['reactions'] as List? ?? [])) {
        rxMap[rx['type'] as String] = int.tryParse(rx['count'].toString()) ?? 0;
      }
      if (mounted) setState(() {
        _report = Report.fromJson(res.data['report']);
        _comments = (res.data['comments'] as List).map((j) => Comment.fromJson(j)).toList();
        _media = (mRes.data['media'] as List).map((j) => ReportMedia.fromJson(j)).toList();
        _reactions = rxMap;
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: SRColors.bg, body: Center(child: CircularProgressIndicator(color: SRColors.publicAccent)));
    if (_report == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Tidak ditemukan')));
    final r = _report!;
    final auth = ref.read(authProvider);
    return Scaffold(
      backgroundColor: SRColors.bg,
      appBar: AppBar(title: const Text('Detail Laporan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          StatusBadge(r.status), const SizedBox(width: 6),
          if (r.categoryName != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: SRColors.bgSecondary, borderRadius: BorderRadius.circular(99)),
            child: Text(r.categoryName!, style: const TextStyle(color: SRColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
          const Spacer(),
          Text(timeago.format(r.createdAt, locale: 'id'), style: const TextStyle(color: SRColors.textMuted, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        Text(r.title, style: const TextStyle(color: SRColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
        const SizedBox(height: 10),
        Text(r.content, style: const TextStyle(color: SRColors.textSecond, fontSize: 15, height: 1.6)),
        if (r.locationProvince != null) ...[
          const SizedBox(height: 10),
          Row(children: [const Icon(Icons.location_on_outlined, size: 13, color: SRColors.textMuted), const SizedBox(width: 4),
            Expanded(child: Text([r.locationDetail, r.locationCity, r.locationProvince].where((e) => e != null).join(', '), style: const TextStyle(color: SRColors.textMuted, fontSize: 12)))]),
        ],
        if (_media.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(height: 160, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _media.length,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.black,
                child: CachedNetworkImage(imageUrl: _media[i].fullUrl, fit: BoxFit.contain))),
              child: Container(margin: const EdgeInsets.only(right: 8), width: 200,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: SRColors.border)), clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(imageUrl: _media[i].fullUrl, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: SRColors.textMuted)))))),
        ],
        const SizedBox(height: 16),
        const Divider(color: SRColors.border),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _rxBtn(Icons.thumb_up_outlined, 'Dukung', _reactions['support'] ?? 0, 'support', auth),
          _rxBtn(Icons.warning_amber_outlined, 'Penting', _reactions['important'] ?? 0, 'important', auth),
          _rxBtn(Icons.help_outline, 'Ragukan', _reactions['doubt'] ?? 0, 'doubt', auth),
        ]),
        const Divider(color: SRColors.border),
        const SizedBox(height: 8),
        Text('Komentar (${_comments.length})', style: const TextStyle(color: SRColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        if (auth.isAuth) Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: TextField(controller: _commentCtrl, style: const TextStyle(color: SRColors.textPrimary, fontSize: 13),
            maxLines: 3, minLines: 1, decoration: const InputDecoration(hintText: 'Tulis komentar...', isDense: true))),
          const SizedBox(width: 8),
          IconButton(onPressed: _submitting ? null : _submit,
            icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: SRColors.publicAccent)),
        ]),
        const SizedBox(height: 10),
        ..._comments.map((c) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.isOfficial ? SRColors.govAccent.withOpacity(0.06) : SRColors.bgSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.isOfficial ? SRColors.govAccent.withOpacity(0.2) : SRColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(c.isOfficial ? '🏛️ Pejabat Resmi' : (c.authorDisplayId ?? 'Anonim'),
                style: TextStyle(color: c.isOfficial ? SRColors.govAccent : SRColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(timeago.format(c.createdAt, locale: 'id'), style: const TextStyle(color: SRColors.textMuted, fontSize: 11)),
            ]),
            const SizedBox(height: 4),
            Text(c.content, style: const TextStyle(color: SRColors.textPrimary, fontSize: 14, height: 1.4)),
          ]))),
      ]),
    );
  }

  Widget _rxBtn(IconData icon, String label, int count, String type, AuthState auth) => InkWell(
    onTap: auth.isAuth ? () => _react(type) : null,
    borderRadius: BorderRadius.circular(8),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Column(children: [
      Icon(icon, size: 20, color: SRColors.textMuted),
      const SizedBox(height: 2),
      Text('$count $label', style: const TextStyle(color: SRColors.textMuted, fontSize: 12)),
    ])));

  Future<void> _react(String type) async {
    final api = ref.read(apiClientProvider);
    try { await api.post('/api/reports/${widget.reportId}/reactions', data: {'type': type}); _load(); } catch (_) {}
  }

  Future<void> _submit() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).post('/api/reports/${widget.reportId}/comments', data: {'content': _commentCtrl.text.trim()});
      _commentCtrl.clear(); await _load();
    } catch (_) {}
    if (mounted) setState(() => _submitting = false);
  }
}
