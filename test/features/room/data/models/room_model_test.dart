import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/room/data/models/room_model.dart';
import 'package:hostel_management/features/room/domain/entities/room_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_type.dart';

void main() {
  group('RoomType mapping', () {
    test('valid database values map correctly', () {
      expect(RoomType.fromDatabaseValue('single'), RoomType.single);
      expect(RoomType.fromDatabaseValue('double'), RoomType.double);
      expect(RoomType.fromDatabaseValue('triple'), RoomType.triple);
      expect(RoomType.fromDatabaseValue('dormitory'), RoomType.dormitory);
      expect(RoomType.fromDatabaseValue('other'), RoomType.other);
    });

    test('invalid database values return null', () {
      expect(RoomType.fromDatabaseValue('invalid'), isNull);
      expect(RoomType.fromDatabaseValue(''), isNull);
    });
  });

  group('RoomStatus mapping', () {
    test('valid database values map correctly', () {
      expect(RoomStatus.fromDatabaseValue('vacant'), RoomStatus.vacant);
      expect(RoomStatus.fromDatabaseValue('partially_occupied'),
          RoomStatus.partiallyOccupied);
      expect(RoomStatus.fromDatabaseValue('occupied'), RoomStatus.occupied);
      expect(RoomStatus.fromDatabaseValue('inactive'), RoomStatus.inactive);
    });

    test('invalid database values return null', () {
      expect(RoomStatus.fromDatabaseValue('invalid'), isNull);
    });
  });

  group('RoomModel', () {
    final now = DateTime.now();

    final testModel = RoomModel(
      id: 1,
      hostelId: 10,
      roomNumber: '101',
      floor: 'Ground',
      roomType: RoomType.double,
      numberOfBeds: 2,
      monthlyRent: 500.0,
      status: RoomStatus.vacant,
      createdAt: now,
      updatedAt: now,
    );

    test('toMap() converts correctly', () {
      final map = testModel.toMap();

      expect(map['id'], 1);
      expect(map['hostel_id'], 10);
      expect(map['room_number'], '101');
      expect(map['floor'], 'Ground');
      expect(map['room_type'], 'double');
      expect(map['number_of_beds'], 2);
      expect(map['monthly_rent'], 500.0);
      expect(map['status'], 'vacant');
      expect(map['created_at'], now.toIso8601String());
      expect(map['updated_at'], now.toIso8601String());
    });

    test('toMap() handles null id appropriately', () {
      final modelWithoutId = RoomModel(
        id: null,
        hostelId: 10,
        roomNumber: '101',
        floor: 'Ground',
        roomType: RoomType.double,
        numberOfBeds: 2,
        monthlyRent: 500.0,
        status: RoomStatus.vacant,
        createdAt: now,
        updatedAt: now,
      );

      final map = modelWithoutId.toMap();
      expect(map.containsKey('id'), isFalse);
    });

    test('fromMap() constructs correctly with double rent', () {
      final map = {
        'id': 1,
        'hostel_id': 10,
        'room_number': '101',
        'floor': 'Ground',
        'room_type': 'double',
        'number_of_beds': 2,
        'monthly_rent': 500.0,
        'status': 'vacant',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final result = RoomModel.fromMap(map);
      expect(result, testModel);
    });

    test('fromMap() constructs correctly with int rent', () {
      final map = {
        'id': 1,
        'hostel_id': 10,
        'room_number': '101',
        'floor': 'Ground',
        'room_type': 'double',
        'number_of_beds': 2,
        'monthly_rent': 500, // as integer from SQLite
        'status': 'vacant',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final result = RoomModel.fromMap(map);
      expect(result.monthlyRent, 500.0);
      expect(result, testModel);
    });

    test('fromMap() defaults to inactive status on invalid status', () {
      final map = testModel.toMap();
      map['status'] = 'invalid_status';

      final result = RoomModel.fromMap(map);
      expect(result.status, RoomStatus.inactive);
    });

    test('fromMap() defaults to other type on invalid type', () {
      final map = testModel.toMap();
      map['room_type'] = 'invalid_type';

      final result = RoomModel.fromMap(map);
      expect(result.roomType, RoomType.other);
    });
  });
}
