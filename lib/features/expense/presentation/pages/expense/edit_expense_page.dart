import 'package:flutter/material.dart';

import '../../../domain/entities/expense_entity.dart';
import 'add_expense_page.dart';

class EditExpensePage extends StatelessWidget {
  final ExpenseEntity expense;

  const EditExpensePage({super.key, required this.expense});

  @override
  Widget build(BuildContext context) => AddExpensePage(expense: expense);
}
