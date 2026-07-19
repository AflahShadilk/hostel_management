import '../../domain/entities/tenant_entity.dart';
import '../../domain/entities/tenant_status.dart';
import '../datasources/tenant_local_schema.dart';

/// SQLite data model for [TenantEntity].
///
/// Extends [TenantEntity] so it can be returned directly wherever the domain
/// type is expected, removing the need for a mapping step at call sites.
class TenantModel extends TenantEntity {
  const TenantModel({
    super.id,
    super.bedId,
    required super.fullName,
    required super.phoneNumber,
    super.email,
    super.address,
    required super.checkInDate,
    super.checkOutDate,
    super.emergencyContactName,
    super.emergencyContactPhone,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  // ---------------------------------------------------------------------------
  // Factories
  // ---------------------------------------------------------------------------

  /// Converts a [TenantEntity] into a [TenantModel] (no data transformation).
  factory TenantModel.fromEntity(TenantEntity entity) {
    return TenantModel(
      id: entity.id,
      bedId: entity.bedId,
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      email: entity.email,
      address: entity.address,
      checkInDate: entity.checkInDate,
      checkOutDate: entity.checkOutDate,
      emergencyContactName: entity.emergencyContactName,
      emergencyContactPhone: entity.emergencyContactPhone,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Deserializes a SQLite row map into a [TenantModel].
  factory TenantModel.fromMap(Map<String, dynamic> map) {
    return TenantModel(
      id: map[TenantLocalSchema.colId] as int?,
      bedId: map[TenantLocalSchema.colBedId] as int?,
      fullName: map[TenantLocalSchema.colFullName] as String,
      phoneNumber: map[TenantLocalSchema.colPhoneNumber] as String,
      email: map[TenantLocalSchema.colEmail] as String?,
      address: map[TenantLocalSchema.colAddress] as String?,
      checkInDate: DateTime.parse(
        map[TenantLocalSchema.colCheckInDate] as String,
      ),
      checkOutDate: map[TenantLocalSchema.colCheckOutDate] != null
          ? DateTime.parse(map[TenantLocalSchema.colCheckOutDate] as String)
          : null,
      emergencyContactName:
          map[TenantLocalSchema.colEmergencyContactName] as String?,
      emergencyContactPhone:
          map[TenantLocalSchema.colEmergencyContactPhone] as String?,
      status: TenantStatus.fromDatabaseValue(
            map[TenantLocalSchema.colStatus] as String,
          ) ??
          TenantStatus.inactive,
      createdAt: DateTime.parse(map[TenantLocalSchema.colCreatedAt] as String),
      updatedAt: DateTime.parse(map[TenantLocalSchema.colUpdatedAt] as String),
    );
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Serializes this model to a SQLite-compatible row map.
  ///
  /// The [id] key is omitted when null so SQLite's AUTOINCREMENT can assign it.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      TenantLocalSchema.colBedId: bedId,
      TenantLocalSchema.colFullName: fullName,
      TenantLocalSchema.colPhoneNumber: phoneNumber,
      TenantLocalSchema.colEmail: email,
      TenantLocalSchema.colAddress: address,
      TenantLocalSchema.colCheckInDate: checkInDate.toIso8601String(),
      TenantLocalSchema.colCheckOutDate: checkOutDate?.toIso8601String(),
      TenantLocalSchema.colEmergencyContactName: emergencyContactName,
      TenantLocalSchema.colEmergencyContactPhone: emergencyContactPhone,
      TenantLocalSchema.colStatus: status.databaseValue,
      TenantLocalSchema.colCreatedAt: createdAt.toIso8601String(),
      TenantLocalSchema.colUpdatedAt: updatedAt.toIso8601String(),
    };
    if (id != null) {
      map[TenantLocalSchema.colId] = id;
    }
    return map;
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  TenantModel copyWith({
    int? id,
    Object? bedId = _sentinel,
    String? fullName,
    String? phoneNumber,
    Object? email = _sentinel,
    Object? address = _sentinel,
    DateTime? checkInDate,
    Object? checkOutDate = _sentinel,
    Object? emergencyContactName = _sentinel,
    Object? emergencyContactPhone = _sentinel,
    TenantStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TenantModel(
      id: id ?? this.id,
      bedId: identical(bedId, _sentinel) ? this.bedId : bedId as int?,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: identical(email, _sentinel) ? this.email : email as String?,
      address:
          identical(address, _sentinel) ? this.address : address as String?,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: identical(checkOutDate, _sentinel)
          ? this.checkOutDate
          : checkOutDate as DateTime?,
      emergencyContactName: identical(emergencyContactName, _sentinel)
          ? this.emergencyContactName
          : emergencyContactName as String?,
      emergencyContactPhone: identical(emergencyContactPhone, _sentinel)
          ? this.emergencyContactPhone
          : emergencyContactPhone as String?,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Sentinel value used by [TenantModel.copyWith] to distinguish between
/// "caller passed null" and "caller did not pass anything" for nullable fields.
const Object _sentinel = Object();
