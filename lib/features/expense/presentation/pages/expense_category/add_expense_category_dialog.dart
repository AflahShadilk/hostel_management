import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/expense_category_entity.dart';
import '../../cubit/expense_category/expense_category_cubit.dart';
import '../../cubit/expense_category/expense_category_state.dart';
import '../../../../rent/presentation/cubit/ui/submitting_cubit.dart';

class AddExpenseCategoryDialog extends StatefulWidget {
  final ExpenseCategoryEntity? category;

  const AddExpenseCategoryDialog({super.key, this.category});

  @override
  State<AddExpenseCategoryDialog> createState() =>
      _AddExpenseCategoryDialogState();
}

class _AddExpenseCategoryDialogState extends State<AddExpenseCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _isActiveController;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _descriptionController =
        TextEditingController(text: category?.description ?? '');
    _isActiveController =
        TextEditingController(text: (category?.isActive ?? true).toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _isActiveController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final category = ExpenseCategoryEntity(
      id: widget.category?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: _isActiveController.text == 'true',
      createdAt: widget.category?.createdAt ?? now,
    );
    context.read<SubmittingCubit>().start();
    if (_isEditing) {
      context.read<ExpenseCategoryCubit>().updateCategory(category);
    } else {
      context.read<ExpenseCategoryCubit>().createCategory(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubmittingCubit>(
      create: (_) => SubmittingCubit(),
      child: Builder(
        builder: (context) => BlocListener<ExpenseCategoryCubit,
            ExpenseCategoryState>(
          listener: (context, state) {
            if (!context.read<SubmittingCubit>().state) return;
            if (state is ExpenseCategoryLoaded || state is ExpenseCategoryEmpty) {
              Navigator.of(context).pop(true);
            } else if (state is ExpenseCategoryError) {
              context.read<SubmittingCubit>().stop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: AlertDialog(
            title: Text(_isEditing ? 'Edit Category' : 'Add Category'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        controller: _nameController,
                        label: 'Name',
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Name is required.'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<bool>(
                        value: _isActiveController.text == 'true',
                        decoration: const InputDecoration(labelText: 'Active Status'),
                        items: const [
                          DropdownMenuItem(value: true, child: Text('Active')),
                          DropdownMenuItem(value: false, child: Text('Inactive')),
                        ],
                        onChanged: (value) =>
                            _isActiveController.text = (value ?? true).toString(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              BlocBuilder<SubmittingCubit, bool>(
                builder: (context, submitting) => AppButton(
                  label: _isEditing ? 'Save Changes' : 'Add Category',
                  isLoading: submitting,
                  onPressed: submitting ? null : () => _submit(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
