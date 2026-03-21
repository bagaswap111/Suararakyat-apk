import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/themes.dart';
import '../../../core/widgets/shared_widgets.dart';

class PublicLoginScreen extends ConsumerStatefulWidget {
  const PublicLoginScreen({super.key});
  @override
  ConsumerState<PublicLoginScreen> createState() => _State();
}

class _State extends ConsumerState<PublicLoginScreen> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: SRColors.bg,
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(children: [
        const SizedBox(height: 40),
        Container(width: 72, height: 72,
          decoration: BoxDecoration(color: SRColors.publicAccent, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 36)),
        const SizedBox(height: 20),
        const Text('SuaraRakyat', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: SRColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('Platform Pelaporan Anonim', style: TextStyle(fontSize: 14, color: SRColors.textMuted)),
        const SizedBox(height: 48),
        if (auth.error != null) ErrorBox(auth.error!),
        TextField(
          controller: _idCtrl,
          style: const TextStyle(color: SRColors.textPrimary),
          decoration: const InputDecoration(labelText: 'ID Anonim', hintText: 'WB-2024-XXXXXX', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _pwCtrl,
          obscureText: _obscure,
          style: const TextStyle(color: SRColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: SRColors.textMuted),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 24),
        LoadingButton(loading: auth.loading, onPressed: _login, label: 'Masuk'),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Belum punya akun? ', style: TextStyle(color: SRColors.textMuted)),
          GestureDetector(
            onTap: () => context.push('/register'),
            child: const Text('Daftar Anonim', style: TextStyle(color: SRColors.publicAccent, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]))),
    );
  }

  Future<void> _login() async {
    if (_idCtrl.text.trim().isEmpty || _pwCtrl.text.isEmpty) return;
    final ok = await ref.read(authProvider.notifier).loginUser(_idCtrl.text.trim(), _pwCtrl.text);
    if (ok && mounted) context.go('/home');
  }
}
