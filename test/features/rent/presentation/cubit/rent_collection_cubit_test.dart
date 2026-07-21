import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/rent/domain/constants/rent_status_constants.dart';
import 'package:hostel_management/features/rent/domain/entities/rent_collection_item_entity.dart';
import 'package:hostel_management/features/rent/domain/entities/rent_record_entity.dart';
import 'package:hostel_management/features/rent/domain/repositories/rent_collection_repository.dart';
import 'package:hostel_management/features/rent/domain/repositories/rent_repository.dart';
import 'package:hostel_management/features/rent/presentation/cubit/rent_collection/rent_collection_cubit.dart';
import 'package:hostel_management/features/rent/presentation/cubit/rent_collection/rent_collection_state.dart';

class FakeRentCollectionRepository implements RentCollectionRepository {
  List<RentCollectionItemEntity> items = [];
  bool throwError = false;

  @override
  Future<List<RentCollectionItemEntity>> getRentCollectionItems() async {
    if (throwError) throw Exception('Fetch failed');
    return items;
  }
}

class FakeRentRepository implements RentRepository {
  bool generateCalled = false;
  
  @override
  Future<int> generateNextBillingPeriods() async {
    generateCalled = true;
    return 0;
  }

  // Dummy implementations for remaining interface methods
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeRentCollectionRepository fakeCollectionRepo;
  late FakeRentRepository fakeRentRepo;
  late RentCollectionCubit cubit;

  setUp(() {
    fakeCollectionRepo = FakeRentCollectionRepository();
    fakeRentRepo = FakeRentRepository();
    cubit = RentCollectionCubit(fakeCollectionRepo, fakeRentRepo);
  });

  RentCollectionItemEntity createItem(int id, String status, double due, double paid, String tenantName) {
    return RentCollectionItemEntity(
      rentRecord: RentRecordEntity(
        id: id,
        stayId: 1,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        dueDate: DateTime.now(), // to ensure it overlaps for 'collected this month' calculation if paid
        generatedAt: DateTime.now(),
        amountDue: due,
        amountPaid: paid,
        status: status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      tenantId: 1,
      tenantName: tenantName,
      roomNumber: '101',
      bedNumber: 'A',
    );
  }

  test('initial state is RentCollectionInitial', () {
    expect(cubit.state, isA<RentCollectionInitial>());
  });

  test('load calls generateNextBillingPeriods and emits Loaded', () async {
    fakeCollectionRepo.items = [
      createItem(1, RentStatus.pending, 5000, 0, 'Alice'),
      createItem(2, RentStatus.paid, 5000, 5000, 'Bob'),
    ];

    expectLater(
      cubit.stream,
      emitsInOrder([
        isA<RentCollectionLoading>(),
        isA<RentCollectionLoaded>(),
      ]),
    );

    await cubit.load();
    expect(fakeRentRepo.generateCalled, isTrue);

    final state = cubit.state as RentCollectionLoaded;
    expect(state.items.length, 2);
    expect(state.totalPendingAmount, 5000);
    expect(state.pendingRecordsCount, 1);
  });

  test('setFilter filters items correctly', () async {
    fakeCollectionRepo.items = [
      createItem(1, RentStatus.pending, 5000, 0, 'Alice'),
      createItem(2, RentStatus.paid, 5000, 5000, 'Bob'),
      createItem(3, RentStatus.overdue, 5000, 0, 'Charlie'),
    ];
    await cubit.load();

    cubit.setFilter('pending');
    expect((cubit.state as RentCollectionLoaded).filteredItems.length, 1);
    expect((cubit.state as RentCollectionLoaded).filteredItems.first.tenantName, 'Alice');

    cubit.setFilter('paid');
    expect((cubit.state as RentCollectionLoaded).filteredItems.length, 1);
    expect((cubit.state as RentCollectionLoaded).filteredItems.first.tenantName, 'Bob');
  });

  test('setSearchQuery filters by tenant name', () async {
    fakeCollectionRepo.items = [
      createItem(1, RentStatus.pending, 5000, 0, 'Alice'),
      createItem(2, RentStatus.paid, 5000, 5000, 'Bob'),
    ];
    await cubit.load();

    cubit.setSearchQuery('ali');
    expect((cubit.state as RentCollectionLoaded).filteredItems.length, 1);
    expect((cubit.state as RentCollectionLoaded).filteredItems.first.tenantName, 'Alice');
  });
}
