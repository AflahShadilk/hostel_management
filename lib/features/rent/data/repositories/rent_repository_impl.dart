// ignore_for_file: curly_braces_in_flow_control_structures

import '../../domain/entities/checkout_request.dart';
import '../../domain/entities/checkout_settlement_entity.dart';
import '../../domain/entities/damage_charge_entity.dart';
import '../../domain/entities/deposit_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/entities/rent_record_entity.dart';
import '../../domain/entities/stay_entity.dart';
import '../../domain/repositories/rent_repository.dart';
import '../../domain/services/checkout/checkout_context.dart';
import '../../domain/services/checkout/checkout_deposit_calculator.dart';
import '../../domain/services/checkout/checkout_rent_calculator.dart';
import '../datasources/rent_local_datasource.dart';
import '../models/checkout_settlement_model.dart';
import '../models/damage_charge_model.dart';
import '../models/deposit_model.dart';
import '../models/payment_model.dart';
import '../models/persist_checkout_command.dart';
import '../models/receipt_model.dart';
import '../models/rent_record_model.dart';
import '../models/stay_model.dart';
import '../models/upsert_rent_record_command.dart';

class RentRepositoryImpl implements RentRepository {
  final RentLocalDataSource _localDataSource;

  const RentRepositoryImpl(this._localDataSource);

  // ---------------------------------------------------------------------------
  // Stay
  // ---------------------------------------------------------------------------

  @override
  Future<StayEntity> createStay(StayEntity stay) async =>
      (await _localDataSource.createStay(StayModel.fromEntity(stay)))
          .toEntity();

  @override
  Future<StayEntity?> getStayById(int id) async =>
      (await _localDataSource.getStayById(id))?.toEntity();

  @override
  Future<StayEntity?> getActiveStayByTenantId(int tenantId) async =>
      (await _localDataSource.getActiveStayByTenantId(tenantId))?.toEntity();

  @override
  Future<List<StayEntity>> getAllStays() async =>
      (await _localDataSource.getAllStays())
          .map((model) => model.toEntity())
          .toList();

  @override
  Future<StayEntity> updateStay(StayEntity stay) async =>
      (await _localDataSource.updateStay(StayModel.fromEntity(stay)))
          .toEntity();

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

  // ---------------------------------------------------------------------------
  // Rent Records
  // ---------------------------------------------------------------------------

