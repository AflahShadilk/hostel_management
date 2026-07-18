import 'package:equatable/equatable.dart';
import '../../domain/entities/tenant_entity.dart';

class TenantViewModel extends Equatable {
  final TenantEntity tenant;
  final String roomName;
  final String bedName;

  const TenantViewModel({
    required this.tenant,
    required this.roomName,
    required this.bedName,
  });

  @override
  List<Object?> get props => [tenant, roomName, bedName];
}
