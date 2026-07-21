import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/room/domain/entities/bed_entity.dart';
import 'package:hostel_management/features/room/domain/entities/bed_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_entity.dart';
import 'package:hostel_management/features/room/domain/entities/room_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_type.dart';
import 'package:hostel_management/features/rent/domain/constants/rent_status_constants.dart';
import 'package:hostel_management/features/rent/domain/entities/rent_record_entity.dart';
import 'package:hostel_management/features/rent/domain/entities/stay_entity.dart';
import 'package:hostel_management/features/room/domain/repositories/bed_repository.dart';
import 'package:hostel_management/features/room/domain/repositories/room_repository.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_entity.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_registration_context.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_status.dart';
import 'package:hostel_management/features/tenant/domain/repositories/tenant_management_repository.dart';
import 'package:hostel_management/features/tenant/domain/repositories/tenant_repository.dart';
import 'package:hostel_management/features/tenant/presentation/cubit/tenant_cubit.dart';
import 'package:hostel_management/features/tenant/presentation/cubit/tenant_state.dart';

class FakeTenantRepository implements TenantRepository {
  List<TenantEntity> tenants = [];
  bool shouldFail = false;

  @override
  Future<List<TenantEntity>> getAllTenants() async {
    if (shouldFail) throw Exception('Load failed');
    return tenants;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTenantManagementRepository implements TenantManagementRepository {
  bool shouldFail = false;
  int callCount = 0;

  @override
  Future<TenantRegistrationContext> assignTenant(TenantEntity tenant) async {
    callCount++;
    if (shouldFail) throw Exception('Assign failed');
    final now = DateTime.now();
    final bed = BedEntity(
      id: tenant.bedId,
      roomId: 1,
      bedNumber: 'B${tenant.bedId}',
      monthlyRent: 5000,
      status: BedStatus.occupied,
      createdAt: now,
      updatedAt: now,
    );
    final stay = StayEntity(
      id: 1,
      tenantId: tenant.id ?? 1,
      roomId: bed.roomId,
      bedId: tenant.bedId ?? 1,
      checkInDate: tenant.checkInDate,
      monthlyRentSnapshot: bed.monthlyRent,
      dailyRate: bed.monthlyRent / 30,
      status: StayStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    return TenantRegistrationContext(
      tenant: tenant,
      stay: stay,
      room: RoomEntity(
        id: 1,
        hostelId: 1,
        roomNumber: '101',
        floor: 'G',
        roomType: RoomType.single,
        numberOfBeds: 1,
        monthlyRent: bed.monthlyRent,
        status: RoomStatus.partiallyOccupied,
        createdAt: now,
        updatedAt: now,
      ),
      bed: bed,
      initialRentRecord: RentRecordEntity(
        id: 1,
        stayId: stay.id!,
        startDate: tenant.checkInDate,
        endDate: tenant.checkInDate.add(const Duration(days: 30)),
        dueDate: tenant.checkInDate,
        generatedAt: now,
        amountDue: bed.monthlyRent,
        amountPaid: 0,
        status: RentStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<TenantEntity> updateTenantDetails(TenantEntity tenant) async {
    callCount++;
    if (shouldFail) throw Exception('Update failed');
    return tenant;
  }

  @override
  Future<void> deleteTenant(int tenantId, {int? bedId}) async {
    callCount++;
    if (shouldFail) throw Exception('Delete failed');
  }

  @override
  Future<TenantEntity> checkOutTenant(int tenantId,
      {required int bedId}) async {
    callCount++;
    if (shouldFail) throw Exception('CheckOut failed');
    final now = DateTime.now();
    return TenantEntity(
      id: tenantId,
      bedId: null,
      fullName: 'Mock',
      phoneNumber: '000',
      checkInDate: now,
      status: TenantStatus.checkedOut,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<TenantEntity> transferTenant(
    int tenantId, {
    required int oldBedId,
    required int newBedId,
  }) async {
    callCount++;
    if (shouldFail) throw Exception('Transfer failed');
    final now = DateTime.now();
    return TenantEntity(
      id: tenantId,
      bedId: newBedId,
      fullName: 'Mock',
      phoneNumber: '000',
      checkInDate: now,
      status: TenantStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class FakeRoomRepository implements RoomRepository {
  @override
  Future<RoomEntity?> getRoomById(int id) async => null; // no room resolution in unit test

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBedRepository implements BedRepository {
  @override
  Future<BedEntity?> getBedById(int id) async {
    return BedEntity(
      id: id,
      roomId: 1,
      bedNumber: 'B$id', monthlyRent: 5000,
      status: BedStatus.occupied,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeTenantRepository tenantRepo;
  late FakeTenantManagementRepository managementRepo;
  late FakeRoomRepository roomRepo;
  late FakeBedRepository bedRepo;
  late TenantCubit cubit;

  final testTenant = TenantEntity(
    id: 1,
    bedId: 1,
    fullName: 'Alice',
    phoneNumber: '111',
    checkInDate: DateTime.now(),
    status: TenantStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    tenantRepo = FakeTenantRepository();
    managementRepo = FakeTenantManagementRepository();
    roomRepo = FakeRoomRepository();
    bedRepo = FakeBedRepository();
    cubit = TenantCubit(tenantRepo, managementRepo, roomRepo, bedRepo);
  });

  group('loadTenants', () {
    test('emits loading then loaded with tenants and viewModels', () async {
      tenantRepo.tenants = [testTenant];

      await cubit.loadTenants();

      expect(cubit.state.status, TenantOperationStatus.loaded);
      expect(cubit.state.tenants, [testTenant]);
      expect(cubit.state.viewModels.length, 1);
      expect(cubit.state.viewModels.first.bedName, 'Bed B1');
      expect(cubit.state.filteredTenants, [testTenant]);
    });

    test('emits loading then failure on error', () async {
      tenantRepo.shouldFail = true;

      final expectedStates = [
        const TenantState(status: TenantOperationStatus.loading),
        const TenantState(
          status: TenantOperationStatus.failure,
          errorMessage: 'Exception: Load failed',
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.loadTenants();
    });
  });

  group('search', () {
    test('filters list by name and phone case-insensitive', () async {
      tenantRepo.tenants = [
        testTenant,
        TenantEntity(
          id: 2,
          bedId: 2,
          fullName: 'Bob',
          phoneNumber: '222',
          checkInDate: DateTime.now(),
          status: TenantStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      await cubit.loadTenants();

      cubit.search('ali');
      expect(cubit.state.filteredTenants.length, 1);
      expect(cubit.state.filteredTenants.first.fullName, 'Alice');
      expect(cubit.state.filteredViewModels.length, 1);

      cubit.search('222');
      expect(cubit.state.filteredTenants.length, 1);
      expect(cubit.state.filteredTenants.first.fullName, 'Bob');
      expect(cubit.state.filteredViewModels.length, 1);
    });
  });

  group('setSearchActive', () {
    test('sets isSearchActive correctly', () async {
      tenantRepo.tenants = [testTenant];
      await cubit.loadTenants();

      cubit.setSearchActive(true);
      expect(cubit.state.isSearchActive, true);

      cubit.setSearchActive(false);
      expect(cubit.state.isSearchActive, false);
    });

    test('clears search query when deactivating', () async {
      tenantRepo.tenants = [testTenant];
      await cubit.loadTenants();

      cubit.search('ali');
      cubit.setSearchActive(false);

      expect(cubit.state.searchQuery, '');
    });
  });

  group('mutations', () {
    test('createTenant emits creating then reloads', () async {
      final expectedStates = [
        const TenantState(status: TenantOperationStatus.creating),
        const TenantState(status: TenantOperationStatus.loading),
        isA<TenantState>().having(
            (s) => s.status, 'status', TenantOperationStatus.loaded),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.createTenant(testTenant);
      expect(managementRepo.callCount, 1);
    });

    test('updateTenant emits updating then reloads', () async {
      final expectedStates = [
        const TenantState(status: TenantOperationStatus.updating),
        const TenantState(status: TenantOperationStatus.loading),
        isA<TenantState>().having(
            (s) => s.status, 'status', TenantOperationStatus.loaded),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.updateTenant(testTenant);
      expect(managementRepo.callCount, 1);
    });

    test('deleteTenant emits deleting then reloads', () async {
      final expectedStates = [
        const TenantState(status: TenantOperationStatus.deleting),
        const TenantState(status: TenantOperationStatus.loading),
        isA<TenantState>().having(
            (s) => s.status, 'status', TenantOperationStatus.loaded),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.deleteTenant(1, bedId: 1);
      expect(managementRepo.callCount, 1);
    });

    test('checkOutTenant emits checkingOut then reloads', () async {
      final expectedStates = [
        const TenantState(status: TenantOperationStatus.checkingOut),
        const TenantState(status: TenantOperationStatus.loading),
        isA<TenantState>().having(
            (s) => s.status, 'status', TenantOperationStatus.loaded),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.checkOutTenant(1, bedId: 1);
      expect(managementRepo.callCount, 1);
    });

    test('transferTenant emits transferring then reloads', () async {
      final expectedStates = [
        const TenantState(status: TenantOperationStatus.transferring),
        const TenantState(status: TenantOperationStatus.loading),
        isA<TenantState>().having(
            (s) => s.status, 'status', TenantOperationStatus.loaded),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.transferTenant(1, oldBedId: 1, newBedId: 2);
      expect(managementRepo.callCount, 1);
    });

    test('mutations emit failure on repository exception', () async {
      managementRepo.shouldFail = true;

      final expectedStates = [
        const TenantState(status: TenantOperationStatus.creating),
        const TenantState(
          status: TenantOperationStatus.failure,
          errorMessage: 'Exception: Assign failed',
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.createTenant(testTenant);
    });
  });
}
