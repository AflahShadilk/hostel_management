import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/entities/expense_category_entity.dart';
import '../../cubit/expense_category/expense_category_cubit.dart';
import '../../cubit/expense_category/expense_category_state.dart';
import 'add_expense_category_dialog.dart';
import 'edit_expense_category_dialog.dart';

class ExpenseCategoryListPage extends StatefulWidget {
  const ExpenseCategoryListPage({super.key});

  @override
  State<ExpenseCategoryListPage> createState() =>
      _ExpenseCategoryListPageState();
}

class _ExpenseCategoryListPageState extends State<ExpenseCategoryListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ExpenseCategoryCubit>().loadCategories();
    });
  }

  Future<void> _openDialog(Widget dialog) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ExpenseCategoryCubit>(),
        child: dialog,
      ),
    );
  }

  Future<void> _deleteCategory(ExpenseCategoryEntity category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Delete ${category.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && category.id != null && mounted) {
      context.read<ExpenseCategoryCubit>().deleteCategory(category.id!);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<ExpenseCategoryCubit, ExpenseCategoryState>(
        listener: (context, state) {
          if (state is ExpenseCategoryError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Expense Categories')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openDialog(const AddExpenseCategoryDialog()),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
          body: BlocBuilder<ExpenseCategoryCubit, ExpenseCategoryState>(
            builder: (context, state) {
              if (state is ExpenseCategoryInitial ||
                  state is ExpenseCategoryLoading) {
                return const Center(child: AppLoadingIndicator());
              }
              if (state is ExpenseCategoryEmpty) {
                return const AppEmptyState(
                    icon: Icons.category_outlined,
                    title: 'No categories found');
              }
              if (state is ExpenseCategoryLoaded) {
                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<ExpenseCategoryCubit>().loadCategories(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final categories = state.categories;
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
                        itemCount: categories.length,
                        itemBuilder: (context, index) => _CategoryCard(
                          category: categories[index],
                          onEdit: () => _openDialog(EditExpenseCategoryDialog(
                              category: categories[index])),
                          onDelete: () => _deleteCategory(categories[index]),
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

class _CategoryCard extends StatelessWidget {
  final ExpenseCategoryEntity category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard(
      {required this.category, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(category.name,
                        style: Theme.of(context).textTheme.titleMedium)),
                Chip(label: Text(category.isActive ? 'Active' : 'Inactive')),
              ]),
              if (category.description != null &&
                  category.description!.isNotEmpty)
                Expanded(
                    child: Text(category.description!,
                        overflow: TextOverflow.ellipsis, maxLines: 3))
              else
                const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit'),
                IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete'),
              ]),
            ],
          ),
        ),
      );
}