  @override
  Future<RentRecordEntity> createRentRecord(
          RentRecordEntity rentRecord) async =>
      (await _localDataSource
              .createRentRecord(RentRecordModel.fromEntity(rentRecord)))
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
  Future<List<RentRecordEntity>> getRentRecordsByTenantId(
      int tenantId) async {
    // Fetch rent records through the tenant's active stay.
    // A tenant can only have one active stay at a time.
    final stay = await _localDataSource.getActiveStayByTenantId(tenantId);
    if (stay == null) return const [];
    return (await _localDataSource.getRentRecordsByStayId(stay.id!))
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<List<RentRecordEntity>> getAllRentRecords() async =>
      (await _localDataSource.getAllRentRecords())
          .map((model) => model.toEntity())
          .toList();

  @override
  Future<RentRecordEntity> updateRentRecord(
          RentRecordEntity rentRecord) async =>
      (await _localDataSource
              .updateRentRecord(RentRecordModel.fromEntity(rentRecord)))
          .toEntity();

  @override
  Future<void> deleteRentRecord(int id) =>
      _localDataSource.deleteRentRecord(id);

  // ---------------------------------------------------------------------------
  // Payments
  // ---------------------------------------------------------------------------

  @override
  Future<PaymentEntity> createPayment(PaymentEntity payment) async =>
      (await _localDataSource.createPayment(PaymentModel.fromEntity(payment)))
          .toEntity();

  @override
  Future<PaymentEntity?> getPaymentById(int id) async =>
      (await _localDataSource.getPaymentById(id))?.toEntity();

  @override
  Future<List<PaymentEntity>> getPaymentsByRentRecordId(
          int rentRecordId) async =>
      (await _localDataSource.getPaymentsByRentRecordId(rentRecordId))
          .map((model) => model.toEntity())
          .toList();

  @override
  Future<List<PaymentEntity>> getAllPayments() async =>
      (await _localDataSource.getAllPayments())
          .map((model) => model.toEntity())
          .toList();

  @override
  Future<PaymentEntity> updatePayment(PaymentEntity payment) async =>
      (await _localDataSource.updatePayment(PaymentModel.fromEntity(payment)))
          .toEntity();

  @override
  Future<void> deletePayment(int id) => _localDataSource.deletePayment(id);

  // ---------------------------------------------------------------------------
  // Receipts
  // ---------------------------------------------------------------------------

  @override
  Future<ReceiptEntity> generateReceiptForPayment(int paymentId) async =>
      (await _localDataSource.generateReceiptForPayment(paymentId)).toEntity();

  @override
  Future<ReceiptEntity> createReceipt(ReceiptEntity receipt) async =>
      (await _localDataSource.createReceipt(ReceiptModel.fromEntity(receipt)))
          .toEntity();

  @override
  Future<ReceiptEntity?> getReceiptByPaymentId(int paymentId) async =>
      (await _localDataSource.getReceiptByPaymentId(paymentId))?.toEntity();

  @override
  Future<List<ReceiptEntity>> getAllReceipts() async =>
      (await _localDataSource.getAllReceipts())
          .map((model) => model.toEntity())
          .toList();

  @override
  Future<ReceiptEntity> updateReceipt(ReceiptEntity receipt) async =>
      (await _localDataSource.updateReceipt(ReceiptModel.fromEntity(receipt)))
          .toEntity();

  @override
  Future<void> deleteReceipt(int id) => _localDataSource.deleteReceipt(id);

  // ---------------------------------------------------------------------------
  // Deposits
  // ---------------------------------------------------------------------------

  @override
  Future<DepositEntity> createDeposit(DepositEntity deposit) async =>
      (await _localDataSource.createDeposit(DepositModel.fromEntity(deposit)))
          .toEntity();

  @override
  Future<DepositEntity?> getDepositByStayId(int stayId) async =>
      (await _localDataSource.getDepositByStayId(stayId))?.toEntity();

  @override
  Future<List<DepositEntity>> getAllDeposits() async =>
      (await _localDataSource.getAllDeposits())
          .map((model) => model.toEntity())
          .toList();

  @override
  Future<DepositEntity> updateDeposit(DepositEntity deposit) async =>
      (await _localDataSource.updateDeposit(DepositModel.fromEntity(deposit)))
          .toEntity();

  @override
  Future<void> deleteDeposit(int id) => _localDataSource.deleteDeposit(id);

  // ---------------------------------------------------------------------------
  // Damage Charges
  // ---------------------------------------------------------------------------

  @override
  Future<DamageChargeEntity> createDamageCharge(
    DamageChargeEntity damageCharge,
  ) async =>
      (await _localDataSource.createDamageCharge(
        DamageChargeModel.fromEntity(damageCharge),
      ))
          .toEntity();

  @override
  Future<List<DamageChargeEntity>> getDamageChargesByStayId(
          int stayId) async =>
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

  // ---------------------------------------------------------------------------
  // Checkout Settlements (CRUD)
  // ---------------------------------------------------------------------------

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
      (await _localDataSource.getCheckoutSettlementByStayId(stayId))
          ?.toEntity();

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

  // ---------------------------------------------------------------------------
  // Checkout workflow — pure orchestration, no SQL, no calculations.
  //
  // Flow:
  //   1. Validate inputs.
  //   2. Load data via datasource.
  //   3. Build CheckoutContext (maps models → entities for the domain layer).
  //   4. Calculate rent (CheckoutRentCalculator).
  //   5. Upsert current-month rent record (datasource).
  //   6. Calculate settlement (CheckoutDepositCalculator).
  //   7. Commit settlement atomically (datasource).
  //   8. Return entity.
  // ---------------------------------------------------------------------------

  @override
  Future<CheckoutSettlementEntity> completeCheckout(
    CheckoutRequest request,
  ) async {
    if (!request.damageAmount.isFinite || request.damageAmount < 0) {
      throw ArgumentError('Damage amount cannot be negative.');
    }
    if (!request.otherCharges.isFinite || request.otherCharges < 0) {
      throw ArgumentError('Other charges cannot be negative.');
    }

    // 1. Load raw data from the database via the datasource.
    final bundle = await _localDataSource.loadCheckoutData(request.stayId);
    final stay = bundle.stay;

    // 2. Build the checkout context, converting models → domain entities.
    final checkoutDate = request.checkoutDate ?? DateTime.now();
    final ctx = CheckoutContext(
      stayId: stay.id!,
      tenantId: stay.tenantId,
      bedId: stay.bedId,
      roomId: stay.roomId,
      checkInDate: stay.checkInDate,
      monthlyRent: stay.monthlyRentSnapshot,
      checkoutDate: checkoutDate,
      rentRecords: bundle.rentRecords.map((r) => r.toEntity()).toList(),
      heldDeposit: bundle.heldDeposit?.toEntity(),
    );

    // 3. Calculate rent figures (prorated charge + outstanding totals).
    final rentResult = CheckoutRentCalculator.calculate(ctx);

    // 4. Build command for current-month rent record.
    final currentMonthPrefix =
        '${checkoutDate.year}-${checkoutDate.month.toString().padLeft(2, '0')}';
    final currentMonthRentRecord = UpsertRentRecordCommand(
      stayId: stay.id!,
      currentMonthPrefix: currentMonthPrefix,
      effectiveStartDate: rentResult.effectiveStartDate,
      checkoutDate: checkoutDate,
      currentMonthCharge: rentResult.currentMonthCharge,
    );

    // 5. Apply deposit against total due.
    final settlementResult = CheckoutDepositCalculator.calculate(
      rentResult: rentResult,
      damageAmount: request.damageAmount,
      otherCharges: request.otherCharges,
      heldDeposit: bundle.heldDeposit?.amount ?? 0.0,
    );

    // 6. Commit everything atomically via datasource.
    final model = await _localDataSource.persistCheckout(
      PersistCheckoutCommand(
        stayId: stay.id!,
        tenantId: stay.tenantId,
        bedId: stay.bedId,
        roomId: stay.roomId,
        checkoutDate: checkoutDate,
        notes: request.notes,
        damageAmount: request.damageAmount,
        otherCharges: request.otherCharges,
        settlement: settlementResult,
        depositId: bundle.heldDeposit?.id,
        currentMonthRentRecord: currentMonthRentRecord,
      ),
    );

    // 7. Return domain entity.
    return model.toEntity();
  }
}

