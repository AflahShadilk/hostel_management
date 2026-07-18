import 'package:equatable/equatable.dart';

class HostelEntity extends Equatable {
  final int? id;
  final String name;
  final String? logoPath;
  final String address;
  final String phone;
  final String email;
  final String ownerName;
  final int ownerUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HostelEntity({
    this.id,
    required this.name,
    this.logoPath,
    required this.address,
    required this.phone,
    required this.email,
    required this.ownerName,
    required this.ownerUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        logoPath,
        address,
        phone,
        email,
        ownerName,
        ownerUserId,
        createdAt,
        updatedAt,
      ];
}
