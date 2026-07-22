import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/hostel_entity.dart';
import '../../domain/repositories/hostel_repository.dart';
import 'hostel_state.dart';
import 'hostel_status.dart';

class HostelCubit extends Cubit<HostelState> {
  final HostelRepository _hostelRepository;

  HostelCubit(this._hostelRepository) : super(const HostelState());

  // ---------------------------------------------------------------------------
  // Email validation helper (pure, no external dependency)
  // ---------------------------------------------------------------------------

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email);
  }

  // ---------------------------------------------------------------------------
  // Check whether the owner already has a hostel configured
  // ---------------------------------------------------------------------------

  Future<void> checkHostelSetup(int ownerUserId) async {
    if (ownerUserId <= 0) return;
    if (state.status == HostelStatus.loading ||
        state.status == HostelStatus.saving) {
      return;
    }

    emit(state.copyWith(status: HostelStatus.loading));

    try {
      final hostel =
          await _hostelRepository.getHostelByOwnerUserId(ownerUserId);

      if (hostel == null) {
        emit(state.copyWith(status: HostelStatus.notConfigured));
      } else {
        emit(state.copyWith(status: HostelStatus.configured, hostel: hostel));
      }
    } catch (_) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        errorMessage: 'Unable to load hostel information. Please try again.',
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Create a new hostel record
  // ---------------------------------------------------------------------------

  Future<void> createHostel({
    required String name,
    String? logoPath,
    required String address,
    required String phone,
    required String email,
    required String ownerName,
    required int ownerUserId,
  }) async {
    if (state.status == HostelStatus.saving ||
        state.status == HostelStatus.loading) {
      return;
    }

    // --- Validation ---
    final trimmedName = name.trim();
    final trimmedAddress = address.trim();
    final trimmedPhone = phone.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedOwnerName = ownerName.trim();

    if (trimmedName.isEmpty) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        errorMessage: 'Please enter the hostel name.',
      ));
      return;
    }
    if (trimmedAddress.isEmpty) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        errorMessage: 'Please enter the hostel address.',
      ));
      return;
    }
    if (trimmedPhone.isEmpty) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        errorMessage: 'Please enter a valid phone number.',
      ));
      return;
    }
    if (normalizedEmail.isEmpty || !_isValidEmail(normalizedEmail)) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        errorMessage: 'Please enter a valid email address.',
      ));
      return;
    }
    if (trimmedOwnerName.isEmpty) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        errorMessage: 'Please enter the owner name.',
      ));
      return;
    }
    if (ownerUserId <= 0) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        errorMessage: 'Unable to save hostel information. Please try again.',
      ));
      return;
    }

    emit(state.copyWith(status: HostelStatus.saving));

    try {
      // Explicit duplicate prevention (avoids relying on UNIQUE constraint
      // as normal control flow).
      final alreadyExists =
          await _hostelRepository.hasHostelForOwner(ownerUserId);
      if (alreadyExists) {
        // Load and surface the existing hostel rather than silently failing.
        final existing =
            await _hostelRepository.getHostelByOwnerUserId(ownerUserId);
        emit(state.copyWith(
          status: HostelStatus.configured,
          hostel: existing,
        ));
        return;
      }

      final now = DateTime.now();
      final hostelToCreate = HostelEntity(
        name: trimmedName,
        logoPath: logoPath,
        address: trimmedAddress,
        phone: trimmedPhone,
        email: normalizedEmail,
        ownerName: trimmedOwnerName,
        ownerUserId: ownerUserId,
        createdAt: now,
        updatedAt: now,
      );

      final persisted = await _hostelRepository.createHostel(hostelToCreate);
      emit(state.copyWith(status: HostelStatus.configured, hostel: persisted));
    } catch (_) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        errorMessage: 'Unable to save hostel information. Please try again.',
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Update an existing hostel record
  // ---------------------------------------------------------------------------

  Future<void> updateHostel({
    required HostelEntity hostel,
    required String name,
    String? logoPath,
    required String address,
    required String phone,
    required String email,
    required String ownerName,
  }) async {
    if (hostel.id == null) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        errorMessage: 'Unable to update hostel information. Please try again.',
      ));
      return;
    }

    if (state.status == HostelStatus.saving ||
        state.status == HostelStatus.loading) {
      return;
    }

    // --- Validation ---
    final trimmedName = name.trim();
    final trimmedAddress = address.trim();
    final trimmedPhone = phone.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedOwnerName = ownerName.trim();

    if (trimmedName.isEmpty) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        hostel: state.hostel, // Retain existing hostel
        errorMessage: 'Please enter the hostel name.',
      ));
      return;
    }
    if (trimmedAddress.isEmpty) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        hostel: state.hostel,
        errorMessage: 'Please enter the hostel address.',
      ));
      return;
    }
    if (trimmedPhone.isEmpty) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        hostel: state.hostel,
        errorMessage: 'Please enter a valid phone number.',
      ));
      return;
    }
    if (normalizedEmail.isEmpty || !_isValidEmail(normalizedEmail)) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        hostel: state.hostel,
        errorMessage: 'Please enter a valid email address.',
      ));
      return;
    }
    if (trimmedOwnerName.isEmpty) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        hostel: state.hostel,
        errorMessage: 'Please enter the owner name.',
      ));
      return;
    }

    emit(state.copyWith(status: HostelStatus.saving));

    final updatedHostel = HostelEntity(
      id: hostel.id,
      name: trimmedName,
      logoPath: logoPath,
      address: trimmedAddress,
      phone: trimmedPhone,
      email: normalizedEmail,
      ownerName: trimmedOwnerName,
      ownerUserId: hostel.ownerUserId, // preserved
      createdAt: hostel.createdAt, // preserved
      updatedAt: DateTime.now(),
    );

    try {
      await _hostelRepository.updateHostel(updatedHostel);
      emit(state.copyWith(status: HostelStatus.configured, hostel: updatedHostel));
    } catch (_) {
      emit(state.copyWith(
        status: HostelStatus.failure,
        hostel: hostel, // Retain the pre-update hostel entity
        errorMessage: 'Unable to update hostel information. Please try again.',
      ));
    }
  }
}
