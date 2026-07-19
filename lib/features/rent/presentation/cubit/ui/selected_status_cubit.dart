import 'package:flutter_bloc/flutter_bloc.dart';

/// Lightweight UI Cubit that holds a single selected status [String].
/// State is the current status string value.
class SelectedStatusCubit extends Cubit<String> {
  SelectedStatusCubit(super.initialStatus);

  /// Update with the newly selected dropdown value.
  void select(String status) => emit(status);
}
