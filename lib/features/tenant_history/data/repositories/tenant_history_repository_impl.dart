import '../../../../core/database/app_database.dart';
import '../../../../features/rent/data/models/payment_model.dart';
import '../../../../features/rent/domain/entities/payment_entity.dart';
import '../../../../features/rent/domain/repositories/rent_repository.dart';
import '../../../../features/tenant/domain/repositories/tenant_repository.dart';
import '../../domain/entities/tenant_history_detail.dart';
import '../../domain/entities/tenant_history_summary.dart';
import '../../domain/repositories/tenant_history_repository.dart';

class TenantHistoryRepositoryImpl implements TenantHistoryRepository {
  final AppDatabase _database;
  final RentRepository _rentRepository;
  final TenantRepository _tenantRepository;

  const TenantHistoryRepositoryImpl(
    this._database,
    this._rentRepository,
    this._tenantRepository,
  );

  @override
  Future<List<TenantHistorySummary>> getCompletedStays() async {
    final db = await _database.database;

    final query = '''
      SELECT
        s.id AS stay_id,
        s.tenant_id,
        t.full_name,
        t.phone_number,
        s.room_id,
        s.bed_id,
        s.check_in_date,
        s.check_out_date,
        s.monthly_rent_snapshot,
        COALESCE(SUM(rr.amount_due), 0)  AS total_rent_charged,
        COALESCE(SUM(rr.amount_paid), 0) AS total_paid,
        COALESCE(d.amount, 0)            AS deposit_amount,
        COALESCE(d.refunded_amount, 0)   AS deposit_refunded,
        COALESCE(cs.status, '')          AS settlement_status
      FROM stays s
      JOIN tenants t ON s.tenant_id = t.id
      LEFT JOIN rent_records rr ON rr.stay_id = s.id
      LEFT JOIN deposits d ON d.stay_id = s.id
      LEFT JOIN checkout_settlements cs ON cs.stay_id = s.id
      WHERE s.status = 'checked_out'
      GROUP BY s.id
      ORDER BY s.check_out_date DESC
    ''';

    final results = await db.rawQuery(query);

    return results.map((row) {
      return TenantHistorySummary(
        stayId: row['stay_id'] as int,
        tenantId: row['tenant_id'] as int,
        tenantName: row['full_name'] as String,
        phoneNumber: row['phone_number'] as String,
        roomId: row['room_id'] as int,
        bedId: row['bed_id'] as int,
        checkInDate: DateTime.parse(row['check_in_date'] as String),
        checkOutDate: DateTime.parse(row['check_out_date'] as String),
        monthlyRentSnapshot: (row['monthly_rent_snapshot'] as num).toDouble(),
        totalRentCharged: (row['total_rent_charged'] as num).toDouble(),
        totalPaid: (row['total_paid'] as num).toDouble(),
        depositAmount: (row['deposit_amount'] as num).toDouble(),
        depositRefunded: (row['deposit_refunded'] as num).toDouble(),
        settlementStatus: row['settlement_status'] as String,
      );
    }).toList();
  }

  @override
  Future<TenantHistoryDetail> getStayDetail(int stayId) async {
    final stay = await _rentRepository.getStayById(stayId);
    if (stay == null) {
      throw Exception('Stay not found for id $stayId');
    }

    final tenant = await _tenantRepository.getTenantById(stay.tenantId);
    if (tenant == null) {
      throw Exception('Tenant not found for id ${stay.tenantId}');
    }

    final rentRecords = await _rentRepository.getRentRecordsByStayId(stayId);
    
    // RentRepository doesn't have getPaymentsByStayId, so we query directly
    final db = await _database.database;
    final paymentsResults = await db.query(
      'payments',
      where: 'stay_id = ?',
      whereArgs: [stayId],
      orderBy: 'payment_date DESC',
    );
    final List<PaymentEntity> payments = paymentsResults.map((map) => PaymentModel.fromMap(map) as PaymentEntity).toList();

    final deposit = await _rentRepository.getDepositByStayId(stayId);
    final checkoutSettlement = await _rentRepository.getCheckoutSettlementByStayId(stayId);

    return TenantHistoryDetail(
      stay: stay,
      tenant: tenant,
      rentRecords: rentRecords,
      payments: payments,
      deposit: deposit,
      checkoutSettlement: checkoutSettlement,
    );
  }
}
