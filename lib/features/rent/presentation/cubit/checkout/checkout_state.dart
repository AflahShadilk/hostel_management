import 'package:equatable/equatable.dart';

import '../../../domain/entities/checkout_settlement_entity.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();

  @override
  List<Object?> get props => const [];
}

class CheckoutLoading extends CheckoutState {
  const CheckoutLoading();

  @override
  List<Object?> get props => const [];
}

class CheckoutLoaded extends CheckoutState {
  final List<CheckoutSettlementEntity> settlements;

  const CheckoutLoaded(this.settlements);

  @override
  List<Object?> get props => [settlements];
}

class CheckoutEmpty extends CheckoutState {
  const CheckoutEmpty();

  @override
  List<Object?> get props => const [];
}

class CheckoutError extends CheckoutState {
  final String message;

  const CheckoutError(this.message);

  @override
  List<Object?> get props => [message];
}
