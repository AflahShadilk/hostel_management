import 'package:equatable/equatable.dart';

/// Describes who initiated the action — used so the UI can show per-contact
/// feedback without needing separate cubits.
enum CommunicationActor {
  tenant,
  relative,
}

/// The kind of action that was attempted.
enum CommunicationAction {
  call,
  whatsApp,
}

/// Sealed base for all [CommunicationCubit] states.
abstract class CommunicationState extends Equatable {
  const CommunicationState();
}

/// No action has been dispatched yet (or the cubit has been reset).
class CommunicationInitial extends CommunicationState {
  const CommunicationInitial();

  @override
  List<Object?> get props => const [];
}

/// A communication action is currently in progress.
///
/// [actor] and [action] let the UI show a spinner on the specific button
/// rather than disabling the whole screen.
class CommunicationLoading extends CommunicationState {
  const CommunicationLoading({required this.actor, required this.action});

  final CommunicationActor actor;
  final CommunicationAction action;

  @override
  List<Object?> get props => [actor, action];
}

/// The platform action completed successfully.
///
/// The cubit automatically resets itself to [CommunicationInitial] after
/// success, so the UI does not need to handle this state explicitly —
/// it is included here for completeness and potential analytics hooks.
class CommunicationSuccess extends CommunicationState {
  const CommunicationSuccess({required this.actor, required this.action});

  final CommunicationActor actor;
  final CommunicationAction action;

  @override
  List<Object?> get props => [actor, action];
}

/// The platform action failed with a user-presentable [message].
///
/// Widgets should surface [message] via a [SnackBar] or similar, then call
/// [CommunicationCubit.reset] to return to [CommunicationInitial].
class CommunicationFailure extends CommunicationState {
  const CommunicationFailure({
    required this.actor,
    required this.action,
    required this.message,
  });

  final CommunicationActor actor;
  final CommunicationAction action;
  final String message;

  @override
  List<Object?> get props => [actor, action, message];
}
