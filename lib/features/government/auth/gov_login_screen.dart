import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/themes.dart';
import '../../../core/widgets/shared_widgets.dart';

class GovLoginScreen extends ConsumerStatefulWidget {
  const GovLoginScreen({super.key});
  @override
  ConsumerState<GovLoginScreen> createState() => _State();
}

class _State extends ConsumerState<GovLoginScreen> {
  final _userCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: SRColors.bg,
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(children: [
        const SizedBox(height: 60),
        Container(width: 72, height: 72,
          decoration: BoxDecoration(color: SRColors.govAccent, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 36)),
        const SizedBox(height: 20),
        const Text('Portal Pejabat', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: SRColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('Sistem Manajemen Aduan Whistleblower', style: TextStyle(fontSize: 13, color: SRColors.textMuted), textAlign: TextAlign.center),
        const SizedBox(height: 48),
        if (auth.error != null) ErrorBox(auth.error!),
        TextField(
          controller: _userCtrl,
          style: const TextStyle(color: SRColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.badge_outlined)),
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
        const SizedBox(height: 28),
        LoadingButton(
          loading: auth.loading,
          onPressed: _login,
          label: 'Masuk ke Portal',
          color: SRColors.govAccent,
        ),
      ]))),
    );
  }

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _pwCtrl.text.isEmpty) return;
    final ok = await ref.read(authProvider.notifier).loginGov(_userCtrl.text.trim(), _pwCtrl.text);
    if (ok && mounted) context.go('/dashboard');
  }
}
