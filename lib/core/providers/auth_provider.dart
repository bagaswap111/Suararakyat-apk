import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/models.dart';
import '../utils/auth_storage.dart';

enum AuthType { none, user, government }

class AuthState {
  final AuthType type;
  final String? token;
  final User? user;
  final GovOfficial? official;
  final bool loading;
  final String? error;
  const AuthState({this.type = AuthType.none, this.token, this.user, this.official, this.loading = false, this.error});
  AuthState copyWith({AuthType? type, String? token, User? user, GovOfficial? official, bool? loading, String? error}) =>
      AuthState(type: type ?? this.type, token: token ?? this.token, user: user ?? this.user,
        official: official ?? this.official, loading: loading ?? this.loading, error: error);
  bool get isAuth => token != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  AuthNotifier(this._api) : super(const AuthState()) { _init(); }

  Future<void> _init() async {
    final token = await AuthStorage.getToken();
    if (token == null) return;
    final type = await AuthStorage.get('auth_type');
    if (type == 'government') {
      state = AuthState(
        type: AuthType.government, token: token,
        official: GovOfficial(
          id: await AuthStorage.get('gov_id') ?? '',
          username: await AuthStorage.get('gov_username') ?? '',
          fullName: await AuthStorage.get('gov_fullname') ?? '',
          agency: await AuthStorage.get('gov_agency') ?? '',
          role: await AuthStorage.get('gov_role') ?? 'analyst',
        ),
      );
    } else if (type == 'user') {
      state = AuthState(
        type: AuthType.user, token: token,
        user: User(id: await AuthStorage.get('user_id') ?? '', displayId: await AuthStorage.get('user_display_id') ?? ''),
      );
    }
  }

  Future<bool> registerUser(String password, {String? contact}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.post('/api/auth/register', data: {'password': password, if (contact != null && contact.isNotEmpty) 'contact': contact});
      final token = res.data['token'] as String;
      final user = User.fromJson(res.data['user']);
      await AuthStorage.saveToken(token);
      await AuthStorage.save('auth_type', 'user');
      await AuthStorage.save('user_id', user.id);
      await AuthStorage.save('user_display_id', user.displayId);
      state = AuthState(type: AuthType.user, token: token, user: user);
      return true;
    } catch (e) { state = state.copyWith(loading: false, error: _err(e)); return false; }
  }

  Future<bool> loginUser(String displayId, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.post('/api/auth/login', data: {'displayId': displayId, 'password': password});
      final token = res.data['token'] as String;
      final user = User.fromJson(res.data['user']);
      await AuthStorage.saveToken(token);
      await AuthStorage.save('auth_type', 'user');
      await AuthStorage.save('user_id', user.id);
      await AuthStorage.save('user_display_id', user.displayId);
      state = AuthState(type: AuthType.user, token: token, user: user);
      return true;
    } catch (e) { state = state.copyWith(loading: false, error: _err(e)); return false; }
  }

  Future<bool> loginGov(String username, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.post('/api/auth/gov/login', data: {'username': username, 'password': password});
      final token = res.data['token'] as String;
      final official = GovOfficial.fromJson(res.data['official']);
      await AuthStorage.saveToken(token);
      await AuthStorage.save('auth_type', 'government');
      await AuthStorage.save('gov_id', official.id);
      await AuthStorage.save('gov_username', official.username);
      await AuthStorage.save('gov_fullname', official.fullName);
      await AuthStorage.save('gov_agency', official.agency);
      await AuthStorage.save('gov_role', official.role);
      state = AuthState(type: AuthType.government, token: token, official: official);
      return true;
    } catch (e) { state = state.copyWith(loading: false, error: _err(e)); return false; }
  }

  Future<void> logout() async { await AuthStorage.clear(); state = const AuthState(); }

  String _err(dynamic e) { try { return e.response?.data?['error'] ?? e.toString(); } catch (_) { return 'Terjadi kesalahan'; } }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref.read(apiClientProvider)));
