import 'package:equatable/equatable.dart';

class StayEntity extends Equatable {
  final int? id;
  final int tenantId;
  final int roomId;
  final int bedId;
  final DateTime checkInDate;
  final DateTime? checkOutDate;
  final DateTime? expectedCheckoutDate;
  final double monthlyRentSnapshot;
  final double dailyRate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StayEntity({
    this.id,
    required this.tenantId,
    required this.roomId,
    required this.bedId,
    required this.checkInDate,
    this.checkOutDate,
    this.expectedCheckoutDate,
    required this.monthlyRentSnapshot,
    required this.dailyRate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        tenantId,
        roomId,
        bedId,
        checkInDate,
        checkOutDate,
        expectedCheckoutDate,
        monthlyRentSnapshot,
        dailyRate,
        status,
        createdAt,
        updatedAt,
      ];
}
