import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hostel_management/features/room/presentation/cubit/room_cubit.dart';
import 'package:hostel_management/features/room/presentation/cubit/room_state.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_entity.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_status.dart';
import 'package:hostel_management/features/tenant/presentation/cubit/tenant_cubit.dart';
import 'package:hostel_management/features/tenant/presentation/cubit/tenant_state.dart';
import 'package:hostel_management/features/tenant/presentation/pages/tenant_management_page.dart';
import 'package:hostel_management/core/widgets/app_loading_indicator.dart';

// Fake implementations for tests
class FakeTenantCubit extends Cubit<TenantState> implements TenantCubit {
  FakeTenantCubit(super.initialState);

  @override
  Future<void> loadTenants() async {}
  @override
  Future<void> search(String query) async {
    // Basic fake search
    final filtered = state.tenants.where((t) => t.fullName.contains(query)).toList();
    emit(state.copyWith(filteredTenants: filtered));
  }
  @override
  Future<void> createTenant(TenantEntity tenant) async {}
  @override
  Future<void> updateTenant(TenantEntity tenant) async {}
  @override
  Future<void> deleteTenant(int tenantId, {required int bedId}) async {}
  @override
  Future<void> checkOutTenant(int tenantId, {required int bedId}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRoomCubit extends Cubit<RoomState> implements RoomCubit {
  FakeRoomCubit(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeTenantCubit tenantCubit;
  late FakeRoomCubit roomCubit;

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

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TenantCubit>.value(value: tenantCubit),
        BlocProvider<RoomCubit>.value(value: roomCubit),
      ],
      child: MaterialApp(
        home: const TenantManagementPage(),
      ),
    );
  }

  setUp(() {
    tenantCubit = FakeTenantCubit(const TenantState());
    roomCubit = FakeRoomCubit(const RoomState());
  });

  testWidgets('shows loading indicator when loading', (tester) async {
    tenantCubit.emit(const TenantState(status: TenantOperationStatus.loading));
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when no tenants', (tester) async {
    tenantCubit.emit(const TenantState(status: TenantOperationStatus.loaded));
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.text('No tenants yet'), findsOneWidget);
  });

  testWidgets('displays tenant in list', (tester) async {
    tenantCubit.emit(TenantState(
      status: TenantOperationStatus.loaded,
      tenants: [testTenant],
      filteredTenants: [testTenant],
    ));
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
  });

  testWidgets('search filters list', (tester) async {
    tenantCubit.emit(TenantState(
      status: TenantOperationStatus.loaded,
      tenants: [testTenant],
      filteredTenants: [testTenant],
    ));
    await tester.pumpWidget(createWidgetUnderTest());

    // Tap search icon
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    // Type query
    await tester.enterText(find.byType(TextField), 'John');
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
  });
}
