import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/themes.dart';
import '../../../core/widgets/shared_widgets.dart';

class GovProfileScreen extends ConsumerStatefulWidget {
  const GovProfileScreen({super.key});
  @override
  ConsumerState<GovProfileScreen> createState() => _State();
}

class _State extends ConsumerState<GovProfileScreen> {
  final _oldPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  bool _saving = false, _obscureOld = true, _obscureNew = true;
  String? _msg, _error;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final official = auth.official;
    return Scaffold(
      backgroundColor: SRColors.bg,
      appBar: AppBar(title: const Text('Profil'), actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: () async {
          await ref.read(authProvider.notifier).logout();
          if (mounted) context.go('/login');
        }),
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // Profile header
        Center(child: Column(children: [
          CircleAvatar(radius: 36, backgroundColor: SRColors.govAccent.withOpacity(0.2),
            child: Text(official?.fullName.isNotEmpty == true ? official!.fullName[0].toUpperCase() : '?',
              style: const TextStyle(color: SRColors.govAccent, fontWeight: FontWeight.w900, fontSize: 28))),
          const SizedBox(height: 12),
          Text(official?.fullName ?? '', style: const TextStyle(color: SRColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('@${official?.username ?? ''}', style: const TextStyle(color: SRColors.textMuted, fontSize: 13)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: SRColors.govAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
              child: Text(official?.role.toUpperCase() ?? '', style: const TextStyle(color: SRColors.govAccent, fontSize: 11, fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            Text(official?.agency ?? '', style: const TextStyle(color: SRColors.textSecond, fontSize: 12)),
          ]),
        ])),
        const SizedBox(height: 32),
        const Divider(color: SRColors.border),
        const SizedBox(height: 16),
        const Text('Ganti Password', style: TextStyle(color: SRColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 14),
        if (_msg != null) Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: SRColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_msg!, style: const TextStyle(color: SRColors.success, fontSize: 13))),
        if (_error != null) ErrorBox(_error!),
        TextField(controller: _oldPwCtrl, obscureText: _obscureOld, style: const TextStyle(color: SRColors.textPrimary),
          decoration: InputDecoration(labelText: 'Password Lama', prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility, color: SRColors.textMuted), onPressed: () => setState(() => _obscureOld = !_obscureOld)))),
        const SizedBox(height: 12),
        TextField(controller: _newPwCtrl, obscureText: _obscureNew, style: const TextStyle(color: SRColors.textPrimary),
          decoration: InputDecoration(labelText: 'Password Baru', hintText: 'Minimal 6 karakter', prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: SRColors.textMuted), onPressed: () => setState(() => _obscureNew = !_obscureNew)))),
        const SizedBox(height: 16),
        LoadingButton(loading: _saving, onPressed: _changePassword, label: 'Ganti Password', color: SRColors.govAccent),
      ]),
    );
  }

  Future<void> _changePassword() async {
    if (_oldPwCtrl.text.isEmpty || _newPwCtrl.text.isEmpty) return;
    if (_newPwCtrl.text.length < 6) { setState(() => _error = 'Password baru minimal 6 karakter'); return; }
    setState(() { _saving = true; _error = null; _msg = null; });
    try {
      await ref.read(apiClientProvider).post('/api/government/me/change-password', data: {'currentPassword': _oldPwCtrl.text, 'newPassword': _newPwCtrl.text});
      if (mounted) { setState(() { _msg = 'Password berhasil diubah'; _saving = false; }); _oldPwCtrl.clear(); _newPwCtrl.clear(); }
    } catch (e) {
      String err = 'Gagal mengubah password';
      try { err = (e as dynamic).response?.data?['error'] ?? err; } catch (_) {}
      if (mounted) setState(() { _error = err; _saving = false; });
    }
  }
}
