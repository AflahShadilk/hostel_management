import 'package:flutter_bloc/flutter_bloc.dart';

/// Lightweight UI Cubit that holds the computed balance [double].
/// Used in add/edit rent record to reactively display (amountDue - amountPaid).
class BalanceCubit extends Cubit<double> {
  BalanceCubit(super.initialBalance);

  /// Recalculate and emit the new balance.
  void update(double balance) => emit(balance);
}
