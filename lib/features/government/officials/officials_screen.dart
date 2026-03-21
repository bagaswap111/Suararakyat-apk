import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/themes.dart';

class OfficialsScreen extends ConsumerStatefulWidget {
  const OfficialsScreen({super.key});
  @override
  ConsumerState<OfficialsScreen> createState() => _State();
}

class _State extends ConsumerState<OfficialsScreen> {
  List<dynamic> _officials = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ref.read(apiClientProvider).get('/api/government/officials');
      if (mounted) setState(() { _officials = res.data['officials']; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SRColors.bg,
      appBar: AppBar(title: const Text('Manajemen Pejabat')),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: SRColors.govAccent))
        : RefreshIndicator(onRefresh: _load, color: SRColors.govAccent,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _officials.length,
              itemBuilder: (ctx, i) {
                final o = _officials[i];
                final isActive = o['is_active'] == true;
                final role = o['role'] as String? ?? 'analyst';
                final roleColor = role == 'admin' ? SRColors.danger : role == 'analyst' ? SRColors.publicAccent : SRColors.textMuted;
                return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: SRColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: SRColors.border)),
                  child: Row(children: [
                    CircleAvatar(backgroundColor: SRColors.govAccent.withOpacity(0.15), radius: 22,
                      child: Text((o['full_name'] as String? ?? '?').isNotEmpty ? (o['full_name'] as String)[0].toUpperCase() : '?',
                        style: const TextStyle(color: SRColors.govAccent, fontWeight: FontWeight.w800, fontSize: 16))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o['full_name'] ?? '', style: const TextStyle(color: SRColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('@${o['username']} · ${o['agency']}', style: const TextStyle(color: SRColors.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
                        child: Text(role, style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w700))),
                      const SizedBox(height: 4),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: (isActive ? SRColors.success : SRColors.textMuted).withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
                        child: Text(isActive ? 'Aktif' : 'Nonaktif', style: TextStyle(color: isActive ? SRColors.success : SRColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700))),
                    ]),
                    PopupMenuButton(icon: const Icon(Icons.more_vert, color: SRColors.textMuted, size: 18),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'toggle', child: Text('Ubah Status')),
                        const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                        const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: SRColors.danger))),
                      ],
                      onSelected: (v) {
                        if (v == 'toggle') _toggleActive(o['id'], !isActive);
                        if (v == 'reset') _showResetDialog(o['id'], o['username']);
                        if (v == 'delete') _delete(o['id'], o['full_name']);
                      }),
                  ]));
              })),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: SRColors.govAccent,
        child: const Icon(Icons.person_add, color: Colors.white)),
    );
  }

  Future<void> _toggleActive(String id, bool active) async {
    try { await ref.read(apiClientProvider).put('/api/government/officials/$id', data: {'isActive': active}); _load(); } catch (_) {}
  }

  Future<void> _delete(String id, String name) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: SRColors.bgSecondary,
      title: const Text('Hapus Akun?'),
      content: Text('Akun "$name" akan dihapus permanen.', style: const TextStyle(color: SRColors.textSecond)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: SRColors.danger))),
      ],
    ));
    if (ok == true) {
      try { await ref.read(apiClientProvider).delete('/api/government/officials/$id'); _load(); } catch (_) {}
    }
  }

  void _showAddDialog() {
    final userCtrl = TextEditingController(), nameCtrl = TextEditingController();
    final agencyCtrl = TextEditingController(), pwCtrl = TextEditingController();
    String role = 'analyst';
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
      backgroundColor: SRColors.bgSecondary,
      title: const Text('Tambah Pejabat'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(userCtrl, 'Username'),
        const SizedBox(height: 10),
        _field(nameCtrl, 'Nama Lengkap'),
        const SizedBox(height: 10),
        _field(agencyCtrl, 'Instansi/Dinas'),
        const SizedBox(height: 10),
        _field(pwCtrl, 'Password', obscure: true),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: role, dropdownColor: SRColors.bgSecondary,
          style: const TextStyle(color: SRColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Role', isDense: true),
          items: const [DropdownMenuItem(value: 'analyst', child: Text('Analis')), DropdownMenuItem(value: 'viewer', child: Text('Peninjau')), DropdownMenuItem(value: 'admin', child: Text('Admin'))],
          onChanged: (v) => setSt(() => role = v!)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: SRColors.govAccent),
          onPressed: () async {
            try {
              await ref.read(apiClientProvider).post('/api/government/officials', data: {'username': userCtrl.text, 'fullName': nameCtrl.text, 'agency': agencyCtrl.text, 'password': pwCtrl.text, 'role': role});
              if (context.mounted) Navigator.pop(context);
              _load();
            } catch (_) {}
          }, child: const Text('Buat')),
      ],
    )));
  }

  void _showResetDialog(String id, String username) {
    final pwCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: SRColors.bgSecondary,
      title: Text('Reset Password @$username'),
      content: _field(pwCtrl, 'Password Baru', obscure: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: SRColors.govAccent),
          onPressed: () async {
            try {
              await ref.read(apiClientProvider).post('/api/government/officials/$id/reset-password', data: {'newPassword': pwCtrl.text});
              if (context.mounted) Navigator.pop(context);
            } catch (_) {}
          }, child: const Text('Reset')),
      ],
    ));
  }

  Widget _field(TextEditingController ctrl, String label, {bool obscure = false}) => TextField(
    controller: ctrl, obscureText: obscure, style: const TextStyle(color: SRColors.textPrimary),
    decoration: InputDecoration(labelText: label, isDense: true));
}
