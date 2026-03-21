import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/themes.dart';
import '../../../core/widgets/shared_widgets.dart';

class GovReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;
  const GovReportDetailScreen({super.key, required this.reportId});
  @override
  ConsumerState<GovReportDetailScreen> createState() => _State();
}

class _State extends ConsumerState<GovReportDetailScreen> {
  Report? _report;
  List<Comment> _comments = [];
  List<ReportMedia> _media = [];
  final _commentCtrl = TextEditingController();
  bool _loading = true, _saving = false;
  String _newStatus = '';
  String? _msg;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.get('/api/reports/${widget.reportId}');
      final mRes = await api.get('/api/upload/report/${widget.reportId}');
      if (mounted) setState(() {
        _report = Report.fromJson(res.data['report']);
        _comments = (res.data['comments'] as List).map((j) => Comment.fromJson(j)).toList();
        _media = (mRes.data['media'] as List).map((j) => ReportMedia.fromJson(j)).toList();
        _newStatus = _report!.status;
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: SRColors.bg, body: Center(child: CircularProgressIndicator(color: SRColors.govAccent)));
    if (_report == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Tidak ditemukan')));
    final r = _report!;
    return Scaffold(
      backgroundColor: SRColors.bg,
      appBar: AppBar(title: const Text('Detail Laporan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_msg != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: SRColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: SRColors.success.withOpacity(0.3))),
          child: Text(_msg!, style: const TextStyle(color: SRColors.success, fontSize: 13))),

        Row(children: [
          StatusBadge(r.status), const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _priorityColor(r.priority).withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
            child: Text(r.priorityLabel, style: TextStyle(color: _priorityColor(r.priority), fontSize: 10, fontWeight: FontWeight.w800))),
          const Spacer(),
          Text(timeago.format(r.createdAt, locale: 'id'), style: const TextStyle(color: SRColors.textMuted, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        Text(r.title, style: const TextStyle(color: SRColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w800, height: 1.3)),
        const SizedBox(height: 10),
        Text(r.content, style: const TextStyle(color: SRColors.textSecond, fontSize: 14, height: 1.6)),
        if (r.locationProvince != null) ...[
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.location_on_outlined, size: 13, color: SRColors.textMuted), const SizedBox(width: 4),
            Expanded(child: Text([r.locationDetail, r.locationCity, r.locationProvince].where((e) => e != null).join(', '), style: const TextStyle(color: SRColors.textMuted, fontSize: 12)))]),
        ],

        // Media
        if (_media.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(height: 130, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _media.length,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.black, child: CachedNetworkImage(imageUrl: _media[i].fullUrl, fit: BoxFit.contain))),
              child: Container(margin: const EdgeInsets.only(right: 8), width: 130,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: SRColors.border)), clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(imageUrl: _media[i].fullUrl, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: SRColors.textMuted)))))),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: _uploadPhoto, icon: const Icon(Icons.add_photo_alternate_outlined, size: 16), label: const Text('Tambah Foto Bukti'),
          style: OutlinedButton.styleFrom(foregroundColor: SRColors.govAccent, side: const BorderSide(color: SRColors.govAccent))),

        // Update status
        const SizedBox(height: 16),
        const Divider(color: SRColors.border),
        const SizedBox(height: 8),
        const Text('Update Status', style: TextStyle(color: SRColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: ['pending', 'verified', 'investigating', 'resolved', 'rejected'].map((s) {
          final active = _newStatus == s;
          final labels = {'pending': 'Menunggu', 'verified': 'Terverifikasi', 'investigating': 'Ditindaklanjuti', 'resolved': 'Selesai', 'rejected': 'Ditolak'};
          return GestureDetector(onTap: () => setState(() => _newStatus = s),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: active ? SRColors.govAccent.withOpacity(0.15) : SRColors.bgSecondary, borderRadius: BorderRadius.circular(99), border: Border.all(color: active ? SRColors.govAccent : SRColors.border)),
              child: Text(labels[s]!, style: TextStyle(color: active ? SRColors.govAccent : SRColors.textMuted, fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500))));
        }).toList()),
        if (_newStatus != r.status) ...[
          const SizedBox(height: 10),
          LoadingButton(loading: _saving, onPressed: _updateStatus, label: 'Simpan Status', color: SRColors.govAccent),
        ],

        // Official comment
        const SizedBox(height: 16),
        const Divider(color: SRColors.border),
        const Text('Respons Resmi', style: TextStyle(color: SRColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: TextField(controller: _commentCtrl, style: const TextStyle(color: SRColors.textPrimary, fontSize: 13), maxLines: 3, minLines: 1, decoration: const InputDecoration(hintText: 'Tulis respons resmi...'))),
          const SizedBox(width: 8),
          IconButton(onPressed: _submitComment, icon: const Icon(Icons.send, color: SRColors.govAccent)),
        ]),
        const SizedBox(height: 12),
        ..._comments.map((c) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.isOfficial ? SRColors.govAccent.withOpacity(0.06) : SRColors.bgSecondary, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.isOfficial ? SRColors.govAccent.withOpacity(0.2) : SRColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(c.isOfficial ? '🏛️ Pejabat' : (c.authorDisplayId ?? 'Anonim'), style: TextStyle(color: c.isOfficial ? SRColors.govAccent : SRColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(), Text(timeago.format(c.createdAt, locale: 'id'), style: const TextStyle(color: SRColors.textMuted, fontSize: 11)),
            ]),
            const SizedBox(height: 4),
            Text(c.content, style: const TextStyle(color: SRColors.textPrimary, fontSize: 14, height: 1.4)),
          ]))),
      ]),
    );
  }

  Color _priorityColor(String p) { switch (p) { case 'critical': return SRColors.danger; case 'high': return SRColors.warning; default: return SRColors.textMuted; } }

  Future<void> _updateStatus() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).patch('/api/government/reports/${widget.reportId}/status', data: {'status': _newStatus});
      setState(() { _msg = 'Status berhasil diperbarui'; _saving = false; });
      await _load();
      Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _msg = null); });
    } catch (_) { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _submitComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    try {
      await ref.read(apiClientProvider).post('/api/government/reports/${widget.reportId}/comments', data: {'content': _commentCtrl.text.trim(), 'isPublic': true});
      _commentCtrl.clear(); await _load();
    } catch (_) {}
  }

  Future<void> _uploadPhoto() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    final form = FormData.fromMap({'images': await Future.wait(picked.map((x) => MultipartFile.fromFile(x.path, filename: x.path.split('/').last)))});
    try {
      await ref.read(apiClientProvider).postForm('/api/upload/gov/report/${widget.reportId}', form);
      setState(() => _msg = '${picked.length} foto diupload');
      await _load();
      Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _msg = null); });
    } catch (_) {}
  }
}
