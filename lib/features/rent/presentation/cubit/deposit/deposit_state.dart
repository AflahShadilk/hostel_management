import 'package:equatable/equatable.dart';

import '../../../domain/entities/deposit_entity.dart';

abstract class DepositState extends Equatable {
  const DepositState();
}

class DepositInitial extends DepositState {
  const DepositInitial();

  @override
  List<Object?> get props => const [];
}

class DepositLoading extends DepositState {
  const DepositLoading();

  @override
  List<Object?> get props => const [];
}

class DepositLoaded extends DepositState {
  final List<DepositEntity> deposits;

  const DepositLoaded(this.deposits);

  @override
  List<Object?> get props => [deposits];
}

class DepositEmpty extends DepositState {
  const DepositEmpty();

  @override
  List<Object?> get props => const [];
}

class DepositError extends DepositState {
  final String message;

  const DepositError(this.message);

  @override
  List<Object?> get props => [message];
}
