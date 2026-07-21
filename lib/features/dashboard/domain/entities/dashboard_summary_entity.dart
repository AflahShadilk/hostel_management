import 'package:equatable/equatable.dart';

import 'dashboard_activity_entity.dart';
import 'recent_stay_item_entity.dart';

class DashboardSummaryEntity extends Equatable {
  final int totalRooms;
  final int vacantRooms;
  final int partiallyOccupiedRooms;
  final int occupiedRooms;
  final int inactiveRooms;

  final int totalBeds;
  final int vacantBeds;
  final int occupiedBeds;
  final int inactiveBeds;

  final int totalTenants;
  final int activeTenants;
  final int checkedOutTenants;

  final double pendingRent;
  final double monthlyRentCollected;
  final double monthlyExpenses;
  final int todayCheckouts;
  final List<DashboardActivityEntity> recentActivities;

  final List<RecentStayItemEntity> recentCheckIns;
  final List<RecentStayItemEntity> recentCheckOuts;

  double get occupancyPercentage {
    if (totalBeds == 0) return 0.0;
    return (occupiedBeds / totalBeds) * 100;
  }

  double get monthlyProfit => monthlyRentCollected - monthlyExpenses;

  const DashboardSummaryEntity({
    required this.totalRooms,
    required this.vacantRooms,
    required this.partiallyOccupiedRooms,
    required this.occupiedRooms,
    required this.inactiveRooms,
    required this.totalBeds,
    required this.vacantBeds,
    required this.occupiedBeds,
    required this.inactiveBeds,
    required this.totalTenants,
    required this.activeTenants,
    required this.checkedOutTenants,
    required this.pendingRent,
    required this.monthlyRentCollected,
    required this.monthlyExpenses,
    required this.todayCheckouts,
    required this.recentActivities,
    required this.recentCheckIns,
    required this.recentCheckOuts,
  });

  @override
  List<Object?> get props => [
        totalRooms,
        vacantRooms,
        partiallyOccupiedRooms,
        occupiedRooms,
        inactiveRooms,
        totalBeds,
        vacantBeds,
        occupiedBeds,
        inactiveBeds,
        totalTenants,
        activeTenants,
        checkedOutTenants,
        pendingRent,
        monthlyRentCollected,
        monthlyExpenses,
        todayCheckouts,
        recentActivities,
        recentCheckIns,
        recentCheckOuts,
      ];
}
