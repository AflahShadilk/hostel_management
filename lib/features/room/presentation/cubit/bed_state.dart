import 'package:equatable/equatable.dart';
import '../../domain/entities/bed_entity.dart';
import 'bed_operation_status.dart';

class BedState extends Equatable {
  final BedOperationStatus status;
  final List<BedEntity> beds;
  final List<BedEntity> vacantBeds;
  final String? errorMessage;

  const BedState({
    this.status = BedOperationStatus.initial,
    this.beds = const [],
    this.vacantBeds = const [],
    this.errorMessage,
  });

  BedState copyWith({
    BedOperationStatus? status,
    List<BedEntity>? beds,
    List<BedEntity>? vacantBeds,
    String? Function()? errorMessage,
  }) {
    return BedState(
      status: status ?? this.status,
      beds: beds ?? this.beds,
      vacantBeds: vacantBeds ?? this.vacantBeds,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, beds, vacantBeds, errorMessage];
}
