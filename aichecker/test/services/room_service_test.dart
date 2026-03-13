import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aichecker/services/api_client.dart';
import 'package:aichecker/services/room_service.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late RoomService roomService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    dio = ApiClient().dio;
    dioAdapter = DioAdapter(dio: dio, matcher: const FullHttpRequestMatcher());
    roomService = RoomService();
  });

  tearDown(() {
    dioAdapter.close();
  });

  // ---------------------------------------------------------------------------
  // getRecentRooms
  // ---------------------------------------------------------------------------
  group('RoomService.getRecentRooms', () {
    test('returns list of rooms on 200', () async {
      dioAdapter.onGet('/rooms/recent', (server) => server.reply(200, [
            {'id': 'r1', 'name': 'Recent Room', 'participant_count': 2, 'user_score': 75},
          ]));

      final rooms = await roomService.getRecentRooms();

      expect(rooms.length, 1);
      expect(rooms[0].id, 'r1');
      expect(rooms[0].name, 'Recent Room');
      expect(rooms[0].userScore, 75);
    });

    test('returns empty list on empty array', () async {
      dioAdapter.onGet('/rooms/recent', (server) => server.reply(200, []));

      final rooms = await roomService.getRecentRooms();

      expect(rooms, isEmpty);
    });

    test('throws exception on server error', () async {
      dioAdapter.onGet(
        '/rooms/recent',
        (server) => server.reply(500, {'message': 'Server error'}),
      );

      expect(() => roomService.getRecentRooms(), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // getMyRooms
  // ---------------------------------------------------------------------------
  group('RoomService.getMyRooms', () {
    test('returns list of rooms on 200', () async {
      dioAdapter.onGet('/rooms', (server) => server.reply(200, [
            {'id': '1', 'name': 'Room 1', 'participant_count': 3},
            {'id': '2', 'name': 'Room 2', 'participant_count': 5},
          ]));

      final rooms = await roomService.getMyRooms();

      expect(rooms.length, 2);
      expect(rooms[0].id, '1');
      expect(rooms[0].name, 'Room 1');
      expect(rooms[1].participants, 5);
    });

    test('throws exception on server error', () async {
      dioAdapter.onGet(
        '/rooms',
        (server) => server.reply(500, {'message': 'Internal Server Error'}),
      );

      expect(() => roomService.getMyRooms(), throwsException);
    });

    test('throws exception on 401 unauthorized', () async {
      dioAdapter.onGet(
        '/rooms',
        (server) => server.reply(401, {'detail': 'Unauthorized'}),
      );

      expect(() => roomService.getMyRooms(), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // getLanguages
  // ---------------------------------------------------------------------------
  group('RoomService.getLanguages', () {
    test('returns list of language strings on 200', () async {
      dioAdapter.onGet(
        '/languages',
        (server) => server.reply(200, ['Python', 'Java', 'Kotlin']),
      );

      final languages = await roomService.getLanguages();

      expect(languages, ['Python', 'Java', 'Kotlin']);
    });

    test('returns empty list when server returns empty array', () async {
      dioAdapter.onGet('/languages', (server) => server.reply(200, []));

      final languages = await roomService.getLanguages();

      expect(languages, isEmpty);
    });

    test('throws exception on server error', () async {
      dioAdapter.onGet(
        '/languages',
        (server) => server.reply(500, {'message': 'error'}),
      );

      expect(() => roomService.getLanguages(), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // getRoom
  // ---------------------------------------------------------------------------
  group('RoomService.getRoom', () {
    test('returns RoomDetail on 200', () async {
      dioAdapter.onGet('/rooms/room-42', (server) => server.reply(200, {
            'id': 'room-42',
            'name': 'Advanced Dart',
            'description': 'Master Dart patterns',
            'language': 'Dart',
            'created_at': '2024-03-01T00:00:00Z',
            'participant_count': 12,
            'criteria': [
              {'criterion_text': 'Tests >= 80%', 'is_ai_verified': true},
            ],
          }));

      final detail = await roomService.getRoom('room-42');

      expect(detail.id, 'room-42');
      expect(detail.name, 'Advanced Dart');
      expect(detail.language, 'Dart');
      expect(detail.participantCount, 12);
      expect(detail.criteria.length, 1);
      expect(detail.criteria[0].isAiVerified, true);
    });

    test('throws exception on 404', () async {
      dioAdapter.onGet(
        '/rooms/nonexistent',
        (server) => server.reply(404, {'message': 'Room not found'}),
      );

      expect(() => roomService.getRoom('nonexistent'), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // joinRoom
  // ---------------------------------------------------------------------------
  group('RoomService.joinRoom', () {
    test('returns response data on 200', () async {
      dioAdapter.onPost(
        '/rooms/room-1/join',
        (server) => server.reply(200, {'message': 'Joined successfully'}),
        data: {'password': 'secret'},
      );

      final result = await roomService.joinRoom('room-1', 'secret');

      expect(result['message'], 'Joined successfully');
    });

    test('throws exception on wrong password (403)', () async {
      dioAdapter.onPost(
        '/rooms/room-1/join',
        (server) => server.reply(403, {'message': 'Invalid password'}),
        data: {'password': 'wrong'},
      );

      expect(() => roomService.joinRoom('room-1', 'wrong'), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // verifyCriterion
  // ---------------------------------------------------------------------------
  group('RoomService.verifyCriterion', () {
    test('returns true when criterion can be AI verified', () async {
      dioAdapter.onPost(
        '/criteria/verify',
        (server) => server.reply(200, {'can_ai_verified': true}),
        data: {'criterion_text': 'Test coverage >= 80%'},
      );

      final result = await roomService.verifyCriterion('Test coverage >= 80%');

      expect(result, isTrue);
    });

    test('returns false when criterion cannot be AI verified', () async {
      dioAdapter.onPost(
        '/criteria/verify',
        (server) => server.reply(200, {'can_ai_verified': false}),
        data: {'criterion_text': 'Code looks clean'},
      );

      final result = await roomService.verifyCriterion('Code looks clean');

      expect(result, isFalse);
    });

    test('throws exception on 422 unprocessable entity', () async {
      dioAdapter.onPost(
        '/criteria/verify',
        (server) => server.reply(422, {'detail': 'criterion_text required'}),
        data: {'criterion_text': ''},
      );

      expect(() => roomService.verifyCriterion(''), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // createRoom
  // ---------------------------------------------------------------------------
  group('RoomService.createRoom', () {
    test('completes without error on 201', () async {
      dioAdapter.onPost(
        '/create_room',
        (server) => server.reply(201, {'id': 'new-room-id'}),
        data: {
          'name': 'New Room',
          'description': 'A test room',
          'criteria': [
            {'criterion_text': 'Some criterion', 'is_ai_verified': false},
          ],
          'language': 'Python',
        },
      );

      await expectLater(
        roomService.createRoom(
          name: 'New Room',
          description: 'A test room',
          criteria: [
            {'criterion_text': 'Some criterion', 'is_ai_verified': false},
          ],
          language: 'Python',
        ),
        completes,
      );
    });

    test('sends request without language when not provided', () async {
      dioAdapter.onPost(
        '/create_room',
        (server) => server.reply(201, {}),
        data: {
          'name': 'No Lang Room',
          'description': 'Desc',
          'criteria': [],
        },
      );

      await expectLater(
        roomService.createRoom(
          name: 'No Lang Room',
          description: 'Desc',
          criteria: [],
        ),
        completes,
      );
    });

    test('throws exception on 422 validation error', () async {
      dioAdapter.onPost(
        '/create_room',
        (server) => server.reply(422, {'detail': 'name required'}),
        data: {
          'name': '',
          'description': '',
          'criteria': [],
        },
      );

      expect(
        () => roomService.createRoom(
          name: '',
          description: '',
          criteria: [],
        ),
        throwsException,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // submitSolution
  // ---------------------------------------------------------------------------
  group('RoomService.submitSolution', () {
    test('returns success map on 200', () async {
      dioAdapter.onPost(
        '/submit',
        (server) => server.reply(200, {'message': 'Solution received'}),
        data: {'data': 'https://github.com/user/repo', 'data_type': 0},
      );

      final result = await roomService.submitSolution('https://github.com/user/repo');

      expect(result['success'], isTrue);
      expect(result['message'], 'Solution received');
    });

    test('returns error map (not throws) on server error', () async {
      dioAdapter.onPost(
        '/submit',
        (server) => server.reply(400, {'message': 'Bad request'}),
        data: {'data': 'bad-url', 'data_type': 0},
      );

      final result = await roomService.submitSolution('bad-url');

      expect(result['success'], isFalse);
      expect(result['error'], isTrue);
    });
  });
}
