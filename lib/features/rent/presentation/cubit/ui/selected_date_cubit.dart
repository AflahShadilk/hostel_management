import 'package:flutter_bloc/flutter_bloc.dart';

/// Lightweight UI Cubit that holds a single selected [DateTime].
/// State is [DateTime?]: null = not yet selected / cleared.
class SelectedDateCubit extends Cubit<DateTime?> {
  SelectedDateCubit(super.initial);

  /// Update with a newly picked date.
  void pick(DateTime date) => emit(date);

  /// Clear the selected date back to null.
  void clear() => emit(null);
}
