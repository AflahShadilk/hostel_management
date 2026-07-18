import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_dropdown_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/entities/room_type.dart';
import '../cubit/room_cubit.dart';
import '../cubit/room_state.dart';
import '../cubit/room_operation_status.dart';
import '../cubit/room_form_cubit.dart';
import '../cubit/room_form_state.dart';
import '../extensions/room_presentation_extensions.dart';

class EditRoomPage extends StatefulWidget {
  /// The Room to edit, passed via GoRouter extra.
  final RoomEntity? room;

  const EditRoomPage({super.key, this.room});

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomNumberController;
  late final TextEditingController _floorController;
  late final TextEditingController _bedsController;
  late final TextEditingController _rentController;

  final _floorFocus = FocusNode();
  final _bedsFocus = FocusNode();
  final _rentFocus = FocusNode();

  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    _roomNumberController = TextEditingController(text: room?.roomNumber ?? '');
    _floorController = TextEditingController(text: room?.floor ?? '');
    _bedsController =
        TextEditingController(text: room?.numberOfBeds.toString() ?? '');
    _rentController = TextEditingController(
      text: room != null
          ? (room.monthlyRent == room.monthlyRent.truncateToDouble()
              ? room.monthlyRent.toInt().toString()
              : room.monthlyRent.toString())
          : '',
    );
  }

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
    final room = widget.room;
    if (room == null) return;

    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final beds = int.tryParse(_bedsController.text.trim()) ?? 0;
    final rent = double.tryParse(_rentController.text.trim()) ?? -1;

    context.read<RoomCubit>().updateRoom(
          currentRoom: room,
          roomNumber: _roomNumberController.text,
          floor: _floorController.text,
          roomType: selectedType,
          numberOfBeds: beds,
          monthlyRent: rent,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Safe fallback if room is missing.
    if (widget.room == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Edit Room'),
          backgroundColor: AppColors.surface,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Room information is unavailable.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () {
                    if (context.canPop()) context.pop();
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => RoomFormCubit(initialType: widget.room!.roomType),
      child: BlocListener<RoomCubit, RoomState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == RoomOperationStatus.updated) {
            if (context.canPop()) context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Room updated successfully.')),
            );
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
            title: Text('Edit Room ${widget.room!.roomNumber}'),
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
                            'Increasing beds creates new beds automatically. '
                            'Reducing beds is allowed only when removable beds are vacant.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _rentController,
                          label: 'Monthly Rent (₹)',
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
                            final isUpdating =
                                state.status == RoomOperationStatus.updating;
                            return BlocBuilder<RoomFormCubit, RoomFormState>(
                              builder: (context, formState) {
                                return AppButton(
                                  label: 'Save Changes',
                                  isLoading: isUpdating,
                                  isFullWidth: true,
                                  onPressed: isUpdating
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
