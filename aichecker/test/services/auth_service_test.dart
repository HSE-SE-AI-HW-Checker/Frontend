import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aichecker/services/api_client.dart';
import 'package:aichecker/services/auth_service.dart';
import 'package:aichecker/services/token_storage.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late AuthService authService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dio = ApiClient().dio;
    dioAdapter = DioAdapter(dio: dio, matcher: const FullHttpRequestMatcher());
    authService = AuthService();
  });

  tearDown(() {
    dioAdapter.close();
  });

  // ---------------------------------------------------------------------------
  // login
  // ---------------------------------------------------------------------------
  group('AuthService.login', () {
    test('returns success map and saves tokens on 200', () async {
      dioAdapter.onPost(
        '/sign_in',
        (server) => server.reply(200, {
          'access_token': 'access-abc',
          'refresh_token': 'refresh-xyz',
          'token_type': 'bearer',
          'message': 'Успешная авторизация',
        }),
        data: {'email': 'user@test.com', 'password': 'secret'},
      );

      final result = await authService.login('user@test.com', 'secret');

      expect(result['success'], isTrue);
      expect(result['error'], isFalse);
      expect(await TokenStorage.getAccessToken(), 'access-abc');
      expect(await TokenStorage.getRefreshToken(), 'refresh-xyz');
    });

    test('returns custom message from server', () async {
      dioAdapter.onPost(
        '/sign_in',
        (server) => server.reply(200, {
          'access_token': 'tok',
          'message': 'Welcome back',
        }),
        data: {'email': 'u@e.com', 'password': 'p'},
      );

      final result = await authService.login('u@e.com', 'p');

      expect(result['message'], 'Welcome back');
    });

    test('returns error map and does not save tokens on 401', () async {
      dioAdapter.onPost(
        '/sign_in',
        (server) => server.reply(401, {'message': 'Invalid credentials'}),
        data: {'email': 'bad@test.com', 'password': 'wrong'},
      );

      final result = await authService.login('bad@test.com', 'wrong');

      expect(result['success'], isFalse);
      expect(result['error'], isTrue);
      expect(await TokenStorage.getAccessToken(), isNull);
    });

    test('returns error map on 500', () async {
      dioAdapter.onPost(
        '/sign_in',
        (server) => server.reply(500, {'message': 'Server error'}),
        data: {'email': 'u@e.com', 'password': 'p'},
      );

      final result = await authService.login('u@e.com', 'p');

      expect(result['success'], isFalse);
      expect(result['error'], isTrue);
    });

    test('does not save tokens when access_token is absent', () async {
      dioAdapter.onPost(
        '/sign_in',
        (server) => server.reply(200, {'message': 'OK', 'error': false}),
        data: {'email': 'u@e.com', 'password': 'p'},
      );

      await authService.login('u@e.com', 'p');

      expect(await TokenStorage.getAccessToken(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // register
  // ---------------------------------------------------------------------------
  group('AuthService.register', () {
    test('returns success map and saves tokens on 200', () async {
      dioAdapter.onPost(
        '/sign_up',
        (server) => server.reply(200, {
          'access_token': 'new-tok',
          'refresh_token': 'new-ref',
          'token_type': 'bearer',
          'message': 'Registered',
        }),
        data: {
          'username': 'ivan',
          'email': 'ivan@test.com',
          'password': 'pass123',
        },
      );

      final result =
          await authService.register('ivan', 'ivan@test.com', 'pass123');

      expect(result['success'], isTrue);
      expect(await TokenStorage.getAccessToken(), 'new-tok');
    });

    test('returns error map on 422 validation error', () async {
      dioAdapter.onPost(
        '/sign_up',
        (server) => server.reply(422, {'detail': 'email already taken'}),
        data: {
          'username': 'ivan',
          'email': 'dup@test.com',
          'password': 'pass',
        },
      );

      final result =
          await authService.register('ivan', 'dup@test.com', 'pass');

      expect(result['success'], isFalse);
      expect(result['error'], isTrue);
    });

    test('uses default success message when absent', () async {
      dioAdapter.onPost(
        '/sign_up',
        (server) => server.reply(200, {'access_token': 'tok'}),
        data: {
          'username': 'u',
          'email': 'u@e.com',
          'password': 'p',
        },
      );

      final result = await authService.register('u', 'u@e.com', 'p');

      expect(result['message'], 'Успешная регистрация');
    });
  });

  // ---------------------------------------------------------------------------
  // logout
  // ---------------------------------------------------------------------------
  group('AuthService.logout', () {
    test('clears local tokens and returns success on 200', () async {
      await TokenStorage.saveTokens(
          accessToken: 'tok', refreshToken: 'ref');

      dioAdapter.onPost(
        '/logout',
        (server) =>
            server.reply(200, {'success': true, 'message': 'Logged out'}),
      );

      final result = await authService.logout();

      expect(result['success'], isTrue);
      expect(await TokenStorage.getAccessToken(), isNull);
    });

    test('clears local tokens even when server returns error', () async {
      await TokenStorage.saveTokens(
          accessToken: 'tok', refreshToken: 'ref');

      dioAdapter.onPost(
        '/logout',
        (server) => server.reply(500, {'message': 'Server error'}),
      );

      final result = await authService.logout();

      expect(result['success'], isTrue);
      expect(await TokenStorage.getAccessToken(), isNull);
    });

    test('returns server message when present', () async {
      dioAdapter.onPost(
        '/logout',
        (server) =>
            server.reply(200, {'success': true, 'message': 'Bye!'}),
      );

      final result = await authService.logout();

      expect(result['message'], 'Bye!');
    });
  });

  // ---------------------------------------------------------------------------
  // getProfile
  // ---------------------------------------------------------------------------
  group('AuthService.getProfile', () {
    test('returns success map with data on 200', () async {
      dioAdapter.onGet(
        '/me',
        (server) => server.reply(200, {
          'id': 'u1',
          'username': 'ivan',
          'email': 'ivan@test.com',
        }),
      );

      final result = await authService.getProfile();

      expect(result['success'], isTrue);
      expect(result['data']['username'], 'ivan');
      expect(result['data']['email'], 'ivan@test.com');
    });

    test('returns error map on 401', () async {
      dioAdapter.onGet(
        '/me',
        (server) => server.reply(401, {'detail': 'Not authenticated'}),
      );

      final result = await authService.getProfile();

      expect(result['success'], isFalse);
      expect(result['error'], isTrue);
    });

    test('returns error map on 500', () async {
      dioAdapter.onGet(
        '/me',
        (server) => server.reply(500, {'message': 'Internal error'}),
      );

      final result = await authService.getProfile();

      expect(result['success'], isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // isAuthenticated
  // ---------------------------------------------------------------------------
  group('AuthService.isAuthenticated', () {
    test('returns false when no tokens stored', () async {
      expect(await authService.isAuthenticated(), isFalse);
    });

    test('returns true when access token exists', () async {
      await TokenStorage.saveTokens(
          accessToken: 'valid-token', refreshToken: '');
      expect(await authService.isAuthenticated(), isTrue);
    });

    test('returns false after tokens are cleared', () async {
      await TokenStorage.saveTokens(
          accessToken: 'tok', refreshToken: '');
      await TokenStorage.clearTokens();
      expect(await authService.isAuthenticated(), isFalse);
    });
  });
}
