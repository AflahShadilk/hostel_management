import 'package:equatable/equatable.dart';

import '../../../domain/entities/payment_entity.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();

  @override
  List<Object?> get props => const [];
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();

  @override
  List<Object?> get props => const [];
}

class PaymentLoaded extends PaymentState {
  final List<PaymentEntity> payments;

  const PaymentLoaded(this.payments);

  @override
  List<Object?> get props => [payments];
}

class PaymentEmpty extends PaymentState {
  const PaymentEmpty();

  @override
  List<Object?> get props => const [];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}
