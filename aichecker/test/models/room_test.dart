import 'package:flutter_test/flutter_test.dart';
import 'package:aichecker/models/room.dart';

void main() {
  group('Room.fromJson', () {
    test('parses recent-rooms API response (room_id / room_name fields)', () {
      final json = {
        'room_id': 'TQ64-E7SR-6ALG',
        'room_name': 'Test',
        'participant_count': 0,
        'submissions_count': 0,
        'final_score': 81.0,
        'last_visit': '2026-03-12T20:21:22',
      };

      final room = Room.fromJson(json);

      expect(room.id, 'TQ64-E7SR-6ALG');
      expect(room.name, 'Test');
      expect(room.participants, 0);
      expect(room.submissions, 0);
      expect(room.userScore, 81);
      expect(room.lastActive, '2026-03-12T20:21:22');
    });

    test('parses generic API response (id / name fields)', () {
      final json = {
        'id': 'abc123',
        'name': 'Test Room',
        'participant_count': 5,
        'submissions': 3,
        'user_score': 87,
        'last_active': '2024-01-01',
        'deadline': '2024-02-01',
        'is_active': true,
        'created_at': '2024-01-01T00:00:00Z',
        'description': 'Test description',
        'criteria': ['criterion1', 'criterion2'],
      };

      final room = Room.fromJson(json);

      expect(room.id, 'abc123');
      expect(room.name, 'Test Room');
      expect(room.participants, 5);
      expect(room.submissions, 3);
      expect(room.userScore, 87);
      expect(room.lastActive, '2024-01-01');
      expect(room.deadline, '2024-02-01');
      expect(room.isActive, true);
      expect(room.created, '2024-01-01T00:00:00Z');
      expect(room.description, 'Test description');
      expect(room.criteria, ['criterion1', 'criterion2']);
    });

    test('prefers room_id over id', () {
      final json = {'room_id': 'new', 'id': 'old', 'room_name': 'Room'};
      expect(Room.fromJson(json).id, 'new');
    });

    test('prefers room_name over name', () {
      final json = {'room_id': '1', 'room_name': 'New', 'name': 'Old'};
      expect(Room.fromJson(json).name, 'New');
    });

    test('rounds final_score double to int', () {
      final json = {'room_id': '1', 'room_name': 'Room', 'final_score': 81.7};
      expect(Room.fromJson(json).userScore, 82);
    });

    test('prefers final_score over user_score', () {
      final json = {
        'room_id': '1',
        'room_name': 'Room',
        'final_score': 90.0,
        'user_score': 50,
      };
      expect(Room.fromJson(json).userScore, 90);
    });

    test('prefers submissions_count over submissions', () {
      final json = {
        'room_id': '1',
        'room_name': 'Room',
        'submissions_count': 5,
        'submissions': 2,
      };
      expect(Room.fromJson(json).submissions, 5);
    });

    test('prefers last_visit over last_active', () {
      final json = {
        'room_id': '1',
        'room_name': 'Room',
        'last_visit': '2026-01-01',
        'last_active': '2025-01-01',
      };
      expect(Room.fromJson(json).lastActive, '2026-01-01');
    });

    test('prefers participant_count over participants', () {
      final json = {
        'room_id': '1',
        'room_name': 'Room',
        'participant_count': 10,
        'participants': 5,
      };
      expect(Room.fromJson(json).participants, 10);
    });

    test('defaults participants to 0 when absent', () {
      final json = {'room_id': '1', 'room_name': 'Room'};
      expect(Room.fromJson(json).participants, 0);
    });

    test('prefers created_at over created', () {
      final json = {
        'id': '1',
        'name': 'Room',
        'created_at': '2024-01-01',
        'created': '2023-01-01',
      };
      expect(Room.fromJson(json).created, '2024-01-01');
    });

    test('all optional fields are null when absent', () {
      final json = {'room_id': '1', 'room_name': 'Room'};

      final room = Room.fromJson(json);

      expect(room.submissions, isNull);
      expect(room.userScore, isNull);
      expect(room.lastActive, isNull);
      expect(room.deadline, isNull);
      expect(room.isActive, isNull);
      expect(room.created, isNull);
      expect(room.description, isNull);
      expect(room.criteria, isNull);
    });
  });

  group('Room.toJson', () {
    test('serializes all fields', () {
      final room = Room(
        id: '1',
        name: 'Test',
        participants: 3,
        description: 'Desc',
        isActive: true,
      );

      final json = room.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'Test');
      expect(json['participants'], 3);
      expect(json['description'], 'Desc');
      expect(json['is_active'], true);
    });
  });
}
