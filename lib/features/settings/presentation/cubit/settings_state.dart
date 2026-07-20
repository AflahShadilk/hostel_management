import 'package:equatable/equatable.dart';
import '../../domain/entities/settings_entity.dart';
abstract class SettingsState extends Equatable { const SettingsState(); }
class SettingsInitial extends SettingsState { const SettingsInitial(); @override List<Object?> get props => const []; }
class SettingsLoading extends SettingsState { const SettingsLoading(); @override List<Object?> get props => const []; }
class SettingsLoaded extends SettingsState { const SettingsLoaded(this.settings); final SettingsEntity settings; @override List<Object?> get props => [settings]; }
class SettingsError extends SettingsState { const SettingsError(this.message); final String message; @override List<Object?> get props => [message]; }
class SettingsOperationInProgress extends SettingsLoaded { const SettingsOperationInProgress(super.settings); }
class SettingsOperationSuccess extends SettingsLoaded { const SettingsOperationSuccess(super.settings, this.message); final String message; @override List<Object?> get props => [settings, message]; }
class SettingsOperationError extends SettingsLoaded { const SettingsOperationError(super.settings, this.message); final String message; @override List<Object?> get props => [settings, message]; }
