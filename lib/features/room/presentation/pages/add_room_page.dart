import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_dropdown_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../hostel/presentation/cubit/hostel_cubit.dart';
import '../../domain/entities/room_type.dart';
import '../cubit/room_cubit.dart';
import '../cubit/room_state.dart';
import '../cubit/room_operation_status.dart';
import '../cubit/room_form_cubit.dart';
import '../cubit/room_form_state.dart';
import '../extensions/room_presentation_extensions.dart';

class AddRoomPage extends StatefulWidget {
  const AddRoomPage({super.key});

  @override
  State<AddRoomPage> createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _floorController = TextEditingController();
  final _bedsController = TextEditingController();
  final _rentController = TextEditingController();

  // Focus nodes for keyboard sequencing.
  final _floorFocus = FocusNode();
  final _bedsFocus = FocusNode();
  final _rentFocus = FocusNode();

  bool _submitted = false;

  @override
  void dispose() {
    _roomNumberController.dispose();
    _floorController.dispose();
    _bedsController.dispose();
    _rentController.dispose();
    _floorFocus.dispose();
    _bedsFocus.dispose();
    _rentFocus.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, RoomType selectedType) {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final hostelId = context.read<HostelCubit>().state.hostel?.id;
    if (hostelId == null || hostelId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load hostel information.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final beds = int.tryParse(_bedsController.text.trim()) ?? 0;
    final rent = double.tryParse(_rentController.text.trim()) ?? -1;

    context.read<RoomCubit>().createRoom(
          hostelId: hostelId,
          roomNumber: _roomNumberController.text,
          floor: _floorController.text,
          roomType: selectedType,
          numberOfBeds: beds,
          monthlyRent: rent,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoomFormCubit(),
      child: BlocListener<RoomCubit, RoomState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == RoomOperationStatus.created) {
            if (context.canPop()) context.pop(true);
          } else if (state.status == RoomOperationStatus.failure &&
              state.errorMessage != null &&
              _submitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Add Room'),
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _roomNumberController,
                          label: 'Room Number',
                          hint: 'e.g. 101, A-01, G1',
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_floorFocus),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter the room number.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _floorController,
                          label: 'Floor',
                          hint: 'e.g. Ground Floor, 1, First Floor',
                          textInputAction: TextInputAction.next,
                          focusNode: _floorFocus,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_bedsFocus),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter the floor.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Room Type dropdown — managed by RoomFormCubit.
                        BlocBuilder<RoomFormCubit, RoomFormState>(
                          builder: (context, formState) {
                            return AppDropdownField<RoomType>(
                              label: 'Room Type',
                              value: formState.selectedRoomType,
                              items: RoomType.values,
                              itemLabelBuilder: (t) => t.label,
                              onChanged: (t) {
                                if (t != null) {
                                  context
                                      .read<RoomFormCubit>()
                                      .selectRoomType(t);
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _bedsController,
                          label: 'Number of Beds',
                          hint: 'e.g. 2',
                          keyboardType: TextInputType.number,
                          focusNode: _bedsFocus,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_rentFocus),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter the number of beds.';
                            }
                            final n = int.tryParse(v.trim());
                            if (n == null || n <= 0) {
                              return 'Number of beds must be greater than 0.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'Beds B1 to BN will be created automatically.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _rentController,
                          label: 'Monthly Rent Per Bed (₹)',
                          hint: 'e.g. 5000',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          focusNode: _rentFocus,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            final formState =
                                context.read<RoomFormCubit>().state;
                            _submitted = true;
                            _submit(context, formState.selectedRoomType);
                          },
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter the monthly rent.';
                            }
                            final r = double.tryParse(v.trim());
                            if (r == null) {
                              return 'Please enter a valid rent amount.';
                            }
                            if (r < 0) {
                              return 'Monthly rent cannot be negative.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        BlocBuilder<RoomCubit, RoomState>(
                          buildWhen: (prev, curr) => prev.status != curr.status,
                          builder: (context, state) {
                            final isCreating =
                                state.status == RoomOperationStatus.creating;
                            return BlocBuilder<RoomFormCubit, RoomFormState>(
                              builder: (context, formState) {
                                return AppButton(
                                  label: 'Add Room',
                                  isLoading: isCreating,
                                  isFullWidth: true,
                                  onPressed: isCreating
                                      ? null
                                      : () {
                                          _submitted = true;
                                          _submit(context,
                                              formState.selectedRoomType);
                                        },
                                );
                              },
                            );
                          },
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
    );
  }
}
