import '../../domain/entities/hostel_entity.dart';

/// Pure data-mapping helper between [HostelEntity] and SQLite row maps.
/// Contains no business logic.
class HostelModel {
  const HostelModel._();

  static HostelEntity fromMap(Map<String, dynamic> map) {
    return HostelEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      logoPath: map['logo_path'] as String?,
      address: map['address'] as String,
      phone: map['phone'] as String,
      email: (map['email'] as String).isEmpty ? null : map['email'] as String,
      ownerName: map['owner_name'] as String,
      gstNumber: map['gst_number'] as String?,
      website: map['website'] as String?,
      ownerUserId: map['owner_user_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(HostelEntity entity) {
    return {
      if (entity.id != null) 'id': entity.id,
      'name': entity.name,
      'logo_path': entity.logoPath,
      'address': entity.address,
      'phone': entity.phone,
      'email': entity.email ?? '',
      'owner_name': entity.ownerName,
      'gst_number': entity.gstNumber,
      'website': entity.website,
      'owner_user_id': entity.ownerUserId,
      'created_at': entity.createdAt.toIso8601String(),
      'updated_at': entity.updatedAt.toIso8601String(),
    };
  }
}
