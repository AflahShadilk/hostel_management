import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hostel_management/features/tenant/domain/entities/tenant_entity.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_status.dart';
import 'package:hostel_management/features/tenant/presentation/cubit/tenant_cubit.dart';
import 'package:hostel_management/features/tenant/presentation/cubit/tenant_state.dart';
import 'package:hostel_management/features/tenant/presentation/models/tenant_view_model.dart';
import 'package:hostel_management/features/tenant/presentation/pages/tenant_management_page.dart';
import 'package:hostel_management/core/widgets/app_loading_indicator.dart';

class FakeTenantCubit extends Cubit<TenantState> implements TenantCubit {
  FakeTenantCubit(super.initialState);

  @override
  Future<void> loadTenants() async {}

  @override
  void search(String query) {
    final filtered = state.tenants
        .where((t) => t.fullName.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final filteredVMs = state.viewModels
        .where((vm) =>
            vm.tenant.fullName.toLowerCase().contains(query.toLowerCase()))
        .toList();
    emit(state.copyWith(
      searchQuery: query,
      filteredTenants: filtered,
      filteredViewModels: filteredVMs,
    ));
  }

  @override
  void setSearchActive(bool active) {
    emit(state.copyWith(isSearchActive: active));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeTenantCubit tenantCubit;

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

  final testViewModel = TenantViewModel(
    tenant: testTenant,
    roomName: 'Room 101',
    bedName: 'Bed B1',
  );

  Widget createWidgetUnderTest() {
    return BlocProvider<TenantCubit>.value(
      value: tenantCubit,
      child: const MaterialApp(
        home: TenantManagementPage(),
      ),
    );
  }

  setUp(() {
    tenantCubit = FakeTenantCubit(const TenantState());
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

  testWidgets('displays tenant from viewModel', (tester) async {
    tenantCubit.emit(TenantState(
      status: TenantOperationStatus.loaded,
      tenants: [testTenant],
      filteredTenants: [testTenant],
      viewModels: [testViewModel],
      filteredViewModels: [testViewModel],
    ));
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    // Resolved business values — no raw IDs shown
    expect(find.text('Room 101'), findsOneWidget);
    expect(find.text('Bed B1'), findsOneWidget);
  });

  testWidgets('search filters list via cubit (no setState)', (tester) async {
    tenantCubit.emit(TenantState(
      status: TenantOperationStatus.loaded,
      tenants: [testTenant],
      filteredTenants: [testTenant],
      viewModels: [testViewModel],
      filteredViewModels: [testViewModel],
    ));
    await tester.pumpWidget(createWidgetUnderTest());

    // Tap search icon — calls setSearchActive(true) on cubit, no setState
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'John');
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
  });
}
