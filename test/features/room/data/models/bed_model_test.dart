import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/room/data/models/bed_model.dart';
import 'package:hostel_management/features/room/domain/entities/bed_status.dart';

void main() {
  group('BedStatus mapping', () {
    test('valid database values map correctly', () {
      expect(BedStatus.fromDatabaseValue('vacant'), BedStatus.vacant);
      expect(BedStatus.fromDatabaseValue('occupied'), BedStatus.occupied);
      expect(BedStatus.fromDatabaseValue('inactive'), BedStatus.inactive);
    });

    test('invalid database values return null', () {
      expect(BedStatus.fromDatabaseValue('invalid'), isNull);
    });
  });

  group('BedModel', () {
    final now = DateTime.now();

    final testModel = BedModel(
      id: 1,
      roomId: 101,
      bedNumber: 'B1',
      status: BedStatus.vacant,
      createdAt: now,
      updatedAt: now,
    );

    test('toMap() converts correctly', () {
      final map = testModel.toMap();

      expect(map['id'], 1);
      expect(map['room_id'], 101);
      expect(map['bed_number'], 'B1');
      expect(map['status'], 'vacant');
      expect(map['created_at'], now.toIso8601String());
      expect(map['updated_at'], now.toIso8601String());
    });

    test('toMap() handles null id appropriately', () {
      final modelWithoutId = BedModel(
        id: null,
        roomId: 101,
        bedNumber: 'B1',
        status: BedStatus.vacant,
        createdAt: now,
        updatedAt: now,
      );

      final map = modelWithoutId.toMap();
      expect(map.containsKey('id'), isFalse);
    });

    test('fromMap() constructs correctly', () {
      final map = {
        'id': 1,
        'room_id': 101,
        'bed_number': 'B1',
        'status': 'vacant',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final result = BedModel.fromMap(map);
      expect(result, testModel);
    });

    test('fromMap() defaults to inactive status on invalid string', () {
      final map = testModel.toMap();
      map['status'] = 'invalid_status';

      final result = BedModel.fromMap(map);
      expect(result.status, BedStatus.inactive);
    });
  });
}
