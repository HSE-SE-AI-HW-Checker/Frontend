import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aichecker/services/token_storage.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // saveTokens / getters
  // ---------------------------------------------------------------------------
  group('TokenStorage.saveTokens', () {
    test('stores access token, refresh token and token type', () async {
      await TokenStorage.saveTokens(
        accessToken: 'access-abc',
        refreshToken: 'refresh-xyz',
        tokenType: 'bearer',
      );

      expect(await TokenStorage.getAccessToken(), 'access-abc');
      expect(await TokenStorage.getRefreshToken(), 'refresh-xyz');
      expect(await TokenStorage.getTokenType(), 'bearer');
    });

    test('overwrites previously saved tokens', () async {
      await TokenStorage.saveTokens(
          accessToken: 'old', refreshToken: 'old-r', tokenType: 'bearer');
      await TokenStorage.saveTokens(
          accessToken: 'new', refreshToken: 'new-r', tokenType: 'bearer');

      expect(await TokenStorage.getAccessToken(), 'new');
      expect(await TokenStorage.getRefreshToken(), 'new-r');
    });

    test('defaults token type to bearer', () async {
      await TokenStorage.saveTokens(
          accessToken: 'tok', refreshToken: 'ref');

      expect(await TokenStorage.getTokenType(), 'bearer');
    });
  });

  // ---------------------------------------------------------------------------
  // getAccessToken
  // ---------------------------------------------------------------------------
  group('TokenStorage.getAccessToken', () {
    test('returns null when no token saved', () async {
      expect(await TokenStorage.getAccessToken(), isNull);
    });

    test('returns saved token', () async {
      await TokenStorage.saveTokens(
          accessToken: 'tok-123', refreshToken: '');
      expect(await TokenStorage.getAccessToken(), 'tok-123');
    });
  });

  // ---------------------------------------------------------------------------
  // hasTokens
  // ---------------------------------------------------------------------------
  group('TokenStorage.hasTokens', () {
    test('returns false when no tokens stored', () async {
      expect(await TokenStorage.hasTokens(), isFalse);
    });

    test('returns true after saving a non-empty access token', () async {
      await TokenStorage.saveTokens(
          accessToken: 'valid-token', refreshToken: '');
      expect(await TokenStorage.hasTokens(), isTrue);
    });

    test('returns false when access token is empty string', () async {
      await TokenStorage.saveTokens(accessToken: '', refreshToken: '');
      expect(await TokenStorage.hasTokens(), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // clearTokens
  // ---------------------------------------------------------------------------
  group('TokenStorage.clearTokens', () {
    test('removes all tokens', () async {
      await TokenStorage.saveTokens(
          accessToken: 'tok', refreshToken: 'ref', tokenType: 'bearer');
      await TokenStorage.clearTokens();

      expect(await TokenStorage.getAccessToken(), isNull);
      expect(await TokenStorage.getRefreshToken(), isNull);
      expect(await TokenStorage.hasTokens(), isFalse);
    });

    test('does not throw when called with no tokens stored', () async {
      await expectLater(TokenStorage.clearTokens(), completes);
    });
  });

  // ---------------------------------------------------------------------------
  // getAuthorizationHeader
  // ---------------------------------------------------------------------------
  group('TokenStorage.getAuthorizationHeader', () {
    test('returns null when no token stored', () async {
      expect(await TokenStorage.getAuthorizationHeader(), isNull);
    });

    test('returns null when access token is empty', () async {
      await TokenStorage.saveTokens(accessToken: '', refreshToken: '');
      expect(await TokenStorage.getAuthorizationHeader(), isNull);
    });

    test('returns formatted header with token type and access token', () async {
      await TokenStorage.saveTokens(
          accessToken: 'abc123', refreshToken: '', tokenType: 'bearer');
      expect(
        await TokenStorage.getAuthorizationHeader(),
        'bearer abc123',
      );
    });

    test('uses custom token type in header', () async {
      await TokenStorage.saveTokens(
          accessToken: 'tok', refreshToken: '', tokenType: 'Token');
      expect(await TokenStorage.getAuthorizationHeader(), 'Token tok');
    });
  });
}
