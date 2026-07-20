import '../../../../core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';
import '../../../expense/data/datasources/expense_local_schema.dart';
import '../../../rent/data/datasources/rent_local_schema.dart';
import '../../../rent/domain/constants/rent_status_constants.dart';
import '../../../room/data/datasources/room_local_schema.dart';
import '../../../room/domain/entities/room_status.dart';
import '../../../tenant/data/datasources/tenant_local_schema.dart';
import '../../domain/entities/search_filter.dart';
import '../../domain/entities/search_result_entity.dart';
import '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<SearchResultEntity>> search({
    required String query,
    required SearchFilter filter,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty && filter == SearchFilter.all) {
      return const <SearchResultEntity>[];
    }

    final database = await _appDatabase.database;
    switch (filter) {
      case SearchFilter.tenant:
        return _searchTenants(database, normalizedQuery);
      case SearchFilter.room:
        return _searchRooms(database, normalizedQuery);
      case SearchFilter.rent:
        return _searchRentRecords(database, normalizedQuery);
      case SearchFilter.expense:
        return _searchExpenses(database, normalizedQuery);
      case SearchFilter.pendingRent:
        return _searchRentRecords(
          database,
          normalizedQuery,
          statuses: const <String>[
            RentStatus.pending,
            RentStatus.partial,
            RentStatus.overdue,
          ],
        );
      case SearchFilter.occupied:
        return _searchRooms(
          database,
          normalizedQuery,
          status: RoomStatus.occupied.databaseValue,
        );
      case SearchFilter.vacant:
        return _searchRooms(
          database,
          normalizedQuery,
          status: RoomStatus.vacant.databaseValue,
        );
      case SearchFilter.all:
        final results = await Future.wait(<Future<List<SearchResultEntity>>>[
          _searchTenants(database, normalizedQuery),
          _searchRooms(database, normalizedQuery),
          _searchRentRecords(database, normalizedQuery),
          _searchExpenses(database, normalizedQuery),
        ]);
        return results.expand((items) => items).toList();
    }
  }

  Future<List<SearchResultEntity>> _searchTenants(
    Database database,
    String query,
  ) async {
    final pattern = '%$query%';
    final rows = await database.rawQuery(
      '''
        SELECT id, full_name, phone_number, emergency_contact_name,
               emergency_contact_phone
        FROM ${TenantLocalSchema.tableTenants}
        WHERE full_name LIKE ? COLLATE NOCASE
           OR phone_number LIKE ? COLLATE NOCASE
           OR emergency_contact_name LIKE ? COLLATE NOCASE
           OR emergency_contact_phone LIKE ? COLLATE NOCASE
        ORDER BY full_name COLLATE NOCASE ASC
      ''',
      <Object?>[pattern, pattern, pattern, pattern],
    );

    return rows
        .map(
          (row) => SearchResultEntity(
            id: row['id'] as int,
            type: SearchResultType.tenant,
            title: row['full_name'] as String,
            subtitle: _tenantSubtitle(row),
          ),
        )
        .toList();
  }

  Future<List<SearchResultEntity>> _searchRooms(
    Database database,
    String query, {
    String? status,
  }) async {
    final pattern = '%$query%';
    final where = <String>[
      '(room_number LIKE ? COLLATE NOCASE OR room_type LIKE ? COLLATE NOCASE)',
      if (status != null) 'status = ?',
    ];
    final arguments = <Object?>[pattern, pattern, if (status != null) status];
    final rows = await database.rawQuery(
      '''
        SELECT id, room_number, room_type, status
        FROM ${RoomLocalSchema.tableRooms}
        WHERE ${where.join(' AND ')}
        ORDER BY room_number COLLATE NOCASE ASC
      ''',
      arguments,
    );

    return rows
        .map(
          (row) => SearchResultEntity(
            id: row['id'] as int,
            type: SearchResultType.room,
            title: 'Room ${row['room_number']}',
            subtitle: '${row['room_type']} • ${row['status']}',
          ),
        )
        .toList();
  }

  Future<List<SearchResultEntity>> _searchRentRecords(
    Database database,
    String query, {
    List<String>? statuses,
  }) async {
    final pattern = '%$query%';
    final where = <String>[
      '(rent_period LIKE ? COLLATE NOCASE OR status LIKE ? COLLATE NOCASE OR CAST(stay_id AS TEXT) LIKE ?)',
      if (statuses != null)
        'status IN (${List.filled(statuses.length, '?').join(', ')})',
    ];
    final arguments = <Object?>[
      pattern,
      pattern,
      pattern,
      ...?statuses,
    ];
    final rows = await database.rawQuery(
      '''
        SELECT id, stay_id, rent_period, amount_due, amount_paid, status
        FROM ${RentLocalSchema.tableRentRecords}
        WHERE ${where.join(' AND ')}
        ORDER BY due_date DESC
      ''',
      arguments,
    );

    return rows.map(
      (row) {
        final due = (row['amount_due'] as num).toDouble();
        final paid = (row['amount_paid'] as num).toDouble();
        return SearchResultEntity(
          id: row['id'] as int,
          type: SearchResultType.rent,
          title: 'Rent ${row['rent_period']} • Stay ${row['stay_id']}',
          subtitle:
              '${row['status']} • Due ${due.toStringAsFixed(2)} • Paid ${paid.toStringAsFixed(2)}',
        );
      },
    ).toList();
  }

  Future<List<SearchResultEntity>> _searchExpenses(
    Database database,
    String query,
  ) async {
    final pattern = '%$query%';
    final rows = await database.rawQuery(
      '''
        SELECT expenses.id, expenses.title, expenses.amount,
               expense_categories.name AS category_name
        FROM ${ExpenseLocalSchema.tableExpenses} AS expenses
        INNER JOIN ${ExpenseLocalSchema.tableExpenseCategories} AS expense_categories
          ON expense_categories.id = expenses.category_id
        WHERE expenses.title LIKE ? COLLATE NOCASE
           OR expense_categories.name LIKE ? COLLATE NOCASE
        ORDER BY expenses.expense_date DESC
      ''',
      <Object?>[pattern, pattern],
    );

    return rows
        .map(
          (row) => SearchResultEntity(
            id: row['id'] as int,
            type: SearchResultType.expense,
            title: row['title'] as String,
            subtitle:
                '${row['category_name']} • ${(row['amount'] as num).toStringAsFixed(2)}',
          ),
        )
        .toList();
  }

  String _tenantSubtitle(Map<String, Object?> row) {
    final details = <String>[row['phone_number'] as String];
    final guardianName = row['emergency_contact_name'] as String?;
    final guardianPhone = row['emergency_contact_phone'] as String?;
    if (guardianName != null && guardianName.isNotEmpty) {
      details.add(guardianName);
    }
    if (guardianPhone != null && guardianPhone.isNotEmpty) {
      details.add(guardianPhone);
    }
    return details.join(' • ');
  }
}
