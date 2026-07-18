import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_entity.dart';
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
  Future<TenantEntity> assignTenant(TenantEntity tenant) async {
    callCount++;
    if (shouldFail) throw Exception('Assign failed');
    return tenant;
  }

  @override
  Future<TenantEntity> updateTenantDetails(TenantEntity tenant) async {
    callCount++;
    if (shouldFail) throw Exception('Update failed');
    return tenant;
  }

  @override
  Future<void> deleteTenant(int tenantId, {required int bedId}) async {
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
      bedId: bedId,
      fullName: 'Mock',
      phoneNumber: '000',
      checkInDate: now,
      status: TenantStatus.checkedOut,
      createdAt: now,
      updatedAt: now,
    );
  }
}

void main() {
  late FakeTenantRepository tenantRepo;
  late FakeTenantManagementRepository managementRepo;
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
    cubit = TenantCubit(tenantRepo, managementRepo);
  });

  group('loadTenants', () {
    test('emits loading then loaded with tenants', () async {
      tenantRepo.tenants = [testTenant];

      final expectedStates = [
        const TenantState(status: TenantOperationStatus.loading),
        TenantState(
          status: TenantOperationStatus.loaded,
          tenants: [testTenant],
          filteredTenants: [testTenant],
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.loadTenants();
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

      cubit.search('222');
      expect(cubit.state.filteredTenants.length, 1);
      expect(cubit.state.filteredTenants.first.fullName, 'Bob');
    });
  });

  group('mutations', () {
    test('createTenant emits creating then reloads', () async {
      final expectedStates = [
        const TenantState(status: TenantOperationStatus.creating),
        const TenantState(status: TenantOperationStatus.loading),
        const TenantState(status: TenantOperationStatus.loaded),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.createTenant(testTenant);
      expect(managementRepo.callCount, 1);
    });

    test('updateTenant emits updating then reloads', () async {
      final expectedStates = [
        const TenantState(status: TenantOperationStatus.updating),
        const TenantState(status: TenantOperationStatus.loading),
        const TenantState(status: TenantOperationStatus.loaded),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.updateTenant(testTenant);
      expect(managementRepo.callCount, 1);
    });

    test('deleteTenant emits deleting then reloads', () async {
      final expectedStates = [
        const TenantState(status: TenantOperationStatus.deleting),
        const TenantState(status: TenantOperationStatus.loading),
        const TenantState(status: TenantOperationStatus.loaded),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.deleteTenant(1, bedId: 1);
      expect(managementRepo.callCount, 1);
    });

    test('checkOutTenant emits checkingOut then reloads', () async {
      final expectedStates = [
        const TenantState(status: TenantOperationStatus.checkingOut),
        const TenantState(status: TenantOperationStatus.loading),
        const TenantState(status: TenantOperationStatus.loaded),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));
      await cubit.checkOutTenant(1, bedId: 1);
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
