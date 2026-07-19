import 'package:equatable/equatable.dart';

import '../../../domain/entities/rent_record_entity.dart';

abstract class RentRecordState extends Equatable {
  const RentRecordState();
}

class RentRecordInitial extends RentRecordState {
  const RentRecordInitial();

  @override
  List<Object?> get props => const [];
}

class RentRecordLoading extends RentRecordState {
  const RentRecordLoading();

  @override
  List<Object?> get props => const [];
}

class RentRecordLoaded extends RentRecordState {
  final List<RentRecordEntity> records;

  const RentRecordLoaded(this.records);

  @override
  List<Object?> get props => [records];
}

class RentRecordEmpty extends RentRecordState {
  const RentRecordEmpty();

  @override
  List<Object?> get props => const [];
}

class RentRecordError extends RentRecordState {
  final String message;

  const RentRecordError(this.message);

  @override
  List<Object?> get props => [message];
}
