import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../features/tenant/domain/entities/tenant_status.dart';
import '../../domain/constants/rent_status_constants.dart';
import '../models/checkout_settlement_model.dart';
import '../models/damage_charge_model.dart';
import '../models/deposit_model.dart';
import '../models/payment_model.dart';
import '../models/receipt_model.dart';
import '../models/rent_record_model.dart';
import '../models/stay_model.dart';
import 'rent_local_datasource.dart';
import 'rent_local_schema.dart';

class RentLocalDataSourceImpl implements RentLocalDataSource {
  final AppDatabase _appDatabase;

  const RentLocalDataSourceImpl(this._appDatabase);

  Future<T> _perform<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on DatabaseException catch (error) {
      throw Exception('Database $operation failed: $error');
    }
  }

  Future<void> _update(
    String table,
    int? id,
    Map<String, dynamic> values,
    String operation,
  ) async {
    final database = await _appDatabase.database;
    await _perform(operation, () async {
      final rowsAffected = await database.update(
        table,
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rowsAffected == 0) {
        throw StateError('Database $operation failed: record not found.');
      }
    });
  }

  Future<void> _delete(String table, int id, String operation) async {
    final database = await _appDatabase.database;
    await _perform(
      operation,
      () => database.delete(table, where: 'id = ?', whereArgs: [id]),
    );
  }

  @override
  Future<StayModel> createStay(StayModel stay) async {
    final database = await _appDatabase.database;
    return _perform('create stay', () async {
      final map = stay.toMap();
      final id = await database.insert(RentLocalSchema.tableStays, map);
      return StayModel.fromMap(<String, dynamic>{...map, 'id': id});
    });
  }

  @override
  Future<StayModel?> getStayById(int id) async {
    final database = await _appDatabase.database;
    return _perform('get stay', () async {
      final rows = await database.query(
        RentLocalSchema.tableStays,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : StayModel.fromMap(rows.first);
    });
  }

  @override
  Future<StayModel?> getActiveStayByTenantId(int tenantId) async {
    final database = await _appDatabase.database;
    return _perform('get active stay', () async {
      final rows = await database.query(
        RentLocalSchema.tableStays,
        where: 'tenant_id = ? AND status = ?',
        whereArgs: [tenantId, StayStatus.active],
        limit: 1,
      );
      return rows.isEmpty ? null : StayModel.fromMap(rows.first);
    });
  }

  @override
  Future<List<StayModel>> getAllStays() async {
    final database = await _appDatabase.database;
    return _perform('get all stays', () async {
      final rows = await database.query(RentLocalSchema.tableStays);
      return rows.map(StayModel.fromMap).toList();
    });
  }

  @override
  Future<StayModel> updateStay(StayModel stay) async {
    await _update(RentLocalSchema.tableStays, stay.id, stay.toMap(), 'update stay');
    return stay;
  }

  @override
  Future<void> deleteStay(int id) =>
      _delete(RentLocalSchema.tableStays, id, 'delete stay');

  @override
  Future<StayModel> checkInTenant({
    required int tenantId,
    required int roomId,
    required int bedId,
    required DateTime checkInDate,
    DateTime? expectedCheckoutDate,
    required double monthlyRent,
    required double dailyRate,
    required double depositAmount,
  }) async {
    final database = await _appDatabase.database;
    return _perform('check in tenant', () async {
      return await database.transaction((txn) async {
        // 1. Verify tenant exists
        final tenants = await txn.query('tenants', where: 'id = ?', whereArgs: [tenantId], limit: 1);
        if (tenants.isEmpty) throw Exception('Tenant not found.');

        // 2. Verify room exists
        final rooms = await txn.query('rooms', where: 'id = ?', whereArgs: [roomId], limit: 1);
        if (rooms.isEmpty) throw Exception('Room not found.');

        // 3. Verify bed exists, belongs to room, is vacant
        final beds = await txn.query('beds', where: 'id = ?', whereArgs: [bedId], limit: 1);
        if (beds.isEmpty) throw Exception('Bed not found.');
        if (beds.first['room_id'] != roomId) throw Exception('Bed does not belong to the selected room.');
        if (beds.first['status'] != 'vacant') throw Exception('Bed is not vacant.');

        // 4. Verify tenant does not have active stay
        final stays = await txn.query(RentLocalSchema.tableStays,
            where: 'tenant_id = ? AND status = ?',
            whereArgs: [tenantId, StayStatus.active],
            limit: 1);
        if (stays.isNotEmpty) throw Exception('Tenant already has an active stay.');

        final now = DateTime.now().toIso8601String();

        // 5. Update bed to occupied
        await txn.update('beds', {'status': 'occupied', 'updated_at': now}, where: 'id = ?', whereArgs: [bedId]);

        // 6. Update tenant to active and assign to bed
        await txn.update('tenants', {'status': 'active', 'bed_id': bedId, 'updated_at': now}, where: 'id = ?', whereArgs: [tenantId]);

        // 7. Insert Stay
        final stayMap = {
          'tenant_id': tenantId,
          'room_id': roomId,
          'bed_id': bedId,
          'check_in_date': checkInDate.toIso8601String(),
          'expected_checkout_date': expectedCheckoutDate?.toIso8601String(),
          'monthly_rent_snapshot': monthlyRent,
          'daily_rate': dailyRate,
          'status': StayStatus.active,
          'created_at': now,
          'updated_at': now,
        };
        final stayId = await txn.insert(RentLocalSchema.tableStays, stayMap);
        final createdStay = StayModel.fromMap(<String, dynamic>{...stayMap, 'id': stayId});

        // 8. If deposit > 0, Insert Deposit
        if (depositAmount > 0) {
          await txn.insert(RentLocalSchema.tableDeposits, {
            'stay_id': stayId,
            'amount': depositAmount,
            'received_date': now,
            'refunded_amount': 0.0,
            'status': 'held',
            'created_at': now,
            'updated_at': now,
          });
        }

        return createdStay;
      });
    });
  }

  @override
  Future<int> generateMonthlyRent({
    required int billingMonth,
    required int billingYear,
    required DateTime dueDate,
  }) async {
    final database = await _appDatabase.database;
    return _perform('generate monthly rent', () async {
      return await database.transaction((txn) async {
        // 1. Load all active stays.
        final stayRows = await txn.query(
          RentLocalSchema.tableStays,
          where: 'status = ?',
          whereArgs: [StayStatus.active],
        );

        final rentPeriod =
            '$billingYear-${billingMonth.toString().padLeft(2, '0')}';
        final now = DateTime.now().toIso8601String();
        int created = 0;

        for (final stay in stayRows) {
          final tenantId = stay['tenant_id'] as int;
          final monthlyRent = (stay['monthly_rent_snapshot'] as num?)?.toDouble() ?? 0.0;

          // 2. Verify the tenant is active.
          final tenantRows = await txn.query(
            'tenants',
            columns: ['status'],
            where: 'id = ?',
            whereArgs: [tenantId],
            limit: 1,
          );
          if (tenantRows.isEmpty) continue;
          final tenantStatus = tenantRows.first['status'] as String?;
          if (tenantStatus != TenantStatus.active.databaseValue) continue;

          // 3. Verify monthly rent snapshot > 0.
          if (monthlyRent <= 0) continue;

          final stayId = stay['id'] as int;

          // 4. Duplicate prevention: one record per stay per billing cycle.
          final existingRows = await txn.query(
            RentLocalSchema.tableRentRecords,
            columns: ['id'],
            where: 'stay_id = ? AND billing_month = ? AND billing_year = ?',
            whereArgs: [stayId, billingMonth, billingYear],
            limit: 1,
          );
          if (existingRows.isNotEmpty) continue;

          // 5. Insert the rent record.
          await txn.insert(RentLocalSchema.tableRentRecords, {
            'stay_id': stayId,
            'billing_month': billingMonth,
            'billing_year': billingYear,
            'rent_period': rentPeriod,
            'due_date': dueDate.toIso8601String(),
            'generated_at': now,
            'amount_due': monthlyRent,
            'amount_paid': 0.0,
            'status': RentStatus.pending,
            'created_at': now,
            'updated_at': now,
          });
          created++;
        }

        return created;
      });
    });
  }

  @override
  Future<RentRecordModel> createRentRecord(RentRecordModel rentRecord) async {
    final database = await _appDatabase.database;
    return _perform('create rent record', () async {
      final map = rentRecord.toMap();
      final id = await database.insert(RentLocalSchema.tableRentRecords, map);
      return RentRecordModel.fromMap(<String, dynamic>{...map, 'id': id});
    });
  }

  @override
  Future<RentRecordModel?> getRentRecordById(int id) async {
    final database = await _appDatabase.database;
    return _perform('get rent record', () async {
      final rows = await database.query(
        RentLocalSchema.tableRentRecords,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : RentRecordModel.fromMap(rows.first);
    });
  }

  @override
  Future<List<RentRecordModel>> getRentRecordsByStayId(int stayId) async {
    final database = await _appDatabase.database;
    return _perform('get stay rent records', () async {
      final rows = await database.query(
        RentLocalSchema.tableRentRecords,
        where: 'stay_id = ?',
        whereArgs: [stayId],
      );
      return rows.map(RentRecordModel.fromMap).toList();
    });
  }

  @override
  Future<List<RentRecordModel>> getAllRentRecords() async {
    final database = await _appDatabase.database;
    return _perform('get all rent records', () async {
      final rows = await database.query(RentLocalSchema.tableRentRecords);
      return rows.map(RentRecordModel.fromMap).toList();
    });
  }

  @override
  Future<RentRecordModel> updateRentRecord(RentRecordModel rentRecord) async {
    await _update(
      RentLocalSchema.tableRentRecords,
      rentRecord.id,
      rentRecord.toMap(),
      'update rent record',
    );
    return rentRecord;
  }

  @override
  Future<void> deleteRentRecord(int id) =>
      _delete(RentLocalSchema.tableRentRecords, id, 'delete rent record');

  @override
  Future<PaymentModel> createPayment(PaymentModel payment) async {
    final database = await _appDatabase.database;
    return _perform('allocate payment', () async {
      if (payment.id != null) {
        throw StateError('A payment that already has an ID cannot be allocated again.');
      }
      if (!payment.amount.isFinite || payment.amount <= 0) {
        throw ArgumentError('Payment amount must be greater than zero.');
      }
      if (!PaymentMethod.values.contains(payment.paymentMethod)) {
        throw ArgumentError('Payment method is not supported.');
      }
      if (payment.status != PaymentStatus.completed) {
        throw ArgumentError('Only completed payments can be allocated.');
      }

      return database.transaction((txn) async {
        final rentRows = await txn.query(
          RentLocalSchema.tableRentRecords,
          where: 'id = ?',
          whereArgs: [payment.rentRecordId],
          limit: 1,
        );
        if (rentRows.isEmpty) {
          throw StateError('Rent record not found.');
        }

        final rentRecord = rentRows.first;
        final stayId = rentRecord['stay_id'] as int;
        final amountDue = (rentRecord['amount_due'] as num).toDouble();
        final amountPaid = (rentRecord['amount_paid'] as num).toDouble();
        const moneyPrecision = 0.000001;
        final outstanding = amountDue - amountPaid;
        if (outstanding < -moneyPrecision) {
          throw StateError('Rent record has an invalid negative outstanding balance.');
        }
        if (payment.amount - outstanding > moneyPrecision) {
          throw StateError('Payment amount exceeds the outstanding balance.');
        }

        final stayRows = await txn.query(
          RentLocalSchema.tableStays,
          columns: ['tenant_id', 'status'],
          where: 'id = ?',
          whereArgs: [stayId],
          limit: 1,
        );
        if (stayRows.isEmpty) {
          throw StateError('Stay not found.');
        }
        final stay = stayRows.first;
        if (stay['status'] != StayStatus.active) {
          throw StateError('Stay is not active.');
        }

        final tenantRows = await txn.query(
          'tenants',
          columns: ['status'],
          where: 'id = ?',
          whereArgs: [stay['tenant_id']],
          limit: 1,
        );
        if (tenantRows.isEmpty ||
            tenantRows.first['status'] != TenantStatus.active.databaseValue) {
          throw StateError('Tenant is not active.');
        }

        final map = payment.toMap();
        final duplicatePayments = await txn.query(
          RentLocalSchema.tablePayments,
          columns: ['id'],
          where:
              'rent_record_id = ? AND amount = ? AND payment_date = ? AND '
              'payment_method = ? AND status = ? AND created_at = ? AND '
              'updated_at = ?',
          whereArgs: [
            map['rent_record_id'],
            map['amount'],
            map['payment_date'],
            map['payment_method'],
            map['status'],
            map['created_at'],
            map['updated_at'],
          ],
          limit: 1,
        );
        if (duplicatePayments.isNotEmpty) {
          throw StateError('This payment has already been allocated.');
        }
        final paymentId = await txn.insert(RentLocalSchema.tablePayments, map);

        final rawUpdatedAmountPaid = amountPaid + payment.amount;
        final updatedAmountPaid =
            (amountDue - rawUpdatedAmountPaid).abs() <= moneyPrecision
                ? amountDue
                : rawUpdatedAmountPaid;
        final remaining = amountDue - updatedAmountPaid;
        final status = remaining <= moneyPrecision
            ? RentStatus.paid
            : updatedAmountPaid == 0
                ? RentStatus.pending
                : RentStatus.partial;
        final updatedRows = await txn.update(
          RentLocalSchema.tableRentRecords,
          {
            'amount_paid': updatedAmountPaid,
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [payment.rentRecordId],
        );
        if (updatedRows != 1) {
          throw StateError('Rent record update failed.');
        }

        return PaymentModel.fromMap(<String, dynamic>{...map, 'id': paymentId});
      });
    });
  }

  @override
  Future<PaymentModel?> getPaymentById(int id) async {
    final database = await _appDatabase.database;
    return _perform('get payment', () async {
      final rows = await database.query(
        RentLocalSchema.tablePayments,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : PaymentModel.fromMap(rows.first);
    });
  }

  @override
  Future<List<PaymentModel>> getPaymentsByRentRecordId(int rentRecordId) async {
    final database = await _appDatabase.database;
    return _perform('get rent record payments', () async {
      final rows = await database.query(
        RentLocalSchema.tablePayments,
        where: 'rent_record_id = ?',
        whereArgs: [rentRecordId],
      );
      return rows.map(PaymentModel.fromMap).toList();
    });
  }

  @override
  Future<List<PaymentModel>> getAllPayments() async {
    final database = await _appDatabase.database;
    return _perform('get all payments', () async {
      final rows = await database.query(RentLocalSchema.tablePayments);
      return rows.map(PaymentModel.fromMap).toList();
    });
  }

  @override
  Future<PaymentModel> updatePayment(PaymentModel payment) async {
    await _update(RentLocalSchema.tablePayments, payment.id, payment.toMap(), 'update payment');
    return payment;
  }

  @override
  Future<void> deletePayment(int id) =>
      _delete(RentLocalSchema.tablePayments, id, 'delete payment');

  @override
  Future<ReceiptModel> createReceipt(ReceiptModel receipt) async {
    final database = await _appDatabase.database;
    return _perform('create receipt', () async {
      final map = receipt.toMap();
      final id = await database.insert(RentLocalSchema.tableReceipts, map);
      return ReceiptModel.fromMap(<String, dynamic>{...map, 'id': id});
    });
  }

  @override
  Future<ReceiptModel?> getReceiptByPaymentId(int paymentId) async {
    final database = await _appDatabase.database;
    return _perform('get receipt', () async {
      final rows = await database.query(
        RentLocalSchema.tableReceipts,
        where: 'payment_id = ?',
        whereArgs: [paymentId],
        limit: 1,
      );
      return rows.isEmpty ? null : ReceiptModel.fromMap(rows.first);
    });
  }

  @override
  Future<List<ReceiptModel>> getAllReceipts() async {
    final database = await _appDatabase.database;
    return _perform('get all receipts', () async {
      final rows = await database.query(RentLocalSchema.tableReceipts);
      return rows.map(ReceiptModel.fromMap).toList();
    });
  }

  @override
  Future<ReceiptModel> updateReceipt(ReceiptModel receipt) async {
    await _update(RentLocalSchema.tableReceipts, receipt.id, receipt.toMap(), 'update receipt');
    return receipt;
  }

  @override
  Future<void> deleteReceipt(int id) =>
      _delete(RentLocalSchema.tableReceipts, id, 'delete receipt');

  @override
  Future<DepositModel> createDeposit(DepositModel deposit) async {
    final database = await _appDatabase.database;
    return _perform('create deposit', () async {
      final map = deposit.toMap();
      final id = await database.insert(RentLocalSchema.tableDeposits, map);
      return DepositModel.fromMap(<String, dynamic>{...map, 'id': id});
    });
  }

  @override
  Future<DepositModel?> getDepositByStayId(int stayId) async {
    final database = await _appDatabase.database;
    return _perform('get deposit', () async {
      final rows = await database.query(
        RentLocalSchema.tableDeposits,
        where: 'stay_id = ?',
        whereArgs: [stayId],
        limit: 1,
      );
      return rows.isEmpty ? null : DepositModel.fromMap(rows.first);
    });
  }

  @override
  Future<List<DepositModel>> getAllDeposits() async {
    final database = await _appDatabase.database;
    return _perform('get all deposits', () async {
      final rows = await database.query(RentLocalSchema.tableDeposits);
      return rows.map(DepositModel.fromMap).toList();
    });
  }

  @override
  Future<DepositModel> updateDeposit(DepositModel deposit) async {
    await _update(RentLocalSchema.tableDeposits, deposit.id, deposit.toMap(), 'update deposit');
    return deposit;
  }

  @override
  Future<void> deleteDeposit(int id) =>
      _delete(RentLocalSchema.tableDeposits, id, 'delete deposit');

  @override
  Future<DamageChargeModel> createDamageCharge(
    DamageChargeModel damageCharge,
  ) async {
    final database = await _appDatabase.database;
    return _perform('create damage charge', () async {
      final map = damageCharge.toMap();
      final id = await database.insert(RentLocalSchema.tableDamageCharges, map);
      return DamageChargeModel.fromMap(<String, dynamic>{...map, 'id': id});
    });
  }

  @override
  Future<List<DamageChargeModel>> getDamageChargesByStayId(int stayId) async {
    final database = await _appDatabase.database;
    return _perform('get stay damage charges', () async {
      final rows = await database.query(
        RentLocalSchema.tableDamageCharges,
        where: 'stay_id = ?',
        whereArgs: [stayId],
      );
      return rows.map(DamageChargeModel.fromMap).toList();
    });
  }

  @override
  Future<List<DamageChargeModel>> getAllDamageCharges() async {
    final database = await _appDatabase.database;
    return _perform('get all damage charges', () async {
      final rows = await database.query(RentLocalSchema.tableDamageCharges);
      return rows.map(DamageChargeModel.fromMap).toList();
    });
  }

  @override
  Future<DamageChargeModel> updateDamageCharge(
    DamageChargeModel damageCharge,
  ) async {
    await _update(
      RentLocalSchema.tableDamageCharges,
      damageCharge.id,
      damageCharge.toMap(),
      'update damage charge',
    );
    return damageCharge;
  }

  @override
  Future<void> deleteDamageCharge(int id) =>
      _delete(RentLocalSchema.tableDamageCharges, id, 'delete damage charge');

  @override
  Future<CheckoutSettlementModel> createCheckoutSettlement(
    CheckoutSettlementModel checkoutSettlement,
  ) async {
    final database = await _appDatabase.database;
    return _perform('create checkout settlement', () async {
      final map = checkoutSettlement.toMap();
      final id = await database.insert(
        RentLocalSchema.tableCheckoutSettlements,
        map,
      );
      return CheckoutSettlementModel.fromMap(<String, dynamic>{...map, 'id': id});
    });
  }

  @override
  Future<CheckoutSettlementModel?> getCheckoutSettlementByStayId(
    int stayId,
  ) async {
    final database = await _appDatabase.database;
    return _perform('get checkout settlement', () async {
      final rows = await database.query(
        RentLocalSchema.tableCheckoutSettlements,
        where: 'stay_id = ?',
        whereArgs: [stayId],
        limit: 1,
      );
      return rows.isEmpty ? null : CheckoutSettlementModel.fromMap(rows.first);
    });
  }

  @override
  Future<List<CheckoutSettlementModel>> getAllCheckoutSettlements() async {
    final database = await _appDatabase.database;
    return _perform('get all checkout settlements', () async {
      final rows = await database.query(RentLocalSchema.tableCheckoutSettlements);
      return rows.map(CheckoutSettlementModel.fromMap).toList();
    });
  }

  @override
  Future<CheckoutSettlementModel> updateCheckoutSettlement(
    CheckoutSettlementModel checkoutSettlement,
  ) async {
    await _update(
      RentLocalSchema.tableCheckoutSettlements,
      checkoutSettlement.id,
      checkoutSettlement.toMap(),
      'update checkout settlement',
    );
    return checkoutSettlement;
  }

  @override
  Future<void> deleteCheckoutSettlement(int id) => _delete(
        RentLocalSchema.tableCheckoutSettlements,
        id,
        'delete checkout settlement',
      );
}
