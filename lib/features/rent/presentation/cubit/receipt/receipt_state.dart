import 'package:equatable/equatable.dart';

import '../../../domain/entities/receipt_entity.dart';

abstract class ReceiptState extends Equatable {
  const ReceiptState();
}

class ReceiptInitial extends ReceiptState {
  const ReceiptInitial();

  @override
  List<Object?> get props => const [];
}

class ReceiptLoading extends ReceiptState {
  const ReceiptLoading();

  @override
  List<Object?> get props => const [];
}

class ReceiptLoaded extends ReceiptState {
  final List<ReceiptEntity> receipts;

  const ReceiptLoaded(this.receipts);

  @override
  List<Object?> get props => [receipts];
}

class ReceiptEmpty extends ReceiptState {
  const ReceiptEmpty();

  @override
  List<Object?> get props => const [];
}

class ReceiptError extends ReceiptState {
  final String message;

  const ReceiptError(this.message);

  @override
  List<Object?> get props => [message];
}
