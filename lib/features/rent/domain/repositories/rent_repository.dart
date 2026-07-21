import '../entities/checkout_settlement_entity.dart';
import '../entities/damage_charge_entity.dart';
import '../entities/deposit_entity.dart';
import '../entities/payment_entity.dart';
import '../entities/receipt_entity.dart';
import '../entities/rent_record_entity.dart';
import '../entities/stay_entity.dart';

abstract interface class RentRepository {
  Future<StayEntity> createStay(StayEntity stay);
  Future<StayEntity?> getStayById(int id);
  Future<StayEntity?> getActiveStayByTenantId(int tenantId);
  Future<List<StayEntity>> getAllStays();
  Future<StayEntity> updateStay(StayEntity stay);
  Future<void> deleteStay(int id);

  Future<StayEntity> checkInTenant({
    required int tenantId,
    required int roomId,
    required int bedId,
    required DateTime checkInDate,
    DateTime? expectedCheckoutDate,
    required double monthlyRent,
    required double dailyRate,
    required double depositAmount,
  });

  /// Generates the next billing period for every active Stay that has no
  /// open (future) Rent Record. Returns the number of new records created.
  Future<int> generateNextBillingPeriods();

  Future<RentRecordEntity> createRentRecord(RentRecordEntity rentRecord);
  Future<RentRecordEntity?> getRentRecordById(int id);
  Future<List<RentRecordEntity>> getRentRecordsByStayId(int stayId);
  Future<List<RentRecordEntity>> getAllRentRecords();
  Future<RentRecordEntity> updateRentRecord(RentRecordEntity rentRecord);
  Future<void> deleteRentRecord(int id);

  Future<PaymentEntity> createPayment(PaymentEntity payment);
  Future<PaymentEntity?> getPaymentById(int id);
  Future<List<PaymentEntity>> getPaymentsByRentRecordId(int rentRecordId);
  Future<List<PaymentEntity>> getAllPayments();
  Future<PaymentEntity> updatePayment(PaymentEntity payment);
  Future<void> deletePayment(int id);

  Future<ReceiptEntity> generateReceiptForPayment(int paymentId);
  Future<ReceiptEntity> createReceipt(ReceiptEntity receipt);
  Future<ReceiptEntity?> getReceiptByPaymentId(int paymentId);
  Future<List<ReceiptEntity>> getAllReceipts();
  Future<ReceiptEntity> updateReceipt(ReceiptEntity receipt);
  Future<void> deleteReceipt(int id);

  Future<DepositEntity> createDeposit(DepositEntity deposit);
  Future<DepositEntity?> getDepositByStayId(int stayId);
  Future<List<DepositEntity>> getAllDeposits();
  Future<DepositEntity> updateDeposit(DepositEntity deposit);
  Future<void> deleteDeposit(int id);

  Future<DamageChargeEntity> createDamageCharge(DamageChargeEntity damageCharge);
  Future<List<DamageChargeEntity>> getDamageChargesByStayId(int stayId);
  Future<List<DamageChargeEntity>> getAllDamageCharges();
  Future<DamageChargeEntity> updateDamageCharge(DamageChargeEntity damageCharge);
  Future<void> deleteDamageCharge(int id);

  Future<CheckoutSettlementEntity> createCheckoutSettlement(
    CheckoutSettlementEntity checkoutSettlement,
  );
  Future<CheckoutSettlementEntity?> getCheckoutSettlementByStayId(int stayId);
  Future<List<CheckoutSettlementEntity>> getAllCheckoutSettlements();
  Future<CheckoutSettlementEntity> updateCheckoutSettlement(
    CheckoutSettlementEntity checkoutSettlement,
  );
  Future<void> deleteCheckoutSettlement(int id);
}
