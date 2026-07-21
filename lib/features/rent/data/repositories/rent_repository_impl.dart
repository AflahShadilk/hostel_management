import 'package:hostel_management/core/database/app_database.dart';
import 'package:hostel_management/features/rent/domain/constants/rent_status_constants.dart';
import 'package:hostel_management/features/rent/domain/entities/checkout_request.dart';
import 'package:hostel_management/features/room/data/datasources/room_local_schema.dart';
import 'package:hostel_management/features/room/domain/entities/bed_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_status.dart';
import 'package:hostel_management/features/tenant/data/datasources/tenant_local_schema.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_status.dart';

import '../../domain/entities/checkout_settlement_entity.dart';
import '../../domain/entities/damage_charge_entity.dart';
import '../../domain/entities/deposit_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/entities/rent_record_entity.dart';
import '../../domain/entities/stay_entity.dart';
import '../../domain/repositories/rent_repository.dart';
import '../datasources/rent_local_datasource.dart';
import '../models/checkout_settlement_model.dart';
import '../models/damage_charge_model.dart';
import '../models/deposit_model.dart';
import '../models/payment_model.dart';
import '../models/receipt_model.dart';
import '../models/rent_record_model.dart';
import '../models/stay_model.dart';
import '../datasources/rent_local_schema.dart';

class RentRepositoryImpl implements RentRepository {
  final RentLocalDataSource _localDataSource;
  final AppDatabase _appDatabase;

  const RentRepositoryImpl(this._localDataSource, this._appDatabase);

  @override
  Future<StayEntity> createStay(StayEntity stay) async =>
      (await _localDataSource.createStay(StayModel.fromEntity(stay))).toEntity();

  @override
  Future<StayEntity?> getStayById(int id) async =>
      (await _localDataSource.getStayById(id))?.toEntity();

  @override
  Future<StayEntity?> getActiveStayByTenantId(int tenantId) async =>
      (await _localDataSource.getActiveStayByTenantId(tenantId))?.toEntity();

  @override
  Future<List<StayEntity>> getAllStays() async =>
      (await _localDataSource.getAllStays()).map((model) => model.toEntity()).toList();

  @override
  Future<StayEntity> updateStay(StayEntity stay) async =>
      (await _localDataSource.updateStay(StayModel.fromEntity(stay))).toEntity();

  @override
  Future<void> deleteStay(int id) => _localDataSource.deleteStay(id);

  @override
  Future<StayEntity> checkInTenant({
    required int tenantId,
    required int roomId,
    required int bedId,
    required DateTime checkInDate,
    DateTime? expectedCheckoutDate,
    required double monthlyRent,
    required double dailyRate,
    required double depositAmount,
  }) async {
    return (await _localDataSource.checkInTenant(
      tenantId: tenantId,
      roomId: roomId,
      bedId: bedId,
      checkInDate: checkInDate,
      expectedCheckoutDate: expectedCheckoutDate,
      monthlyRent: monthlyRent,
      dailyRate: dailyRate,
      depositAmount: depositAmount,
    ))
        .toEntity();
  }

  @override
  Future<int> generateNextBillingPeriods() =>
      _localDataSource.generateNextBillingPeriods();

  @override
  Future<RentRecordEntity> createRentRecord(RentRecordEntity rentRecord) async =>
      (await _localDataSource.createRentRecord(RentRecordModel.fromEntity(rentRecord)))
          .toEntity();

  @override
  Future<RentRecordEntity?> getRentRecordById(int id) async =>
      (await _localDataSource.getRentRecordById(id))?.toEntity();

  @override
  Future<List<RentRecordEntity>> getRentRecordsByStayId(int stayId) async =>
      (await _localDataSource.getRentRecordsByStayId(stayId))
          .map((model) => model.toEntity())
          .toList();

  @override
  Future<List<RentRecordEntity>> getAllRentRecords() async =>
      (await _localDataSource.getAllRentRecords())
          .map((model) => model.toEntity())
          .toList();

  @override
  Future<RentRecordEntity> updateRentRecord(RentRecordEntity rentRecord) async =>
      (await _localDataSource.updateRentRecord(RentRecordModel.fromEntity(rentRecord)))
          .toEntity();

  @override
  Future<void> deleteRentRecord(int id) => _localDataSource.deleteRentRecord(id);

  @override
  Future<PaymentEntity> createPayment(PaymentEntity payment) async =>
      (await _localDataSource.createPayment(PaymentModel.fromEntity(payment))).toEntity();

  @override
  Future<PaymentEntity?> getPaymentById(int id) async =>
      (await _localDataSource.getPaymentById(id))?.toEntity();

  @override
  Future<List<PaymentEntity>> getPaymentsByRentRecordId(int rentRecordId) async =>
      (await _localDataSource.getPaymentsByRentRecordId(rentRecordId))
          .map((model) => model.toEntity())
          .toList();

  @override
  Future<List<PaymentEntity>> getAllPayments() async =>
      (await _localDataSource.getAllPayments()).map((model) => model.toEntity()).toList();

