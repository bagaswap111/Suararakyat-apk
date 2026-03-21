import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _s = FlutterSecureStorage();
  static Future<void> saveToken(String t) => _s.write(key: 'token', value: t);
  static Future<void> save(String k, String v) => _s.write(key: k, value: v);
  static Future<String?> getToken() => _s.read(key: 'token');
  static Future<String?> get(String k) => _s.read(key: k);
  static Future<void> clear() => _s.deleteAll();
}
