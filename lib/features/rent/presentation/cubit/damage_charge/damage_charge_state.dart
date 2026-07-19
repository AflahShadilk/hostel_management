import 'package:equatable/equatable.dart';

import '../../../domain/entities/damage_charge_entity.dart';

abstract class DamageChargeState extends Equatable {
  const DamageChargeState();
}

class DamageChargeInitial extends DamageChargeState {
  const DamageChargeInitial();

  @override
  List<Object?> get props => const [];
}

class DamageChargeLoading extends DamageChargeState {
  const DamageChargeLoading();

  @override
  List<Object?> get props => const [];
}

class DamageChargeLoaded extends DamageChargeState {
  final List<DamageChargeEntity> damageCharges;

  const DamageChargeLoaded(this.damageCharges);

  @override
  List<Object?> get props => [damageCharges];
}

class DamageChargeEmpty extends DamageChargeState {
  const DamageChargeEmpty();

  @override
  List<Object?> get props => const [];
}

class DamageChargeError extends DamageChargeState {
  final String message;

  const DamageChargeError(this.message);

  @override
  List<Object?> get props => [message];
}
