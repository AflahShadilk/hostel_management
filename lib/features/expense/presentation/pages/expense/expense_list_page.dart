import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_safe_area_fab.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/entities/expense_category_entity.dart';
import '../../../domain/entities/expense_entity.dart';
import '../../../domain/entities/expense_query.dart';
import '../../cubit/expense/expense_cubit.dart';
import '../../cubit/expense/expense_state.dart';
import '../../cubit/expense_category/expense_category_cubit.dart';
import '../../cubit/expense_category/expense_category_state.dart';
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
      if (!mounted) return;
      context.read<ExpenseCubit>().loadExpenses();
      context.read<ExpenseCategoryCubit>().loadCategories();
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
      await context.read<ExpenseCubit>().deleteExpense(expense.id!);
    }
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (range != null && mounted) {
      await context.read<ExpenseCubit>().filterExpensesByDateRange(
            startDate: range.start,
            endDate: range.end,
          );
    }
  }

  Future<void> _openExpensePage(String routeName,
      {ExpenseEntity? expense}) async {
    await context.pushNamed(routeName, extra: expense);
    if (mounted) await context.read<ExpenseCubit>().loadExpenses();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<ExpenseCubit, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Expenses'),
            actions: [
              IconButton(
                tooltip: 'Manage categories',
                onPressed: () => context.pushNamed(
                  AppRoutes.expenseCategoryManagementName,
                ),
                icon: const Icon(Icons.category_outlined),
              ),
            ],
          ),
          floatingActionButton: AppSafeAreaFab(
            child: FloatingActionButton.extended(
              onPressed: () => _openExpensePage(AppRoutes.addExpenseName),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
          ),
          body: Column(
            children: [
              _ExpenseControls(onCustomRange: _pickCustomRange),
              Expanded(
                child: BlocBuilder<ExpenseCubit, ExpenseState>(
                  builder: (context, state) {
                    if (state is ExpenseInitial || state is ExpenseLoading) {
                      return const Center(child: AppLoadingIndicator());
                    }
                    if (state is ExpenseEmpty) {
                      return const AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No expenses found',
                      );
                    }
                    if (state is ExpenseLoaded) {
                      return BlocBuilder<ExpenseCategoryCubit,
                          ExpenseCategoryState>(
                        builder: (context, categoryState) {
                          final categories =
                              categoryState is ExpenseCategoryLoaded
                                  ? categoryState.categories
                                  : const <ExpenseCategoryEntity>[];
                          return RefreshIndicator(
                            onRefresh: () =>
                                context.read<ExpenseCubit>().loadExpenses(),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final columns = constraints.maxWidth >= 1100
                                    ? 3
                                    : constraints.maxWidth >= 700
                                        ? 2
                                        : 1;
                                return GridView.builder(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: AppSpacing.md,
                                    mainAxisSpacing: AppSpacing.md,
                                    childAspectRatio: 1.65,
                                  ),
                                  itemCount: state.expenses.length,
                                  itemBuilder: (context, index) {
                                    final expense = state.expenses[index];
                                    final categoryName = _categoryName(
                                      categories,
                                      expense.categoryId,
                                    );
                                    return _ExpenseCard(
                                      expense: expense,
                                      categoryName: categoryName ??
                                          'Category #${expense.categoryId}',
                                      date: _date,
                                      onEdit: () => _openExpensePage(
                                        AppRoutes.editExpenseName,
                                        expense: expense,
                                      ),
                                      onDelete: () => _deleteExpense(expense),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      );
  String? _categoryName(
    List<ExpenseCategoryEntity> categories,
    int categoryId,
  ) {
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return null;
  }
}

class _ExpenseControls extends StatelessWidget {
  final Future<void> Function() onCustomRange;

  const _ExpenseControls({required this.onCustomRange});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          0,
        ),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search expenses',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: context.read<ExpenseCubit>().searchExpenses,
              ),
            ),
            BlocBuilder<ExpenseCubit, ExpenseState>(
              builder: (context, state) => DropdownButton<ExpenseSort>(
                value: context.read<ExpenseCubit>().query.sort,
                hint: const Text('Sort'),
                items: const [
                  DropdownMenuItem(
                    value: ExpenseSort.newest,
                    child: Text('Newest'),
                  ),
                  DropdownMenuItem(
                    value: ExpenseSort.oldest,
                    child: Text('Oldest'),
                  ),
                  DropdownMenuItem(
                    value: ExpenseSort.highestAmount,
                    child: Text('Highest Amount'),
                  ),
                  DropdownMenuItem(
                    value: ExpenseSort.lowestAmount,
                    child: Text('Lowest Amount'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    context.read<ExpenseCubit>().sortExpenses(value);
                  }
                },
              ),
            ),
            _DateFilterButton(
              label: 'Today',
              onPressed: () {
                final today = DateTime.now();
                return context.read<ExpenseCubit>().filterExpensesByDateRange(
                      startDate: today,
                      endDate: today,
                    );
              },
            ),
            _DateFilterButton(
              label: 'This Week',
              onPressed: () {
                final now = DateTime.now();
                final start = DateTime(now.year, now.month, now.day)
                    .subtract(Duration(days: now.weekday - 1));
                return context.read<ExpenseCubit>().filterExpensesByDateRange(
                      startDate: start,
                      endDate: start.add(const Duration(days: 6)),
                    );
              },
            ),
            _DateFilterButton(
              label: 'This Month',
              onPressed: () {
                final now = DateTime.now();
                return context.read<ExpenseCubit>().filterExpensesByDateRange(
                      startDate: DateTime(now.year, now.month),
                      endDate: DateTime(now.year, now.month + 1, 0),
                    );
              },
            ),
            _DateFilterButton(label: 'Custom Range', onPressed: onCustomRange),
            TextButton(
              onPressed: () =>
                  context.read<ExpenseCubit>().filterExpensesByDateRange(),
              child: const Text('Clear dates'),
            ),
          ],
        ),
      );
}

class _DateFilterButton extends StatelessWidget {
  final String label;
  final Future<void> Function() onPressed;

  const _DateFilterButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      );
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseEntity expense;
  final String categoryName;
  final String Function(DateTime) date;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.categoryName,
    required this.date,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryName,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                expense.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Amount: ${expense.amount.toStringAsFixed(2)}'),
              Text('Date: ${date(expense.expenseDate)}'),
              Text(
                'Payment: ${expense.paymentMethod}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
