import 'package:flutter_test/flutter_test.dart';
import 'package:aichecker/models/room_detail.dart';

void main() {
  group('RoomCriterion.fromJson', () {
    test('parses criterion_text and is_ai_verified', () {
      final json = {
        'criterion_text': 'Unit test coverage >= 80%',
        'is_ai_verified': true,
      };

      final criterion = RoomCriterion.fromJson(json);

      expect(criterion.criterionText, 'Unit test coverage >= 80%');
      expect(criterion.isAiVerified, true);
    });

    test('defaults isAiVerified to false when field absent', () {
      final json = {'criterion_text': 'Some criterion'};
      expect(RoomCriterion.fromJson(json).isAiVerified, false);
    });

    test('defaults isAiVerified to false when field is null', () {
      final json = {'criterion_text': 'Some criterion', 'is_ai_verified': null};
      expect(RoomCriterion.fromJson(json).isAiVerified, false);
    });

    test('parses is_ai_verified as false', () {
      final json = {
        'criterion_text': 'Manual criterion',
        'is_ai_verified': false,
      };
      expect(RoomCriterion.fromJson(json).isAiVerified, false);
    });
  });

  group('RoomDetail.fromJson', () {
    test('parses full response correctly', () {
      final json = {
        'id': 'room-1',
        'name': 'Backend Course 2024',
        'description': 'Implement a REST API',
        'language': 'Python',
        'created_at': '2024-01-01T10:00:00Z',
        'participant_count': 7,
        'creator_name': 'John Doe',
        'criteria': [
          {'criterion_text': 'Criterion A', 'is_ai_verified': true},
          {'criterion_text': 'Criterion B', 'is_ai_verified': false},
        ],
      };

      final detail = RoomDetail.fromJson(json);

      expect(detail.id, 'room-1');
      expect(detail.name, 'Backend Course 2024');
      expect(detail.description, 'Implement a REST API');
      expect(detail.language, 'Python');
      expect(detail.createdAt, '2024-01-01T10:00:00Z');
      expect(detail.participantCount, 7);
      expect(detail.creatorName, 'John Doe');
      expect(detail.criteria.length, 2);
      expect(detail.criteria[0].criterionText, 'Criterion A');
      expect(detail.criteria[0].isAiVerified, true);
      expect(detail.criteria[1].criterionText, 'Criterion B');
      expect(detail.criteria[1].isAiVerified, false);
    });

    test('creatorName is null when absent', () {
      final json = {
        'id': '1',
        'name': 'Room',
        'description': 'Desc',
        'participant_count': 0,
      };
      expect(RoomDetail.fromJson(json).creatorName, isNull);
    });

    test('description defaults to empty string when null', () {
      final json = {
        'id': '1',
        'name': 'Room',
        'description': null,
        'participant_count': 0,
      };
      expect(RoomDetail.fromJson(json).description, '');
    });

    test('language and createdAt are null when absent', () {
      final json = {
        'id': '1',
        'name': 'Room',
        'description': 'Desc',
        'participant_count': 0,
      };

      final detail = RoomDetail.fromJson(json);

      expect(detail.language, isNull);
      expect(detail.createdAt, isNull);
    });

    test('criteria defaults to empty list when null', () {
      final json = {
        'id': '1',
        'name': 'Room',
        'description': 'Desc',
        'participant_count': 0,
        'criteria': null,
      };
      expect(RoomDetail.fromJson(json).criteria, isEmpty);
    });

    test('criteria defaults to empty list when absent', () {
      final json = {
        'id': '1',
        'name': 'Room',
        'description': 'Desc',
        'participant_count': 0,
      };
      expect(RoomDetail.fromJson(json).criteria, isEmpty);
    });

    test('participant_count defaults to 0 when absent', () {
      final json = {'id': '1', 'name': 'Room', 'description': 'Desc'};
      expect(RoomDetail.fromJson(json).participantCount, 0);
    });

    test('parses empty criteria list', () {
      final json = {
        'id': '1',
        'name': 'Room',
        'description': 'Desc',
        'participant_count': 2,
        'criteria': [],
      };
      expect(RoomDetail.fromJson(json).criteria, isEmpty);
    });
  });
}
