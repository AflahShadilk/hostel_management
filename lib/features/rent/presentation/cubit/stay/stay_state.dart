import 'package:equatable/equatable.dart';

import '../../../domain/entities/stay_entity.dart';

abstract class StayState extends Equatable {
  const StayState();
}

class StayInitial extends StayState {
  const StayInitial();

  @override
  List<Object?> get props => const [];
}

class StayLoading extends StayState {
  const StayLoading();

  @override
  List<Object?> get props => const [];
}

class StayLoaded extends StayState {
  final List<StayEntity> stays;

  const StayLoaded(this.stays);

  @override
  List<Object?> get props => [stays];
}

class StayEmpty extends StayState {
  const StayEmpty();

  @override
  List<Object?> get props => const [];
}

class StayError extends StayState {
  final String message;

  const StayError(this.message);

  @override
  List<Object?> get props => [message];
}
