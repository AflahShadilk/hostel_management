import 'package:flutter/material.dart';

import '../../../domain/entities/expense_category_entity.dart';
import 'add_expense_category_dialog.dart';

class EditExpenseCategoryDialog extends StatelessWidget {
  final ExpenseCategoryEntity category;

  const EditExpenseCategoryDialog({super.key, required this.category});

  @override
  Widget build(BuildContext context) =>
      AddExpenseCategoryDialog(category: category);
}
