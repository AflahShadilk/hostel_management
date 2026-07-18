import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/hostel/data/models/hostel_model.dart';
import 'package:hostel_management/features/hostel/domain/entities/hostel_entity.dart';

void main() {
  final fixedNow = DateTime(2024, 6, 15, 10, 30);
  final fixedUpdated = DateTime(2024, 6, 16, 12, 0);

  HostelEntity makeEntity({String? logoPath}) => HostelEntity(
        id: 1,
        name: 'Sunrise Hostel',
        logoPath: logoPath,
        address: '42 Baker Street',
        phone: '9876543210',
        email: 'info@sunrise.com',
        ownerName: 'Alice',
        ownerUserId: 7,
        createdAt: fixedNow,
        updatedAt: fixedUpdated,
      );

  group('HostelModel.toMap', () {
    test('converts all fields correctly', () {
      final entity = makeEntity(logoPath: '/path/to/logo.png');
      final map = HostelModel.toMap(entity);

      expect(map['id'], 1);
      expect(map['name'], 'Sunrise Hostel');
      expect(map['logo_path'], '/path/to/logo.png');
      expect(map['address'], '42 Baker Street');
      expect(map['phone'], '9876543210');
      expect(map['email'], 'info@sunrise.com');
      expect(map['owner_name'], 'Alice');
      expect(map['owner_user_id'], 7);
      expect(map['created_at'], fixedNow.toIso8601String());
      expect(map['updated_at'], fixedUpdated.toIso8601String());
    });

    test('excludes id when null', () {
      final entity = HostelEntity(
        name: 'New Hostel',
        address: 'Addr',
        phone: '123',
        email: 'a@b.com',
        ownerName: 'Bob',
        ownerUserId: 3,
        createdAt: fixedNow,
        updatedAt: fixedNow,
      );
      final map = HostelModel.toMap(entity);
      expect(map.containsKey('id'), isFalse);
    });

    test('null logoPath is preserved in map', () {
      final entity = makeEntity();
      final map = HostelModel.toMap(entity);
      expect(map['logo_path'], isNull);
    });
  });

  group('HostelModel.fromMap', () {
    test('converts all fields correctly', () {
      final map = {
        'id': 1,
        'name': 'Sunrise Hostel',
        'logo_path': '/path/to/logo.png',
        'address': '42 Baker Street',
        'phone': '9876543210',
        'email': 'info@sunrise.com',
        'owner_name': 'Alice',
        'owner_user_id': 7,
        'created_at': fixedNow.toIso8601String(),
        'updated_at': fixedUpdated.toIso8601String(),
      };

      final entity = HostelModel.fromMap(map);

      expect(entity.id, 1);
      expect(entity.name, 'Sunrise Hostel');
      expect(entity.logoPath, '/path/to/logo.png');
      expect(entity.address, '42 Baker Street');
      expect(entity.phone, '9876543210');
      expect(entity.email, 'info@sunrise.com');
      expect(entity.ownerName, 'Alice');
      expect(entity.ownerUserId, 7);
      expect(entity.createdAt, fixedNow);
      expect(entity.updatedAt, fixedUpdated);
    });

    test('null logo_path parsed as null', () {
      final map = {
        'id': 2,
        'name': 'Basic Hostel',
        'logo_path': null,
        'address': 'Addr',
        'phone': '000',
        'email': 'x@y.com',
        'owner_name': 'Owner',
        'owner_user_id': 1,
        'created_at': fixedNow.toIso8601String(),
        'updated_at': fixedNow.toIso8601String(),
      };

      final entity = HostelModel.fromMap(map);
      expect(entity.logoPath, isNull);
    });

    test('roundtrip toMap → fromMap preserves all fields', () {
      final original = makeEntity(logoPath: '/img.png');
      final entity = HostelModel.fromMap(HostelModel.toMap(original));

      expect(entity.id, original.id);
      expect(entity.name, original.name);
      expect(entity.logoPath, original.logoPath);
      expect(entity.address, original.address);
      expect(entity.phone, original.phone);
      expect(entity.email, original.email);
      expect(entity.ownerName, original.ownerName);
      expect(entity.ownerUserId, original.ownerUserId);
      expect(entity.createdAt, original.createdAt);
      expect(entity.updatedAt, original.updatedAt);
    });
  });
}
