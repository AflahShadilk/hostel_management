import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/tenant/data/models/tenant_model.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_status.dart';

void main() {
  final now = DateTime(2024, 6, 1, 12);
  final later = DateTime(2024, 8, 1, 12);

  TenantModel buildModel({
    int? id = 1,
    int bedId = 10,
    String fullName = 'Alice Smith',
    String phoneNumber = '9876543210',
    String? email = 'alice@example.com',
    String? address = '123 Main St',
    DateTime? checkInDate,
    DateTime? checkOutDate,
    String? emergencyContactName = 'Bob Smith',
    String? emergencyContactPhone = '1234567890',
    TenantStatus status = TenantStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TenantModel(
      id: id,
      bedId: bedId,
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      address: address,
      checkInDate: checkInDate ?? now,
      checkOutDate: checkOutDate,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      status: status,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  // ---------------------------------------------------------------------------
  // TenantStatus
  // ---------------------------------------------------------------------------
  group('TenantStatus', () {
    test('fromDatabaseValue maps known values correctly', () {
      expect(TenantStatus.fromDatabaseValue('active'), TenantStatus.active);
      expect(
        TenantStatus.fromDatabaseValue('checked_out'),
        TenantStatus.checkedOut,
      );
      expect(
        TenantStatus.fromDatabaseValue('inactive'),
        TenantStatus.inactive,
      );
    });

    test('fromDatabaseValue returns null for unknown values', () {
      expect(TenantStatus.fromDatabaseValue('unknown'), isNull);
      expect(TenantStatus.fromDatabaseValue(''), isNull);
    });

    test('databaseValue matches expected strings', () {
      expect(TenantStatus.active.databaseValue, 'active');
      expect(TenantStatus.checkedOut.databaseValue, 'checked_out');
      expect(TenantStatus.inactive.databaseValue, 'inactive');
    });
  });

  // ---------------------------------------------------------------------------
  // TenantModel.fromMap
  // ---------------------------------------------------------------------------
  group('TenantModel.fromMap', () {
    test('deserializes all fields correctly', () {
      final map = {
        'id': 1,
        'bed_id': 10,
        'full_name': 'Alice Smith',
        'phone_number': '9876543210',
        'email': 'alice@example.com',
        'address': '123 Main St',
        'check_in_date': now.toIso8601String(),
        'check_out_date': later.toIso8601String(),
        'emergency_contact_name': 'Bob Smith',
        'emergency_contact_phone': '1234567890',
        'status': 'active',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final model = TenantModel.fromMap(map);

      expect(model.id, 1);
      expect(model.bedId, 10);
      expect(model.fullName, 'Alice Smith');
      expect(model.phoneNumber, '9876543210');
      expect(model.email, 'alice@example.com');
      expect(model.address, '123 Main St');
      expect(model.checkInDate, now);
      expect(model.checkOutDate, later);
      expect(model.emergencyContactName, 'Bob Smith');
      expect(model.emergencyContactPhone, '1234567890');
      expect(model.status, TenantStatus.active);
      expect(model.createdAt, now);
      expect(model.updatedAt, now);
    });

    test('handles null optional fields', () {
      final map = {
        'id': null,
        'bed_id': 5,
        'full_name': 'Charlie',
        'phone_number': '555',
        'email': null,
        'address': null,
        'check_in_date': now.toIso8601String(),
        'check_out_date': null,
        'emergency_contact_name': null,
        'emergency_contact_phone': null,
        'status': 'inactive',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final model = TenantModel.fromMap(map);

      expect(model.id, isNull);
      expect(model.email, isNull);
      expect(model.address, isNull);
      expect(model.checkOutDate, isNull);
      expect(model.emergencyContactName, isNull);
      expect(model.emergencyContactPhone, isNull);
      expect(model.status, TenantStatus.inactive);
    });

    test('defaults to inactive on unrecognised status value', () {
      final map = {
        'id': 1,
        'bed_id': 5,
        'full_name': 'X',
        'phone_number': '000',
        'email': null,
        'address': null,
        'check_in_date': now.toIso8601String(),
        'check_out_date': null,
        'emergency_contact_name': null,
        'emergency_contact_phone': null,
        'status': 'unknown_status',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final model = TenantModel.fromMap(map);
      expect(model.status, TenantStatus.inactive);
    });
  });

  // ---------------------------------------------------------------------------
  // TenantModel.toMap
  // ---------------------------------------------------------------------------
  group('TenantModel.toMap', () {
    test('serializes all fields correctly', () {
      final model = buildModel(checkOutDate: later);
      final map = model.toMap();

      expect(map['id'], 1);
      expect(map['bed_id'], 10);
      expect(map['full_name'], 'Alice Smith');
      expect(map['phone_number'], '9876543210');
      expect(map['email'], 'alice@example.com');
      expect(map['address'], '123 Main St');
      expect(map['check_in_date'], now.toIso8601String());
      expect(map['check_out_date'], later.toIso8601String());
      expect(map['emergency_contact_name'], 'Bob Smith');
      expect(map['emergency_contact_phone'], '1234567890');
      expect(map['status'], 'active');
      expect(map['created_at'], now.toIso8601String());
      expect(map['updated_at'], now.toIso8601String());
    });

    test('omits id key when id is null', () {
      final model = buildModel(id: null);
      final map = model.toMap();
      expect(map.containsKey('id'), isFalse);
    });

    test('includes null for optional nullable fields', () {
      final model = buildModel(email: null, address: null, checkOutDate: null);
      final map = model.toMap();
      expect(map['email'], isNull);
      expect(map['address'], isNull);
      expect(map['check_out_date'], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // TenantModel.fromEntity
  // ---------------------------------------------------------------------------
  group('TenantModel.fromEntity', () {
    test('converts entity to model preserving all fields', () {
      final entity = buildModel();
      final model = TenantModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.bedId, entity.bedId);
      expect(model.fullName, entity.fullName);
      expect(model.phoneNumber, entity.phoneNumber);
      expect(model.email, entity.email);
      expect(model.status, entity.status);
    });
  });

  // ---------------------------------------------------------------------------
  // TenantModel.copyWith
  // ---------------------------------------------------------------------------
  group('TenantModel.copyWith', () {
    test('returns a copy with updated fields', () {
      final original = buildModel();
      final updated = original.copyWith(
        fullName: 'Bob Jones',
        status: TenantStatus.checkedOut,
        checkOutDate: later,
      );

      expect(updated.fullName, 'Bob Jones');
      expect(updated.status, TenantStatus.checkedOut);
      expect(updated.checkOutDate, later);

      // Unchanged fields are preserved.
      expect(updated.id, original.id);
      expect(updated.bedId, original.bedId);
      expect(updated.phoneNumber, original.phoneNumber);
      expect(updated.email, original.email);
    });

    test('copyWith can explicitly set nullable fields to null', () {
      final original = buildModel(email: 'test@test.com', checkOutDate: later);
      final updated = original.copyWith(email: null, checkOutDate: null);

      expect(updated.email, isNull);
      expect(updated.checkOutDate, isNull);
    });

    test('copyWith can clear the bed after checkout', () {
      final updated = buildModel().copyWith(bedId: null);

      expect(updated.bedId, isNull);
    });

    test('copyWith without arguments returns an equal copy', () {
      final original = buildModel();
      final copy = original.copyWith();
      expect(copy, original);
    });
  });

  // ---------------------------------------------------------------------------
  // TenantEntity equality (Equatable)
  // ---------------------------------------------------------------------------
  group('TenantEntity equality', () {
    test('two identical models are equal', () {
      final a = buildModel();
      final b = buildModel();
      expect(a, b);
    });

    test('models with different phone numbers are not equal', () {
      final a = buildModel(phoneNumber: '111');
      final b = buildModel(phoneNumber: '222');
      expect(a, isNot(b));
    });
  });
}
