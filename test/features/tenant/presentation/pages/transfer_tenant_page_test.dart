import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hostel_management/core/di/injection.dart';
import 'package:hostel_management/core/widgets/app_button.dart';
import 'package:hostel_management/features/hostel/domain/entities/hostel_entity.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_cubit.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_state.dart';
import 'package:hostel_management/features/room/domain/entities/bed_entity.dart';
import 'package:hostel_management/features/room/domain/entities/bed_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_entity.dart';
import 'package:hostel_management/features/room/domain/entities/room_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_type.dart';
import 'package:hostel_management/features/room/domain/repositories/bed_repository.dart';
import 'package:hostel_management/features/room/domain/repositories/room_repository.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_entity.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_status.dart';
import 'package:hostel_management/features/tenant/presentation/cubit/tenant_cubit.dart';
import 'package:hostel_management/features/tenant/presentation/cubit/tenant_state.dart';
import 'package:hostel_management/features/tenant/presentation/models/tenant_view_model.dart';
import 'package:hostel_management/features/tenant/presentation/pages/transfer_tenant_page.dart';

class FakeTenantCubit extends Cubit<TenantState> implements TenantCubit {
  FakeTenantCubit(super.initialState);
  bool transferCalled = false;

  @override
  Future<void> transferTenant(int tenantId,
      {required int oldBedId, required int newBedId}) async {
    transferCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHostelCubit extends Cubit<HostelState> implements HostelCubit {
  FakeHostelCubit(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRoomRepository implements RoomRepository {
  @override
  Future<List<RoomEntity>> getRoomsByHostelId(int hostelId) async {
    return [
      RoomEntity(
        id: 1,
        hostelId: 1,
        roomNumber: '101',
        floor: 'G',
        roomType: RoomType.double,
        numberOfBeds: 2,
        monthlyRent: 1000,
        status: RoomStatus.partiallyOccupied,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBedRepository implements BedRepository {
  @override
  Future<List<BedEntity>> getVacantBedsByRoomId(int roomId) async {
    return [
      BedEntity(
        id: 2,
        roomId: 1,
        bedNumber: 'B2',
        status: BedStatus.vacant,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )
    ];
  }

  @override
  Future<BedEntity?> getBedById(int id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeTenantCubit tenantCubit;
  late FakeHostelCubit hostelCubit;

  final testTenant = TenantEntity(
    id: 1,
    bedId: 1,
    fullName: 'John Doe',
    phoneNumber: '1234567890',
    checkInDate: DateTime.now(),
    status: TenantStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() async {
    await getIt.reset();
    getIt.registerLazySingleton<RoomRepository>(() => FakeRoomRepository());
    getIt.registerLazySingleton<BedRepository>(() => FakeBedRepository());

    tenantCubit = FakeTenantCubit(TenantState(
      status: TenantOperationStatus.loaded,
      viewModels: [
        TenantViewModel(
          tenant: testTenant,
          roomName: 'Room 101',
          bedName: 'Bed B1',
        )
      ],
    ));

    hostelCubit = FakeHostelCubit(HostelState(
      hostel: HostelEntity(
        id: 1,
        name: 'Test Hostel',
        address: 'Test',
        phone: '000',
        email: 'test@test.com',
        ownerName: 'Owner',
        ownerUserId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ));
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TenantCubit>.value(value: tenantCubit),
        BlocProvider<HostelCubit>.value(value: hostelCubit),
      ],
      child: MaterialApp(
        home: TransferTenantPage(tenant: testTenant),
      ),
    );
  }

  testWidgets('renders tenant name and resolved bed label (no raw ID)',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('John Doe'), findsOneWidget);
    // Shows resolved combined label, NOT raw ID text like 'Bed ID:'
    expect(find.textContaining('Room 101 · Bed B1'), findsOneWidget);
    expect(find.textContaining('Bed ID:'), findsNothing);
  });

  testWidgets('disables submit button until bed is selected', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final button = tester.widget<AppButton>(find.byType(AppButton));
    expect(button.onPressed, isNull);

    // Tap the bed tile
    await tester.tap(find.text('Bed B2'));
    await tester.pumpAndSettle();

    final enabledButton = tester.widget<AppButton>(find.byType(AppButton));
    expect(enabledButton.onPressed, isNotNull);
  });

  testWidgets('calls transferTenant when submit is pressed', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bed B2'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(tenantCubit.transferCalled, isTrue);
  });
}
