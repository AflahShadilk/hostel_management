import 'package:equatable/equatable.dart';

/// Flat, denormalized summary of a completed stay.
/// Optimized for the Tenant History list view.
class TenantHistorySummary extends Equatable {
  final int stayId;
  final int tenantId;
  final String tenantName;
  final String phoneNumber;
  final int roomId;
  final int bedId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double monthlyRentSnapshot;
  final double totalRentCharged;
  final double totalPaid;
  final double depositAmount;
  final double depositRefunded;
  final String settlementStatus;

  const TenantHistorySummary({
    required this.stayId,
    required this.tenantId,
    required this.tenantName,
    required this.phoneNumber,
    required this.roomId,
    required this.bedId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.monthlyRentSnapshot,
    required this.totalRentCharged,
    required this.totalPaid,
    required this.depositAmount,
    required this.depositRefunded,
    required this.settlementStatus,
  });

  /// The duration of the stay in days (inclusive of check-in and check-out days).
  int get totalStayDays {
    return checkOutDate.difference(checkInDate).inDays + 1;
  }

  @override
  List<Object?> get props => [
        stayId,
        tenantId,
        tenantName,
        phoneNumber,
        roomId,
        bedId,
        checkInDate,
        checkOutDate,
        monthlyRentSnapshot,
        totalRentCharged,
        totalPaid,
        depositAmount,
        depositRefunded,
        settlementStatus,
      ];
}
