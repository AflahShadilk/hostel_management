import '../entities/profit_loss_entity.dart';

abstract interface class ReportsRepository {
  Future<ProfitLossEntity> getProfitLoss({
    DateTime? from,
    DateTime? to,
  });
}