  @override
  Future<PaymentEntity> updatePayment(PaymentEntity payment) async =>
      (await _localDataSource.updatePayment(PaymentModel.fromEntity(payment))).toEntity();

  @override
  Future<void> deletePayment(int id) => _localDataSource.deletePayment(id);

  @override
  Future<ReceiptEntity> generateReceiptForPayment(int paymentId) async =>
      (await _localDataSource.generateReceiptForPayment(paymentId)).toEntity();

  @override
  Future<ReceiptEntity> createReceipt(ReceiptEntity receipt) async =>
      (await _localDataSource.createReceipt(ReceiptModel.fromEntity(receipt))).toEntity();

  @override
  Future<ReceiptEntity?> getReceiptByPaymentId(int paymentId) async =>
      (await _localDataSource.getReceiptByPaymentId(paymentId))?.toEntity();

  @override
  Future<List<ReceiptEntity>> getAllReceipts() async =>
      (await _localDataSource.getAllReceipts()).map((model) => model.toEntity()).toList();

  @override
  Future<ReceiptEntity> updateReceipt(ReceiptEntity receipt) async =>
      (await _localDataSource.updateReceipt(ReceiptModel.fromEntity(receipt))).toEntity();

  @override
  Future<void> deleteReceipt(int id) => _localDataSource.deleteReceipt(id);

  @override
  Future<DepositEntity> createDeposit(DepositEntity deposit) async =>
      (await _localDataSource.createDeposit(DepositModel.fromEntity(deposit))).toEntity();

  @override
  Future<DepositEntity?> getDepositByStayId(int stayId) async =>
      (await _localDataSource.getDepositByStayId(stayId))?.toEntity();

  @override
  Future<List<DepositEntity>> getAllDeposits() async =>
      (await _localDataSource.getAllDeposits()).map((model) => model.toEntity()).toList();

  @override
  Future<DepositEntity> updateDeposit(DepositEntity deposit) async =>
      (await _localDataSource.updateDeposit(DepositModel.fromEntity(deposit))).toEntity();

  @override
  Future<void> deleteDeposit(int id) => _localDataSource.deleteDeposit(id);

  @override
  Future<DamageChargeEntity> createDamageCharge(
    DamageChargeEntity damageCharge,
  ) async =>
      (await _localDataSource.createDamageCharge(
        DamageChargeModel.fromEntity(damageCharge),
      ))
          .toEntity();

  @override
  Future<List<DamageChargeEntity>> getDamageChargesByStayId(int stayId) async =>
      (await _localDataSource.getDamageChargesByStayId(stayId))
          .map((model) => model.toEntity())
          .toList();

  @override
  Future<List<DamageChargeEntity>> getAllDamageCharges() async =>
      (await _localDataSource.getAllDamageCharges())
          .map((model) => model.toEntity())
          .toList();

  @override
  Future<DamageChargeEntity> updateDamageCharge(
    DamageChargeEntity damageCharge,
  ) async =>
      (await _localDataSource.updateDamageCharge(
        DamageChargeModel.fromEntity(damageCharge),
      ))
          .toEntity();

  @override
  Future<void> deleteDamageCharge(int id) =>
      _localDataSource.deleteDamageCharge(id);

  @override
  Future<CheckoutSettlementEntity> createCheckoutSettlement(
    CheckoutSettlementEntity checkoutSettlement,
  ) async =>
      (await _localDataSource.createCheckoutSettlement(
        CheckoutSettlementModel.fromEntity(checkoutSettlement),
      ))
          .toEntity();

  @override
  Future<CheckoutSettlementEntity?> getCheckoutSettlementByStayId(
    int stayId,
  ) async =>
      (await _localDataSource.getCheckoutSettlementByStayId(stayId))?.toEntity();

  @override
  Future<List<CheckoutSettlementEntity>> getAllCheckoutSettlements() async =>
      (await _localDataSource.getAllCheckoutSettlements())
          .map((model) => model.toEntity())
          .toList();

  @override
  Future<CheckoutSettlementEntity> updateCheckoutSettlement(
    CheckoutSettlementEntity checkoutSettlement,
  ) async =>
      (await _localDataSource.updateCheckoutSettlement(
        CheckoutSettlementModel.fromEntity(checkoutSettlement),
      ))
          .toEntity();

  @override
  Future<void> deleteCheckoutSettlement(int id) =>
      _localDataSource.deleteCheckoutSettlement(id);

