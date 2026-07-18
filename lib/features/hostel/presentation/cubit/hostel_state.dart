import 'package:equatable/equatable.dart';

import '../../domain/entities/hostel_entity.dart';
import 'hostel_status.dart';

class HostelState extends Equatable {
  final HostelStatus status;
  final HostelEntity? hostel;
  final String? errorMessage;

  const HostelState({
    this.status = HostelStatus.initial,
    this.hostel,
    this.errorMessage,
  });

  HostelState copyWith({
    HostelStatus? status,
    HostelEntity? hostel,
    String? errorMessage,
  }) {
    return HostelState(
      status: status ?? this.status,
      hostel: hostel ?? this.hostel,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, hostel, errorMessage];
}
