import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/core/database/app_database.dart';
import 'package:hostel_management/features/expense/data/datasources/expense_local_schema.dart';
import 'package:hostel_management/features/rent/data/datasources/rent_local_schema.dart';
import 'package:hostel_management/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase appDatabase;
  late ReportsRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    appDatabase = AppDatabase.instance;
    final db = await appDatabase.database;
    
    // Clean tables for tests
    await db.delete(ExpenseLocalSchema.tableExpenses);
    await db.delete(ExpenseLocalSchema.tableExpenseCategories);
    await db.delete(RentLocalSchema.tablePayments);
    await db.delete(RentLocalSchema.tableDamageCharges);
    await db.delete(RentLocalSchema.tableRentRecords);
    await db.delete(RentLocalSchema.tableStays);
    await db.delete('tenants');
    await db.delete('beds');
    await db.delete('rooms');
    await db.delete('hostels');
    await db.delete('users');

    // Create required dependencies
    await db.insert('users', {'id': 1, 'name': 'owner', 'phone': '000', 'email': 'test@test.com', 'role': 'owner', 'created_at': 'now'});
    await db.insert('hostels', {'id': 1, 'owner_user_id': 1, 'name': 'Test', 'address': 'addr', 'phone': 'phone', 'email': 'email', 'owner_name': 'name', 'created_at': 'now', 'updated_at': 'now'});
    await db.insert('rooms', {'id': 1, 'hostel_id': 1, 'room_number': 'R1', 'floor': '1', 'room_type': 'single', 'number_of_beds': 1, 'monthly_rent': 5000, 'status': 'vacant', 'created_at': 'now', 'updated_at': 'now'});
    await db.insert('beds', {'id': 1, 'room_id': 1, 'bed_number': 'B1', 'monthly_rent': 5000, 'status': 'vacant', 'created_at': 'now', 'updated_at': 'now'});
    await db.insert('tenants', {'id': 1, 'bed_id': 1, 'full_name': 'T1', 'phone_number': '123', 'status': 'active', 'check_in_date': 'now', 'created_at': 'now', 'updated_at': 'now'});
    await db.insert(RentLocalSchema.tableStays, {'id': 1, 'tenant_id': 1, 'room_id': 1, 'bed_id': 1, 'check_in_date': 'now', 'status': 'active', 'created_at': 'now', 'updated_at': 'now'});
    await db.insert(RentLocalSchema.tableRentRecords, {'id': 1, 'stay_id': 1, 'start_date': 'now', 'end_date': 'now', 'generated_at': 'now', 'due_date': 'now', 'amount_due': 1000, 'amount_paid': 0, 'status': 'pending', 'created_at': 'now', 'updated_at': 'now'});
    await db.insert(ExpenseLocalSchema.tableExpenseCategories, {'id': 1, 'name': 'Default', 'created_at': 'now'});

    repository = ReportsRepositoryImpl(appDatabase);
  });

  test('getProfitLoss calculates basic totals correctly without filters', () async {
    final db = await appDatabase.database;
    
    // Rent Revenue
    await db.insert(RentLocalSchema.tablePayments, {
      'rent_record_id': 1,
      'stay_id': 1,
      'tenant_id': 1,
      'amount': 500,
      'payment_date': '2026-07-15T10:00:00.000',
      'payment_method': 'cash',
      'receipt_number': 'REC1',
      'status': 'completed',
      'created_at': 'now',
      'updated_at': 'now',
    });
    
    // Cancelled payment should be ignored
    await db.insert(RentLocalSchema.tablePayments, {
      'rent_record_id': 1,
      'stay_id': 1,
      'tenant_id': 1,
      'amount': 100,
      'payment_date': '2026-07-16T10:00:00.000',
      'payment_method': 'cash',
      'receipt_number': 'REC2',
      'status': 'cancelled',
      'created_at': 'now',
      'updated_at': 'now',
    });

    // Damage Charge
    await db.insert(RentLocalSchema.tableDamageCharges, {
      'stay_id': 1,
      'description': 'Broken Chair',
      'amount': 200,
      'status': 'paid',
      'created_at': 'now',
      'updated_at': '2026-07-18T10:00:00.000', // Treated as payment date
    });
    // Pending charge should be ignored
    await db.insert(RentLocalSchema.tableDamageCharges, {
      'stay_id': 1,
      'description': 'Wall scuff',
      'amount': 50,
      'status': 'pending',
      'created_at': 'now',
      'updated_at': 'now',
    });

    // Expenses
    await db.insert(ExpenseLocalSchema.tableExpenses, {
      'category_id': 1,
      'title': 'Cleaning',
      'amount': 150,
      'expense_date': '2026-07-20T10:00:00.000',
      'payment_method': 'cash',
      'is_deleted': 0,
      'created_at': 'now',
      'updated_at': 'now',
    });
    // Deleted expense should be ignored
    await db.insert(ExpenseLocalSchema.tableExpenses, {
      'category_id': 1,
      'title': 'Mistake',
      'amount': 1000,
      'expense_date': '2026-07-21T10:00:00.000',
      'payment_method': 'cash',
      'is_deleted': 1,
      'created_at': 'now',
      'updated_at': 'now',
    });

    final profitLoss = await repository.getProfitLoss();

    expect(profitLoss.rentRevenue, 500);
    expect(profitLoss.damageChargeRevenue, 200);
    expect(profitLoss.totalRevenue, 700);
    expect(profitLoss.totalExpenses, 150);
    expect(profitLoss.netProfit, 550);
    expect(profitLoss.isProfit, true);
  });

  test('getProfitLoss applies date filters correctly', () async {
    final db = await appDatabase.database;
    
    // Outside range
    await db.insert(RentLocalSchema.tablePayments, {
      'rent_record_id': 1,
      'stay_id': 1,
      'tenant_id': 1,
      'amount': 1000,
      'payment_date': '2026-06-15T10:00:00.000',
      'payment_method': 'cash',
      'receipt_number': 'REC1',
      'status': 'completed',
      'created_at': 'now',
      'updated_at': 'now',
    });
    
    // Inside range
    await db.insert(RentLocalSchema.tablePayments, {
      'rent_record_id': 1,
      'stay_id': 1,
      'tenant_id': 1,
      'amount': 500,
      'payment_date': '2026-07-15T10:00:00.000',
      'payment_method': 'cash',
      'receipt_number': 'REC2',
      'status': 'completed',
      'created_at': 'now',
      'updated_at': 'now',
    });

    final from = DateTime.parse('2026-07-01T00:00:00.000');
    final to = DateTime.parse('2026-07-31T23:59:59.000');

    final profitLoss = await repository.getProfitLoss(from: from, to: to);

    // Should only include the 500 payment
    expect(profitLoss.rentRevenue, 500);
    expect(profitLoss.totalExpenses, 0);
  });
}
