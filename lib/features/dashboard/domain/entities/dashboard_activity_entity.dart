import 'package:equatable/equatable.dart';

enum DashboardActivityType {
  tenantCheckIn,
  tenantCheckOut,
  rentCollected,
  roomAdded,
  expenseAdded,
  other,
}

class DashboardActivityEntity extends Equatable {
  final String title;
  final String subtitle;
  final DateTime time;
  final DashboardActivityType type;

  const DashboardActivityEntity({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
  });

  @override
  List<Object?> get props => [title, subtitle, time, type];
}
