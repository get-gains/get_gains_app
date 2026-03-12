import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_gains_app/services/storage/secure_storage_service.dart';

/// In-memory fake of [FlutterSecureStorage] for testing.
///
/// Only the core CRUD methods are implemented; everything else
/// (listeners, Cupertino availability, etc.) falls through to
/// [noSuchMethod] which returns sensible defaults for optional members.
class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_store);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.clear();
  }

  /// Expose for test assertions.
  Map<String, String> get store => Map.unmodifiable(_store);
}

/// Creates a valid JWT token string with the given [exp] (seconds since epoch).
/// The header and payload are real base64url-encoded JSON; signature is a dummy.
String _createJwt({required int exp}) {
  final header = base64Url.encode(
    utf8.encode(json.encode({'alg': 'HS256', 'typ': 'JWT'})),
  );
  final payload = base64Url.encode(
    utf8.encode(json.encode({'sub': 'user123', 'exp': exp})),
  );
  return '$header.$payload.fake_signature';
}

void main() {
  late FakeFlutterSecureStorage fakeStorage;
  late SecureStorageService service;

  setUp(() {
    fakeStorage = FakeFlutterSecureStorage();
    service = SecureStorageService(storage: fakeStorage);
  });

  group('getExpiryFromJwt', () {
    test('extracts expiry from a valid JWT', () {
      final futureExp =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
      final token = _createJwt(exp: futureExp);
      final expiry = SecureStorageService.getExpiryFromJwt(token);

      expect(expiry, isNotNull);
      expect(expiry!.difference(DateTime.now()).inMinutes, closeTo(60, 1));
    });

    test('returns null for malformed token', () {
      expect(SecureStorageService.getExpiryFromJwt('not.a.jwt'), isNull);
      expect(SecureStorageService.getExpiryFromJwt('single_segment'), isNull);
      expect(SecureStorageService.getExpiryFromJwt(''), isNull);
    });

    test('returns null when exp claim is missing', () {
      final header = base64Url.encode(
        utf8.encode(json.encode({'alg': 'HS256'})),
      );
      final payload = base64Url.encode(
        utf8.encode(json.encode({'sub': 'user123'})),
      );
      final token = '$header.$payload.sig';
      expect(SecureStorageService.getExpiryFromJwt(token), isNull);
    });
  });

  group('isTokenExpired', () {
    test('returns false when stored expiry is in the future', () async {
      final future = DateTime.now().add(const Duration(hours: 1));
      await service.saveAccessToken('some_token');
      await service.saveTokenExpiry(future);

      expect(await service.isTokenExpired(), isFalse);
    });

    test('returns true when stored expiry is in the past', () async {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      await service.saveAccessToken('some_token');
      await service.saveTokenExpiry(past);

      expect(await service.isTokenExpired(), isTrue);
    });

    test(
      'falls back to JWT exp claim when no stored expiry (valid token)',
      () async {
        final futureExp =
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000;
        final jwt = _createJwt(exp: futureExp);
        await service.saveAccessToken(jwt);
        // No saveTokenExpiry called

        expect(await service.isTokenExpired(), isFalse);

        // Verify it also persisted the expiry for future fast reads
        expect(fakeStorage.store.containsKey('token_expiry'), isTrue);
      },
    );

    test(
      'falls back to JWT exp claim when no stored expiry (expired token)',
      () async {
        final pastExp =
            DateTime.now()
                .subtract(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000;
        final jwt = _createJwt(exp: pastExp);
        await service.saveAccessToken(jwt);

        expect(await service.isTokenExpired(), isTrue);
      },
    );

    test('returns false when no expiry info at all (non-JWT token)', () async {
      await service.saveAccessToken('opaque_token_no_jwt');
      // No stored expiry, token can't be decoded as JWT

      // Should NOT consider expired — let the server decide
      expect(await service.isTokenExpired(), isFalse);
    });
  });

  group('isAuthenticated', () {
    test('returns false when no access token exists', () async {
      expect(await service.isAuthenticated(), isFalse);
    });

    test('returns true when access token exists and is not expired', () async {
      final futureExp =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
      final jwt = _createJwt(exp: futureExp);
      await service.saveTokens(accessToken: jwt, refreshToken: 'refresh_123');

      expect(await service.isAuthenticated(), isTrue);
    });

    test(
      'returns true when access token is expired but refresh token exists',
      () async {
        final pastExp =
            DateTime.now()
                .subtract(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000;
        final jwt = _createJwt(exp: pastExp);
        await service.saveTokens(accessToken: jwt, refreshToken: 'refresh_456');

        // Access token expired, but refresh token exists → recoverable
        expect(await service.isAuthenticated(), isTrue);
      },
    );

    test(
      'returns false when access token is expired and no refresh token',
      () async {
        final pastExp =
            DateTime.now()
                .subtract(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000;
        final jwt = _createJwt(exp: pastExp);
        await service.saveAccessToken(jwt);
        // No refresh token saved

        expect(await service.isAuthenticated(), isFalse);
      },
    );

    test(
      'persists through simulated restart (tokens saved → new service instance reads them)',
      () async {
        // Simulate first app session: login saves tokens
        final futureExp =
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000;
        final jwt = _createJwt(exp: futureExp);
        await service.saveTokens(
          accessToken: jwt,
          refreshToken: 'refresh_persist',
        );
        await service.saveUserId('user_42');
        await service.saveUserEmail('user@example.com');

        // Simulate app restart: create a new service instance with same backing store
        final newService = SecureStorageService(storage: fakeStorage);

        expect(await newService.isAuthenticated(), isTrue);
        expect(await newService.getUserId(), equals('user_42'));
        expect(await newService.getUserEmail(), equals('user@example.com'));
        expect(await newService.getAccessToken(), equals(jwt));
        expect(await newService.getRefreshToken(), equals('refresh_persist'));
      },
    );

    test('returns false after logout clears all tokens', () async {
      final futureExp =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
      final jwt = _createJwt(exp: futureExp);
      await service.saveTokens(
        accessToken: jwt,
        refreshToken: 'refresh_logout',
      );
      expect(await service.isAuthenticated(), isTrue);

      // Simulate logout
      await service.clearTokens();

      expect(await service.isAuthenticated(), isFalse);
      expect(await service.getAccessToken(), isNull);
      expect(await service.getRefreshToken(), isNull);
    });
  });

  group('saveTokens', () {
    test('saves access token, refresh token, and optional expiry', () async {
      final expiry = DateTime.now().add(const Duration(hours: 2));
      await service.saveTokens(
        accessToken: 'access_1',
        refreshToken: 'refresh_1',
        expiry: expiry,
      );

      expect(await service.getAccessToken(), equals('access_1'));
      expect(await service.getRefreshToken(), equals('refresh_1'));
      final storedExpiry = await service.getTokenExpiry();
      expect(storedExpiry, isNotNull);
    });

    test('saves without expiry and still works', () async {
      await service.saveTokens(
        accessToken: 'access_2',
        refreshToken: 'refresh_2',
      );

      expect(await service.getAccessToken(), equals('access_2'));
      expect(await service.getRefreshToken(), equals('refresh_2'));
      // No expiry stored, but isAuthenticated should still work
      expect(await service.isAuthenticated(), isTrue);
    });
  });
}