  @override
  Future<CheckoutSettlementEntity> completeCheckout(
    CheckoutRequest request,
  ) async {
    if (!request.damageAmount.isFinite || request.damageAmount < 0) {
      throw ArgumentError('Damage amount cannot be negative.');
    }
    final database = await _appDatabase.database;
    return database.transaction((txn) async {
      final stayRows = await txn.query(
        RentLocalSchema.tableStays,
        where: 'id = ? AND status = ?',
        whereArgs: <Object?>[request.stayId, StayStatus.active],
        limit: 1,
      );
      if (stayRows.isEmpty) throw StateError('Active stay not found.');
      final stay = stayRows.first;
      final existing = await txn.query(
        RentLocalSchema.tableCheckoutSettlements,
        where: 'stay_id = ?',
        whereArgs: <Object?>[request.stayId],
        limit: 1,
      );
      if (existing.isNotEmpty) throw StateError('Checkout settlement already exists.');

      final rent = await txn.rawQuery('''
        SELECT COALESCE(SUM(amount_due - amount_paid), 0) AS outstanding
        FROM ${RentLocalSchema.tableRentRecords} WHERE stay_id = ?
      ''', <Object?>[request.stayId]);
      final outstanding = (rent.first['outstanding'] as num).toDouble();
      final depositRows = await txn.query(
        RentLocalSchema.tableDeposits,
        where: 'stay_id = ? AND status = ?',
        whereArgs: <Object?>[request.stayId, 'held'],
        limit: 1,
      );
      final deposit = depositRows.isEmpty ? null : depositRows.first;
      final held = deposit == null ? 0.0 : (deposit['amount'] as num).toDouble();
      final totalDue = outstanding + request.damageAmount;
      final refund = (held - totalDue).clamp(0, double.infinity).toDouble();
      final adjustment = held - refund;
      final remaining = (totalDue - held).clamp(0, double.infinity).toDouble();
      final now = DateTime.now();
      final nowText = now.toIso8601String();

      final settlementId = await txn.insert(RentLocalSchema.tableCheckoutSettlements, {
        'stay_id': request.stayId, 'outstanding_amount': outstanding,
        'rent_due': outstanding, 'late_fee': 0.0,
        'damage_charges': request.damageAmount, 'deposit_adjustment': adjustment,
        'refund_amount': refund, 'final_amount': remaining,
        'settlement_date': nowText, 'notes': request.notes?.trim().isEmpty == true ? null : request.notes?.trim(),
        'status': SettlementStatus.completed, 'created_at': nowText, 'updated_at': nowText,
      });
      if (request.damageAmount > 0) {
        await txn.insert(RentLocalSchema.tableDamageCharges, {
          'stay_id': request.stayId, 'description': request.notes?.trim().isNotEmpty == true ? request.notes!.trim() : 'Checkout damage charge',
          'amount': request.damageAmount, 'status': 'paid', 'created_at': nowText, 'updated_at': nowText,
        });
      }
      if (deposit != null) {
        await txn.update(RentLocalSchema.tableDeposits, {
          'refunded_amount': refund, 'refund_date': nowText,
          'status': refund > 0 ? 'refunded' : 'forfeited', 'updated_at': nowText,
        }, where: 'id = ?', whereArgs: <Object?>[deposit['id']]);
      }
      await txn.update(RentLocalSchema.tableStays, {
        'status': StayStatus.checkedOut, 'check_out_date': nowText, 'updated_at': nowText,
      }, where: 'id = ?', whereArgs: <Object?>[request.stayId]);
      await txn.update(TenantLocalSchema.tableTenants, {
        TenantLocalSchema.colStatus: TenantStatus.checkedOut.databaseValue,
        TenantLocalSchema.colBedId: null, TenantLocalSchema.colCheckOutDate: nowText,
        TenantLocalSchema.colUpdatedAt: nowText,
      }, where: 'id = ?', whereArgs: <Object?>[stay['tenant_id']]);
      await txn.update(RoomLocalSchema.tableBeds, {
        'status': BedStatus.vacant.databaseValue, 'updated_at': nowText,
      }, where: 'id = ?', whereArgs: <Object?>[stay['bed_id']]);
      final roomId = stay['room_id'] as int;
      final occupancy = await txn.rawQuery('SELECT COUNT(*) AS occupied, (SELECT COUNT(*) FROM ${RoomLocalSchema.tableBeds} WHERE room_id = ?) AS total FROM ${RoomLocalSchema.tableBeds} WHERE room_id = ? AND status = ?', <Object?>[roomId, roomId, BedStatus.occupied.databaseValue]);
      final occupied = (occupancy.first['occupied'] as num).toInt();
      final total = (occupancy.first['total'] as num).toInt();
      await txn.update(RoomLocalSchema.tableRooms, {
        'status': occupied == 0 ? RoomStatus.vacant.databaseValue : occupied == total ? RoomStatus.occupied.databaseValue : RoomStatus.partiallyOccupied.databaseValue,
        'updated_at': nowText,
      }, where: 'id = ?', whereArgs: <Object?>[roomId]);
      return CheckoutSettlementEntity(id: settlementId, stayId: request.stayId, outstandingAmount: outstanding, rentDue: outstanding, lateFee: 0, damageCharges: request.damageAmount, depositAdjustment: adjustment, refundAmount: refund, finalAmount: remaining, settlementDate: now, notes: request.notes?.trim().isEmpty == true ? null : request.notes?.trim(), status: SettlementStatus.completed, createdAt: now, updatedAt: now);
    });
  }
}

