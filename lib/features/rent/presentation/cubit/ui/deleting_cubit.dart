import 'package:flutter_bloc/flutter_bloc.dart';

/// Lightweight UI Cubit that tracks whether a delete operation is in-flight.
/// State is [bool]: true = deleting, false = idle.
class DeletingCubit extends Cubit<bool> {
  DeletingCubit() : super(false);

  /// Mark deletion as started.
  void start() => emit(true);

  /// Mark deletion as finished (success or error).
  void stop() => emit(false);
}
