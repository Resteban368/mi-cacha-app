import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../storage/secure_storage_keys.dart';
import 'session.dart';

/// Persiste la sesión en `flutter_secure_storage` (Keychain / Keystore /
/// almacenamiento cifrado en web).
abstract interface class SessionStorage {
  Future<Session?> read();

  Future<void> write(Session session);

  Future<void> clear();
}

class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<Session?> read() async {
    final token = await _storage.read(key: SecureStorageKeys.accessToken);
    if (token == null || token.isEmpty) return null;
    return Session(
      accessToken: token,
      role: await _storage.read(key: SecureStorageKeys.userRole) ?? '',
      displayName:
          await _storage.read(key: SecureStorageKeys.userDisplayName) ?? '',
    );
  }

  @override
  Future<void> write(Session session) async {
    await _storage.write(
      key: SecureStorageKeys.accessToken,
      value: session.accessToken,
    );
    await _storage.write(key: SecureStorageKeys.userRole, value: session.role);
    await _storage.write(
      key: SecureStorageKeys.userDisplayName,
      value: session.displayName,
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: SecureStorageKeys.accessToken);
    await _storage.delete(key: SecureStorageKeys.userRole);
    await _storage.delete(key: SecureStorageKeys.userDisplayName);
  }
}
