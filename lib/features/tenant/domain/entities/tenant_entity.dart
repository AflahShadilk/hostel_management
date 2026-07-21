import 'package:equatable/equatable.dart';
import 'tenant_status.dart';

/// Immutable domain entity representing a hostel tenant.
///
/// A Tenant belongs to a Bed (which belongs to a Room, which belongs to a
/// Hostel). The [bedId] foreign-key establishes this chain without storing
/// redundant hostel or room IDs on the tenant itself.
class TenantEntity extends Equatable {
  final int? id;
  final int? bedId;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? address;
  final DateTime checkInDate;
  final DateTime? checkOutDate;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? idType;
  final String? idDocumentPath;
  final TenantStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TenantEntity({
    this.id,
    this.bedId,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.address,
    required this.checkInDate,
    this.checkOutDate,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.idType,
    this.idDocumentPath,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        bedId,
        fullName,
        phoneNumber,
        email,
        address,
        checkInDate,
        checkOutDate,
        emergencyContactName,
        emergencyContactPhone,
        idType,
        idDocumentPath,
        status,
        createdAt,
        updatedAt,
      ];
}
