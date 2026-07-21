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

class RentRepositoryImpl implements RentRepository {
  final RentLocalDataSource _localDataSource;

  const RentRepositoryImpl(this._localDataSource);

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
}
