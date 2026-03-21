import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/themes.dart';
import '../../../core/widgets/shared_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _State();
}

class _State extends ConsumerState<RegisterScreen> {
  final _pwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: SRColors.bg,
      appBar: AppBar(title: const Text('Daftar Anonim')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: SRColors.publicAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: SRColors.publicAccent.withOpacity(0.2))),
          child: const Row(children: [
            Icon(Icons.shield_outlined, color: SRColors.publicAccent, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Identitas Anda terlindungi. ID anonim dibuat otomatis sistem.', style: TextStyle(color: SRColors.textSecond, fontSize: 13))),
          ])),
        const SizedBox(height: 24),
        if (auth.error != null) ErrorBox(auth.error!),
        TextField(controller: _pwCtrl, obscureText: _obscure, style: const TextStyle(color: SRColors.textPrimary),
          decoration: InputDecoration(labelText: 'Password', hintText: 'Minimal 6 karakter', prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: SRColors.textMuted), onPressed: () => setState(() => _obscure = !_obscure)))),
        const SizedBox(height: 14),
        TextField(controller: _confirmCtrl, obscureText: true, style: const TextStyle(color: SRColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Konfirmasi Password', prefixIcon: Icon(Icons.lock_outline))),
        const SizedBox(height: 14),
        TextField(controller: _contactCtrl, style: const TextStyle(color: SRColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Kontak (Opsional, terenkripsi)', hintText: 'No. HP / Email', prefixIcon: Icon(Icons.contact_phone_outlined))),
        const SizedBox(height: 6),
        const Text('Hanya tersedia untuk pejabat terverifikasi saat menangani kasus Anda.', style: TextStyle(color: SRColors.textMuted, fontSize: 12)),
        const SizedBox(height: 24),
        LoadingButton(loading: auth.loading, onPressed: _register, label: 'Buat Akun Anonim'),
      ]),
    );
  }

  Future<void> _register() async {
    if (_pwCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak cocok')));
      return;
    }
    if (_pwCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 6 karakter')));
      return;
    }
    final ok = await ref.read(authProvider.notifier).registerUser(_pwCtrl.text, contact: _contactCtrl.text);
    if (ok && mounted) context.go('/home');
  }
}
