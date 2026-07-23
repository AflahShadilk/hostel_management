import '../models/checkout_data_bundle.dart';
import '../models/checkout_settlement_model.dart';
import '../models/damage_charge_model.dart';
import '../models/deposit_model.dart';
import '../models/payment_model.dart';
import '../models/persist_checkout_command.dart';
import '../models/receipt_model.dart';
import '../models/rent_record_model.dart';
import '../models/stay_model.dart';
import '../models/upsert_rent_record_command.dart';

abstract class RentLocalDataSource {
  Future<StayModel> createStay(StayModel stay);
  Future<StayModel?> getStayById(int id);
  Future<StayModel?> getActiveStayByTenantId(int tenantId);
  Future<List<StayModel>> getAllStays();
  Future<StayModel> updateStay(StayModel stay);
  Future<void> deleteStay(int id);

  Future<StayModel> checkInTenant({
    required int tenantId,
    required int roomId,
    required int bedId,
    required DateTime checkInDate,
    DateTime? expectedCheckoutDate,
    required double monthlyRent,
    required double dailyRate,
    required double depositAmount,
  });

  Future<int> generateNextBillingPeriods();

  Future<RentRecordModel> createRentRecord(RentRecordModel rentRecord);
  Future<RentRecordModel?> getRentRecordById(int id);
  Future<List<RentRecordModel>> getRentRecordsByStayId(int stayId);
  Future<List<RentRecordModel>> getAllRentRecords();
  Future<RentRecordModel> updateRentRecord(RentRecordModel rentRecord);
  Future<void> deleteRentRecord(int id);

  Future<PaymentModel> createPayment(PaymentModel payment);
  Future<PaymentModel?> getPaymentById(int id);
  Future<List<PaymentModel>> getPaymentsByRentRecordId(int rentRecordId);
  Future<List<PaymentModel>> getAllPayments();
  Future<PaymentModel> updatePayment(PaymentModel payment);
  Future<void> deletePayment(int id);

  Future<ReceiptModel> generateReceiptForPayment(int paymentId);
  Future<ReceiptModel> createReceipt(ReceiptModel receipt);
  Future<ReceiptModel?> getReceiptByPaymentId(int paymentId);
  Future<List<ReceiptModel>> getAllReceipts();
  Future<ReceiptModel> updateReceipt(ReceiptModel receipt);
  Future<void> deleteReceipt(int id);

  Future<DepositModel> createDeposit(DepositModel deposit);
  Future<DepositModel?> getDepositByStayId(int stayId);
  Future<List<DepositModel>> getAllDeposits();
  Future<DepositModel> updateDeposit(DepositModel deposit);
  Future<void> deleteDeposit(int id);

  Future<DamageChargeModel> createDamageCharge(DamageChargeModel damageCharge);
  Future<List<DamageChargeModel>> getDamageChargesByStayId(int stayId);
  Future<List<DamageChargeModel>> getAllDamageCharges();
  Future<DamageChargeModel> updateDamageCharge(DamageChargeModel damageCharge);
  Future<void> deleteDamageCharge(int id);

  Future<CheckoutSettlementModel> createCheckoutSettlement(
    CheckoutSettlementModel checkoutSettlement,
  );
  Future<CheckoutSettlementModel?> getCheckoutSettlementByStayId(int stayId);
  Future<List<CheckoutSettlementModel>> getAllCheckoutSettlements();
  Future<CheckoutSettlementModel> updateCheckoutSettlement(
    CheckoutSettlementModel checkoutSettlement,
  );
  Future<void> deleteCheckoutSettlement(int id);

  // ---------------------------------------------------------------------------
  // Checkout workflow — dedicated methods to keep SQL out of the repository.
  // ---------------------------------------------------------------------------

  /// Loads everything the checkout calculators need in a single round-trip:
  /// the active stay, all rent records for the stay, and the held deposit.
  Future<CheckoutDataBundle> loadCheckoutData(int stayId);

  /// Inserts a new rent record for the checkout month, or updates the existing
  /// one if a record already exists for that billing period.
  Future<void> upsertCurrentMonthRentRecord(UpsertRentRecordCommand cmd);

  /// Commits the full checkout in a single atomic transaction:
  /// settlement row, damage charge, deposit update, stay/tenant/bed/room updates.
  Future<CheckoutSettlementModel> persistCheckout(PersistCheckoutCommand cmd);
}
