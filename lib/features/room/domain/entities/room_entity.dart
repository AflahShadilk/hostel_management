import 'package:equatable/equatable.dart';
import 'room_type.dart';
import 'room_status.dart';

class RoomEntity extends Equatable {
  final int? id;
  final int hostelId;
  final String roomNumber;
  final String floor;
  final RoomType roomType;
  final int numberOfBeds;
  final double monthlyRent;
  final RoomStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoomEntity({
    this.id,
    required this.hostelId,
    required this.roomNumber,
    required this.floor,
    required this.roomType,
    required this.numberOfBeds,
    required this.monthlyRent,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        hostelId,
        roomNumber,
        floor,
        roomType,
        numberOfBeds,
        monthlyRent,
        status,
        createdAt,
        updatedAt,
      ];
}
