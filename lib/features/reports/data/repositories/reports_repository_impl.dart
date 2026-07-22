import '../../../../core/database/app_database.dart';
import '../../../expense/data/datasources/expense_local_schema.dart';
import '../../../rent/data/datasources/rent_local_schema.dart';
import '../../domain/entities/profit_loss_entity.dart';
import '../../domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final AppDatabase _appDatabase;

  ReportsRepositoryImpl(this._appDatabase);

  @override
  Future<ProfitLossEntity> getProfitLoss({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _appDatabase.database;

    final String fromDate = from != null ? from.toIso8601String() : '0000-01-01T00:00:00.000';
    final String toDate = to != null ? to.toIso8601String() : '9999-12-31T23:59:59.999';

    final result = await db.rawQuery('''
      SELECT 
        (
          SELECT COALESCE(SUM(amount), 0) 
          FROM ${RentLocalSchema.tablePayments} 
          WHERE status = 'completed' 
            AND payment_date >= ? AND payment_date <= ?
        ) AS rentRevenue,
        (
          SELECT COALESCE(SUM(amount), 0) 
          FROM ${RentLocalSchema.tableDamageCharges} 
          WHERE status = 'paid' 
            AND updated_at >= ? AND updated_at <= ?
        ) AS damageChargeRevenue,
        (
          SELECT COALESCE(SUM(amount), 0) 
          FROM ${ExpenseLocalSchema.tableExpenses} 
          WHERE is_deleted = 0 
            AND expense_date >= ? AND expense_date <= ?
        ) AS totalExpenses
    ''', <Object?>[
      fromDate, toDate,
      fromDate, toDate,
      fromDate, toDate,
    ]);

    final row = result.first;
    
    return ProfitLossEntity(
      rentRevenue: (row['rentRevenue'] as num).toDouble(),
      damageChargeRevenue: (row['damageChargeRevenue'] as num).toDouble(),
      otherRevenue: 0.0,
      totalExpenses: (row['totalExpenses'] as num).toDouble(),
    );
  }
}
