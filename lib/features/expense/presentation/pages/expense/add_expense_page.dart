import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/expense_entity.dart';
import '../../../domain/entities/expense_category_entity.dart';
import '../../cubit/expense/expense_cubit.dart';
import '../../cubit/expense/expense_state.dart';
import '../../cubit/expense_category/expense_category_cubit.dart';
import '../../cubit/expense_category/expense_category_state.dart';
import '../../../../rent/presentation/cubit/ui/selected_date_cubit.dart';
import '../../../../rent/presentation/cubit/ui/selected_status_cubit.dart';
import '../../../../rent/presentation/cubit/ui/submitting_cubit.dart';

class AddExpensePage extends StatefulWidget {
  final ExpenseEntity? expense;

  const AddExpensePage({super.key, this.expense});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _paymentMethodController;
  late final TextEditingController _referenceNumberController;
  late final TextEditingController _vendorNameController;
  late final TextEditingController _notesController;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _titleController = TextEditingController(text: expense?.title ?? '');
    _descriptionController =
        TextEditingController(text: expense?.description ?? '');
    _amountController =
        TextEditingController(text: expense?.amount.toString() ?? '');
    _paymentMethodController =
        TextEditingController(text: expense?.paymentMethod ?? '');
    _referenceNumberController =
        TextEditingController(text: expense?.referenceNumber ?? '');
    _vendorNameController =
        TextEditingController(text: expense?.vendorName ?? '');
    _notesController = TextEditingController(text: expense?.notes ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ExpenseCategoryCubit>().loadCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _paymentMethodController.dispose();
    _referenceNumberController.dispose();
    _vendorNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _pickDate(BuildContext context) async {
    final selectedDate = context.read<SelectedDateCubit>();
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate.state ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) selectedDate.pick(date);
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final categoryId = int.tryParse(context.read<SelectedStatusCubit>().state);
    if (categoryId == null) return;
    final now = DateTime.now();
    final expense = ExpenseEntity(
      id: widget.expense?.id,
      categoryId: categoryId,
      title: _titleController.text.trim(),
      description: _nullable(_descriptionController.text),
      amount: double.parse(_amountController.text.trim()),
      expenseDate: context.read<SelectedDateCubit>().state ?? DateTime.now(),
      paymentMethod: _paymentMethodController.text.trim(),
      referenceNumber: _nullable(_referenceNumberController.text),
      vendorName: _nullable(_vendorNameController.text),
      notes: _nullable(_notesController.text),
      createdAt: widget.expense?.createdAt ?? now,
      updatedAt: now,
    );
    context.read<SubmittingCubit>().start();
    if (_isEditing) {
      context.read<ExpenseCubit>().updateExpense(expense);
    } else {
      context.read<ExpenseCubit>().createExpense(expense);
    }
  }

  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    return MultiBlocProvider(
      providers: [
        BlocProvider<SubmittingCubit>(create: (_) => SubmittingCubit()),
        BlocProvider<SelectedDateCubit>(
          create: (_) =>
              SelectedDateCubit(expense?.expenseDate ?? DateTime.now()),
        ),
        BlocProvider<SelectedStatusCubit>(
          create: (_) =>
              SelectedStatusCubit(expense?.categoryId.toString() ?? ''),
        ),
      ],
      child: Builder(
        builder: (context) => BlocListener<ExpenseCubit, ExpenseState>(
          listener: (context, state) {
            if (!context.read<SubmittingCubit>().state) return;
            if (state is ExpenseLoaded || state is ExpenseEmpty) {
              Navigator.of(context).pop(true);
            } else if (state is ExpenseError) {
              context.read<SubmittingCubit>().stop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: Scaffold(
            appBar: AppBar(
                title: Text(_isEditing ? 'Edit Expense' : 'Add Expense')),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xl +
                          MediaQuery.viewPaddingOf(context).bottom +
                          80,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BlocBuilder<ExpenseCategoryCubit,
                              ExpenseCategoryState>(
                            builder: (context, state) {
                              final categories = state is ExpenseCategoryLoaded
                                  ? state.categories
                                  : const <ExpenseCategoryEntity>[];
                              return BlocBuilder<SelectedStatusCubit, String>(
                                builder: (context, categoryId) =>
                                    DropdownButtonFormField<String>(
                                  value: categoryId.isEmpty ? null : categoryId,
                                  decoration: const InputDecoration(
                                      labelText: 'Category'),
                                  items: categories
                                      .where((category) => category.id != null)
                                      .map((category) => DropdownMenuItem(
                                            value: category.id.toString(),
                                            child: Text(category.name),
                                          ))
                                      .toList(),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Category is required.'
                                          : null,
                                  onChanged: (value) {
                                    if (value != null) {
                                      context
                                          .read<SelectedStatusCubit>()
                                          .select(value);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _titleController,
                            label: 'Title',
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Title is required.'
                                    : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _descriptionController,
                              label: 'Description',
                              maxLines: 3),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _amountController,
                            label: 'Amount',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'))
                            ],
                            validator: (value) {
                              final amount =
                                  double.tryParse(value?.trim() ?? '');
                              return amount == null || amount <= 0
                                  ? 'Amount must be greater than zero.'
                                  : null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          BlocBuilder<SelectedDateCubit, DateTime?>(
                            builder: (context, date) => InkWell(
                              onTap: () => _pickDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Expense Date',
                                  suffixIcon:
                                      Icon(Icons.calendar_today_outlined),
                                ),
                                child: Text(_date(date ?? DateTime.now())),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _paymentMethodController,
                            label: 'Payment Method',
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Payment method is required.'
                                    : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _referenceNumberController,
                              label: 'Reference Number'),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _vendorNameController,
                              label: 'Vendor Name'),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                              controller: _notesController,
                              label: 'Notes',
                              maxLines: 3),
                          const SizedBox(height: AppSpacing.xl),
                          BlocBuilder<SubmittingCubit, bool>(
                            builder: (context, submitting) => AppButton(
                              label:
                                  _isEditing ? 'Save Changes' : 'Add Expense',
                              isLoading: submitting,
                              isFullWidth: true,
                              onPressed:
                                  submitting ? null : () => _submit(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
