import 'package:equatable/equatable.dart';

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
      ];
}
