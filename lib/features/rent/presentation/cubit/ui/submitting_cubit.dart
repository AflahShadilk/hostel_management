import 'package:flutter_bloc/flutter_bloc.dart';

/// Lightweight UI Cubit that tracks whether a form submission is in-flight.
/// State is [bool]: true = submitting, false = idle.
class SubmittingCubit extends Cubit<bool> {
  SubmittingCubit() : super(false);

  /// Mark submission as started.
  void start() => emit(true);

  /// Mark submission as finished (success or error).
  void stop() => emit(false);
}
