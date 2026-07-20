import 'package:equatable/equatable.dart';

import '../../../domain/entities/expense_category_entity.dart';

abstract class ExpenseCategoryState extends Equatable {
  const ExpenseCategoryState();
}

class ExpenseCategoryInitial extends ExpenseCategoryState {
  const ExpenseCategoryInitial();

  @override
  List<Object?> get props => const [];
}

class ExpenseCategoryLoading extends ExpenseCategoryState {
  const ExpenseCategoryLoading();

  @override
  List<Object?> get props => const [];
}

class ExpenseCategoryLoaded extends ExpenseCategoryState {
  final List<ExpenseCategoryEntity> categories;

  const ExpenseCategoryLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class ExpenseCategoryEmpty extends ExpenseCategoryState {
  const ExpenseCategoryEmpty();

  @override
  List<Object?> get props => const [];
}

class ExpenseCategoryError extends ExpenseCategoryState {
  final String message;

  const ExpenseCategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
