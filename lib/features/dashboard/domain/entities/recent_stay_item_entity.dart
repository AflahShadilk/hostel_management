import 'package:equatable/equatable.dart';

/// Represents a recent check-in or check-out item on the dashboard.
class RecentStayItemEntity extends Equatable {
  final String tenantName;
  final String roomNumber;
  final String bedNumber;
  final DateTime date;

  const RecentStayItemEntity({
    required this.tenantName,
    required this.roomNumber,
    required this.bedNumber,
    required this.date,
  });

  @override
  List<Object?> get props => [tenantName, roomNumber, bedNumber, date];
}
