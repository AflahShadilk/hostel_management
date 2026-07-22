import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/communication_repository.dart';
import 'communication_state.dart';

/// Mediates all communication actions for a single Active Stay Details screen.
///
/// Widgets dispatch high-level intents (callTenant, whatsAppRelative, etc.)
/// and observe the emitted [CommunicationState] to render per-button feedback.
///
/// Architecture:
///   Widget → [CommunicationCubit] → [CommunicationRepository] → CommunicationService → platform
///
/// The cubit is responsible for:
///   • Translating a phone-number string into a platform action.
///   • Guarding against missing / empty / null phone numbers before
///     reaching the repository.
///   • Emitting [CommunicationFailure] for every error scenario so widgets
///     never crash.
///   • Auto-resetting to [CommunicationInitial] after a success emission,
///     so the UI does not need to manage that transition.
class CommunicationCubit extends Cubit<CommunicationState> {
  CommunicationCubit(this._repository) : super(const CommunicationInitial());

  final CommunicationRepository _repository;

  // ---------------------------------------------------------------------------
  // Tenant
  // ---------------------------------------------------------------------------

  /// Opens the phone dialler pre-filled with [tenantPhone].
  Future<void> callTenant(String? tenantPhone) => _dispatch(
        actor: CommunicationActor.tenant,
        action: CommunicationAction.call,
        phone: tenantPhone,
        launch: (phone) => _repository.makePhoneCall(phone),
        missingMessage: 'Tenant does not have a phone number on record.',
      );

  /// Opens WhatsApp addressed to [tenantPhone].
  Future<void> whatsAppTenant(String? tenantPhone) => _dispatch(
        actor: CommunicationActor.tenant,
        action: CommunicationAction.whatsApp,
        phone: tenantPhone,
        launch: (phone) => _repository.openWhatsAppChat(phone),
        missingMessage: 'Tenant does not have a phone number on record.',
      );

  // ---------------------------------------------------------------------------
  // Relative / Emergency contact
  // ---------------------------------------------------------------------------

  /// Opens the phone dialler pre-filled with [relativePhone].
  Future<void> callRelative(String? relativePhone) => _dispatch(
        actor: CommunicationActor.relative,
        action: CommunicationAction.call,
        phone: relativePhone,
        launch: (phone) => _repository.makePhoneCall(phone),
        missingMessage:
            'No emergency contact phone number has been recorded for this tenant.',
      );

  /// Opens WhatsApp addressed to [relativePhone].
  Future<void> whatsAppRelative(String? relativePhone) => _dispatch(
        actor: CommunicationActor.relative,
        action: CommunicationAction.whatsApp,
        phone: relativePhone,
        launch: (phone) => _repository.openWhatsAppChat(phone),
        missingMessage:
            'No emergency contact phone number has been recorded for this tenant.',
      );

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Returns the cubit to [CommunicationInitial].
  ///
  /// Call this after consuming a [CommunicationFailure] (e.g. after showing
  /// a SnackBar) so the UI is ready for the next action.
  void reset() => emit(const CommunicationInitial());

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _dispatch({
    required CommunicationActor actor,
    required CommunicationAction action,
    required String? phone,
    required Future<CommunicationResult> Function(String) launch,
    required String missingMessage,
  }) async {
    // Guard: phone absent or blank
    if (phone == null || phone.trim().isEmpty) {
      emit(CommunicationFailure(
        actor: actor,
        action: action,
        message: missingMessage,
      ));
      return;
    }

    emit(CommunicationLoading(actor: actor, action: action));

    try {
      final result = await launch(phone);
      if (result.isSuccess) {
        emit(CommunicationSuccess(actor: actor, action: action));
        // Auto-reset so buttons return to their default state.
        emit(const CommunicationInitial());
      } else {
        emit(CommunicationFailure(
          actor: actor,
          action: action,
          message: result.message ?? 'Communication action failed.',
        ));
      }
    } catch (e) {
      emit(CommunicationFailure(
        actor: actor,
        action: action,
        message: 'An unexpected error occurred. Please try again.',
      ));
    }
  }
}
