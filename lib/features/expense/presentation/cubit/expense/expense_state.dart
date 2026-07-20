import 'package:equatable/equatable.dart';

import '../../../domain/entities/expense_entity.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();
}

class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();

  @override
  List<Object?> get props => const [];
}

class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();

  @override
  List<Object?> get props => const [];
}

class ExpenseLoaded extends ExpenseState {
  final List<ExpenseEntity> expenses;

  const ExpenseLoaded(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

class ExpenseEmpty extends ExpenseState {
  const ExpenseEmpty();

  @override
  List<Object?> get props => const [];
}

class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}
