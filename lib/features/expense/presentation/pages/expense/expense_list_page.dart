import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/entities/expense_entity.dart';
import '../../cubit/expense/expense_cubit.dart';
import '../../cubit/expense/expense_state.dart';
import 'delete_expense_dialog.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ExpenseCubit>().loadExpenses();
    });
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _deleteExpense(ExpenseEntity expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteExpenseDialog(
        title: 'Delete Expense?',
        message: 'Delete ${expense.title}?',
      ),
    );
    if (confirmed == true && expense.id != null && mounted) {
      context.read<ExpenseCubit>().deleteExpense(expense.id!);
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<ExpenseCubit, ExpenseState>(
    listener: (context, state) {
      if (state is ExpenseError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) {
          if (state is ExpenseInitial || state is ExpenseLoading) {
            return const Center(child: AppLoadingIndicator());
          }
          if (state is ExpenseEmpty) {
            return const AppEmptyState(icon: Icons.receipt_long_outlined, title: 'No expenses found');
          }
          if (state is ExpenseLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<ExpenseCubit>().loadExpenses(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1100
                      ? 3
                      : constraints.maxWidth >= 700
                          ? 2
                          : 1;
                  return GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: state.expenses.length,
                    itemBuilder: (context, index) => _ExpenseCard(
                      expense: state.expenses[index],
                      date: _date,
                      onDelete: () => _deleteExpense(state.expenses[index]),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseEntity expense;
  final String Function(DateTime) date;
  final VoidCallback onDelete;

  const _ExpenseCard({required this.expense, required this.date, required this.onDelete});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(expense.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.sm),
          Text('Amount: ${expense.amount.toStringAsFixed(2)}'),
          Text('Date: ${date(expense.expenseDate)}'),
          Text('Payment: ${expense.paymentMethod}', maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
            ),
          ),
        ],
      ),
    ),
  );
}
