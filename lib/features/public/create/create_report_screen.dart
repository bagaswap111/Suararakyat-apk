import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/themes.dart';

const _provinces = ['Aceh','Sumatera Utara','Sumatera Barat','Riau','Kepulauan Riau','Jambi','Sumatera Selatan','Bengkulu','Lampung','DKI Jakarta','Jawa Barat','Banten','Jawa Tengah','DI Yogyakarta','Jawa Timur','Bali','Nusa Tenggara Barat','Nusa Tenggara Timur','Kalimantan Barat','Kalimantan Tengah','Kalimantan Selatan','Kalimantan Timur','Kalimantan Utara','Sulawesi Utara','Sulawesi Tengah','Sulawesi Selatan','Sulawesi Tenggara','Maluku','Papua','Papua Barat'];

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});
  @override
  ConsumerState<CreateReportScreen> createState() => _State();
}

class _State extends ConsumerState<CreateReportScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  String? _province, _categoryId;
  List<Category> _cats = [];
  List<File> _images = [];
  bool _loading = false;
  String? _error, _progress;

  @override
  void initState() { super.initState(); _loadCats(); }

  Future<void> _loadCats() async {
    try {
      final res = await ref.read(apiClientProvider).get('/api/categories');
      if (mounted) setState(() => _cats = (res.data['categories'] as List).map((j) => Category.fromJson(j)).toList());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SRColors.bg,
      appBar: AppBar(title: const Text('Buat Laporan'), actions: [
        TextButton(
          onPressed: _loading ? null : _submit,
          child: _loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: SRColors.publicAccent))
            : const Text('Kirim', style: TextStyle(color: SRColors.publicAccent, fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_error != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: SRColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_error!, style: const TextStyle(color: SRColors.danger, fontSize: 13))),
        if (_progress != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: SRColors.publicAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_progress!, style: const TextStyle(color: SRColors.publicAccent, fontSize: 13))),

        TextField(controller: _titleCtrl, style: const TextStyle(color: SRColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(hintText: 'Judul laporan...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero),
          maxLines: 2),
        const Divider(color: SRColors.border),
        TextField(controller: _contentCtrl, style: const TextStyle(color: SRColors.textPrimary, fontSize: 15, height: 1.5),
          decoration: const InputDecoration(hintText: 'Jelaskan kejadian secara detail...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero),
          maxLines: null, minLines: 6),

        const SizedBox(height: 16),
        _label(Icons.photo_camera_outlined, 'Foto Bukti (Opsional, maks 5)'),
        const SizedBox(height: 8),
        SizedBox(height: 90, child: ListView(scrollDirection: Axis.horizontal, children: [
          ..._images.asMap().entries.map((e) => Stack(children: [
            Container(margin: const EdgeInsets.only(right: 8), width: 90, height: 90,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: SRColors.border)),
              clipBehavior: Clip.antiAlias, child: Image.file(e.value, fit: BoxFit.cover)),
            Positioned(top: 2, right: 10, child: GestureDetector(
              onTap: () => setState(() => _images.removeAt(e.key)),
              child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: SRColors.danger, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white)))),
          ])),
          if (_images.length < 5) GestureDetector(onTap: _pickImages,
            child: Container(width: 90, height: 90,
              decoration: BoxDecoration(color: SRColors.bgSecondary, borderRadius: BorderRadius.circular(10), border: Border.all(color: SRColors.border)),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_photo_alternate_outlined, color: SRColors.textMuted, size: 26),
                SizedBox(height: 4),
                Text('Tambah', style: TextStyle(color: SRColors.textMuted, fontSize: 11)),
              ]))),
        ])),

        const SizedBox(height: 16),
        _label(Icons.category_outlined, 'Kategori'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _cats.map((c) {
          final active = _categoryId == c.id.toString();
          return GestureDetector(onTap: () => setState(() => _categoryId = active ? null : c.id.toString()),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? SRColors.publicAccent.withOpacity(0.15) : SRColors.bgSecondary,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: active ? SRColors.publicAccent : SRColors.border)),
              child: Text(c.name, style: TextStyle(color: active ? SRColors.publicAccent : SRColors.textMuted, fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500))));
        }).toList()),

        const SizedBox(height: 16),
        _label(Icons.location_on_outlined, 'Lokasi Kejadian'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: _province, dropdownColor: SRColors.bgSecondary, style: const TextStyle(color: SRColors.textPrimary, fontSize: 14),
          decoration: const InputDecoration(labelText: 'Provinsi'),
          items: [const DropdownMenuItem(value: null, child: Text('Pilih Provinsi')), ..._provinces.map((p) => DropdownMenuItem(value: p, child: Text(p)))],
          onChanged: (v) => setState(() => _province = v)),
        const SizedBox(height: 10),
        TextField(controller: _cityCtrl, style: const TextStyle(color: SRColors.textPrimary), decoration: const InputDecoration(labelText: 'Kota/Kabupaten')),
        const SizedBox(height: 10),
        TextField(controller: _detailCtrl, style: const TextStyle(color: SRColors.textPrimary), decoration: const InputDecoration(labelText: 'Detail Lokasi')),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _label(IconData icon, String text) => Row(children: [Icon(icon, size: 15, color: SRColors.textMuted), const SizedBox(width: 6), Text(text, style: const TextStyle(color: SRColors.textSecond, fontSize: 13, fontWeight: FontWeight.w700))]);

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) setState(() => _images = [..._images, ...picked.map((x) => File(x.path))].take(5).toList());
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) { setState(() => _error = 'Judul dan isi wajib diisi'); return; }
    setState(() { _loading = true; _error = null; _progress = 'Mengirim laporan...'; });
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.post('/api/reports', data: {
        'title': _titleCtrl.text.trim(), 'content': _contentCtrl.text.trim(),
        if (_province != null) 'locationProvince': _province,
        if (_cityCtrl.text.isNotEmpty) 'locationCity': _cityCtrl.text.trim(),
        if (_detailCtrl.text.isNotEmpty) 'locationDetail': _detailCtrl.text.trim(),
        if (_categoryId != null) 'categoryId': _categoryId,
      });
      final id = res.data['report']['id'];
      if (_images.isNotEmpty) {
        setState(() => _progress = 'Mengupload ${_images.length} foto...');
        final form = FormData.fromMap({'images': await Future.wait(_images.map((f) => MultipartFile.fromFile(f.path, filename: f.path.split('/').last)))});
        await api.postForm('/api/upload/report/$id', form);
      }
      if (mounted) context.go('/home');
    } catch (_) { if (mounted) setState(() { _error = 'Gagal mengirim laporan'; _loading = false; _progress = null; }); }
  }
}
