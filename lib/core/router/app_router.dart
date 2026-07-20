import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/presentation/main_shell_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'app_routes.dart';

import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/auth/presentation/pages/owner_sign_up_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/pin_setup_page.dart';
import '../../features/hostel/presentation/pages/hostel_setup_page.dart';
import '../../features/room/domain/entities/room_entity.dart';
import '../../features/room/presentation/cubit/room_cubit.dart';
import '../../features/room/presentation/pages/room_management_page.dart';
import '../../features/room/presentation/pages/add_room_page.dart';
import '../../features/room/presentation/pages/edit_room_page.dart';
import '../../features/room/presentation/pages/bed_management_page.dart';
import '../../features/room/presentation/cubit/bed_cubit.dart';
import '../../features/tenant/domain/entities/tenant_entity.dart';
import '../../features/tenant/presentation/cubit/tenant_cubit.dart';
import '../../features/tenant/presentation/pages/add_tenant_page.dart';
import '../../features/tenant/presentation/pages/edit_tenant_page.dart';
import '../../features/tenant/presentation/pages/tenant_management_page.dart';
import '../../features/tenant/presentation/pages/transfer_tenant_page.dart';
import '../../features/rent/domain/entities/stay_entity.dart';
import '../../features/rent/presentation/cubit/stay/stay_cubit.dart';
import '../../features/rent/presentation/pages/stay/add_edit_stay_page.dart';
import '../../features/rent/presentation/pages/stay/stay_details_page.dart';
import '../../features/rent/presentation/pages/stay/stay_list_page.dart';
import '../../features/rent/domain/entities/rent_record_entity.dart';
import '../../features/rent/presentation/cubit/rent_record/rent_record_cubit.dart';
import '../../features/rent/presentation/pages/rent_record/add_edit_rent_record_page.dart';
import '../../features/rent/presentation/pages/rent_record/rent_record_details_page.dart';
import '../../features/rent/presentation/pages/rent_record/rent_record_list_page.dart';
import '../../features/rent/domain/entities/payment_entity.dart';
import '../../features/rent/presentation/cubit/payment/payment_cubit.dart';
import '../../features/rent/presentation/pages/payment/add_edit_payment_page.dart';
import '../../features/rent/presentation/pages/payment/payment_details_page.dart';
import '../../features/rent/presentation/pages/payment/payment_list_page.dart';
import '../../features/rent/domain/entities/receipt_entity.dart';
import '../../features/rent/presentation/cubit/receipt/receipt_cubit.dart';
import '../../features/rent/presentation/pages/receipt/add_edit_receipt_page.dart';
import '../../features/rent/presentation/pages/receipt/receipt_details_page.dart';
import '../../features/rent/presentation/pages/receipt/receipt_list_page.dart';
import '../../features/rent/domain/entities/deposit_entity.dart';
import '../../features/rent/presentation/cubit/deposit/deposit_cubit.dart';
import '../../features/rent/presentation/pages/deposit/add_edit_deposit_page.dart';
import '../../features/rent/presentation/pages/deposit/deposit_details_page.dart';
import '../../features/rent/presentation/pages/deposit/deposit_list_page.dart';
import '../../features/rent/domain/entities/damage_charge_entity.dart';
import '../../features/rent/presentation/cubit/damage_charge/damage_charge_cubit.dart';
import '../../features/rent/presentation/pages/damage_charge/add_edit_damage_charge_page.dart';
import '../../features/rent/presentation/pages/damage_charge/damage_charge_details_page.dart';
import '../../features/rent/presentation/pages/damage_charge/damage_charge_list_page.dart';
import '../../features/rent/domain/entities/checkout_settlement_entity.dart';
import '../../features/rent/presentation/cubit/checkout/checkout_cubit.dart';
import '../../features/rent/presentation/pages/checkout/add_edit_checkout_page.dart';
import '../../features/rent/presentation/pages/checkout/checkout_details_page.dart';
import '../../features/rent/presentation/pages/checkout/checkout_list_page.dart';
import '../../features/expense/domain/entities/expense_entity.dart';
import '../../features/expense/presentation/cubit/expense/expense_cubit.dart';
import '../../features/expense/presentation/cubit/expense_category/expense_category_cubit.dart';
import '../../features/expense/presentation/pages/expense/add_expense_page.dart';
import '../../features/expense/presentation/pages/expense/edit_expense_page.dart';
import '../../features/expense/presentation/pages/expense/expense_list_page.dart';
import '../../features/expense/presentation/pages/expense_category/expense_category_list_page.dart';
import '../../features/search/presentation/cubit/search_cubit.dart';
import '../../features/search/presentation/pages/search_page.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splashPath,
    errorBuilder: (context, state) => const _RouteErrorPage(),
    routes: [
      GoRoute(
        name: AppRoutes.splashName,
        path: AppRoutes.splashPath,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        name: AppRoutes.roleSelectionName,
        path: AppRoutes.roleSelectionPath,
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.ownerLoginPath,
        name: AppRoutes.ownerLoginName,
        builder: (context, state) => const LoginPage(role: UserRole.owner),
      ),
      GoRoute(
        path: AppRoutes.managerLoginPath,
        name: AppRoutes.managerLoginName,
        builder: (context, state) => const LoginPage(role: UserRole.manager),
      ),
      GoRoute(
        name: AppRoutes.ownerSignUpName,
        path: AppRoutes.ownerSignUpPath,
        builder: (context, state) => const OwnerSignUpPage(),
      ),
      GoRoute(
        name: AppRoutes.pinSetupName,
        path: AppRoutes.pinSetupPath,
        builder: (context, state) => const PinSetupPage(),
      ),
      GoRoute(
        name: AppRoutes.hostelSetupName,
        path: AppRoutes.hostelSetupPath,
        builder: (context, state) => const HostelSetupPage(),
      ),
      // -----------------------------------------------------------------------
      // Main Application Shell
      // -----------------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => getIt<DashboardCubit>()),
              BlocProvider(create: (_) => getIt<RoomCubit>()),
              BlocProvider(create: (_) => getIt<TenantCubit>()),
              BlocProvider(create: (_) => getIt<StayCubit>()),
              BlocProvider(create: (_) => getIt<RentRecordCubit>()),
              BlocProvider(create: (_) => getIt<PaymentCubit>()),
              BlocProvider(create: (_) => getIt<ReceiptCubit>()),
              BlocProvider(create: (_) => getIt<DepositCubit>()),
              BlocProvider(create: (_) => getIt<DamageChargeCubit>()),
              BlocProvider(create: (_) => getIt<CheckoutCubit>()),
              BlocProvider(create: (_) => getIt<ExpenseCategoryCubit>()),
              BlocProvider(create: (_) => getIt<ExpenseCubit>()),
              BlocProvider(create: (_) => getIt<SearchCubit>()),
            ],
            child: MainShellPage(navigationShell: navigationShell),
          );
        },
        branches: [
          // Branch 0: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.searchName,
                path: AppRoutes.searchPath,
                builder: (context, state) => const SearchPage(),
              ),
            ],
          ),
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.homeName,
                path: AppRoutes.homePath,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          // Branch 1: Room Management
          StatefulShellBranch(
            routes: [
              ShellRoute(
                builder: (context, state, child) {
                  return child;
                },
                routes: [
                  GoRoute(
                    name: AppRoutes.roomManagementName,
                    path: AppRoutes.roomManagementPath,
                    builder: (context, state) => const RoomManagementPage(),
                    routes: [
                      GoRoute(
                        name: AppRoutes.addRoomName,
                        path: AppRoutes.addRoomPath,
                        builder: (context, state) => const AddRoomPage(),
                      ),
                      GoRoute(
                        name: AppRoutes.editRoomName,
                        path: AppRoutes.editRoomPath,
                        builder: (context, state) {
                          final room = state.extra as RoomEntity?;
                          return EditRoomPage(room: room);
                        },
                      ),
                      GoRoute(
                        name: AppRoutes.bedManagementName,
                        path: AppRoutes.bedManagementPath,
                        builder: (context, state) {
                          final roomIdStr =
                              state.pathParameters['roomId'] ?? '';
                          final room = state.extra as RoomEntity?;
                          return BlocProvider(
                            create: (_) => getIt<BedCubit>(),
                            child: BedManagementPage(
                                roomIdStr: roomIdStr, room: room),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Tenant Management
          StatefulShellBranch(
            routes: [
              ShellRoute(
                builder: (context, state, child) {
                  return child;
                },
                routes: [
                  GoRoute(
                    name: AppRoutes.tenantManagementName,
                    path: AppRoutes.tenantManagementPath,
                    builder: (context, state) => const TenantManagementPage(),
                    routes: [
                      GoRoute(
                        name: AppRoutes.addTenantName,
                        path: AppRoutes.addTenantPath,
                        builder: (context, state) => const AddTenantPage(),
                      ),
                      GoRoute(
                        name: AppRoutes.editTenantName,
                        path: AppRoutes.editTenantPath,
                        builder: (context, state) {
                          final tenant = state.extra as TenantEntity?;
                          return EditTenantPage(tenant: tenant);
                        },
                      ),
                      GoRoute(
                        name: AppRoutes.transferTenantName,
                        path: AppRoutes.transferTenantPath,
                        builder: (context, state) {
                          final tenant = state.extra as TenantEntity?;
                          return TransferTenantPage(tenant: tenant);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: Stay Management
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.stayManagementName,
                path: AppRoutes.stayManagementPath,
                builder: (context, state) => const StayListPage(),
                routes: [
                  GoRoute(
                    name: AppRoutes.addStayName,
                    path: AppRoutes.addStayPath,
                    builder: (context, state) => const AddEditStayPage(),
                  ),
                  GoRoute(
                    name: AppRoutes.stayDetailsName,
                    path: AppRoutes.stayDetailsPath,
                    builder: (context, state) => StayDetailsPage(
                      stay: state.extra as StayEntity?,
                    ),
                  ),
                  GoRoute(
                    name: AppRoutes.editStayName,
                    path: AppRoutes.editStayPath,
                    builder: (context, state) => AddEditStayPage(
                      stay: state.extra as StayEntity?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch 9: Checkout Settlement Management
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.checkoutManagementName,
                path: AppRoutes.checkoutManagementPath,
                builder: (context, state) => const CheckoutListPage(),
                routes: [
                  GoRoute(
                      name: AppRoutes.addCheckoutName,
                      path: AppRoutes.addCheckoutPath,
                      builder: (context, state) => const AddEditCheckoutPage()),
                  GoRoute(
                      name: AppRoutes.checkoutDetailsName,
                      path: AppRoutes.checkoutDetailsPath,
                      builder: (context, state) => CheckoutDetailsPage(
                          settlement:
                              state.extra as CheckoutSettlementEntity?)),
                  GoRoute(
                      name: AppRoutes.editCheckoutName,
                      path: AppRoutes.editCheckoutPath,
                      builder: (context, state) => AddEditCheckoutPage(
                          settlement:
                              state.extra as CheckoutSettlementEntity?)),
                ],
              ),
            ],
          ),
          // Branch 8: Damage Charge Management
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.damageChargeManagementName,
                path: AppRoutes.damageChargeManagementPath,
                builder: (context, state) => const DamageChargeListPage(),
                routes: [
                  GoRoute(
                      name: AppRoutes.addDamageChargeName,
                      path: AppRoutes.addDamageChargePath,
                      builder: (context, state) =>
                          const AddEditDamageChargePage()),
                  GoRoute(
                      name: AppRoutes.damageChargeDetailsName,
                      path: AppRoutes.damageChargeDetailsPath,
                      builder: (context, state) => DamageChargeDetailsPage(
                          damageCharge: state.extra as DamageChargeEntity?)),
                  GoRoute(
                      name: AppRoutes.editDamageChargeName,
                      path: AppRoutes.editDamageChargePath,
                      builder: (context, state) => AddEditDamageChargePage(
                          damageCharge: state.extra as DamageChargeEntity?)),
                ],
              ),
            ],
          ),
          // Branch 7: Deposit Management
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.depositManagementName,
                path: AppRoutes.depositManagementPath,
                builder: (context, state) => const DepositListPage(),
                routes: [
                  GoRoute(
                      name: AppRoutes.addDepositName,
                      path: AppRoutes.addDepositPath,
                      builder: (context, state) => const AddEditDepositPage()),
                  GoRoute(
                      name: AppRoutes.depositDetailsName,
                      path: AppRoutes.depositDetailsPath,
                      builder: (context, state) => DepositDetailsPage(
                          deposit: state.extra as DepositEntity?)),
                  GoRoute(
                      name: AppRoutes.editDepositName,
                      path: AppRoutes.editDepositPath,
                      builder: (context, state) => AddEditDepositPage(
                          deposit: state.extra as DepositEntity?)),
                ],
              ),
            ],
          ),
          // Branch 6: Receipt Management
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.receiptManagementName,
                path: AppRoutes.receiptManagementPath,
                builder: (context, state) => const ReceiptListPage(),
                routes: [
                  GoRoute(
                      name: AppRoutes.addReceiptName,
                      path: AppRoutes.addReceiptPath,
                      builder: (context, state) => const AddEditReceiptPage()),
                  GoRoute(
                      name: AppRoutes.receiptDetailsName,
                      path: AppRoutes.receiptDetailsPath,
                      builder: (context, state) => ReceiptDetailsPage(
                          receipt: state.extra as ReceiptEntity?)),
                  GoRoute(
                      name: AppRoutes.editReceiptName,
                      path: AppRoutes.editReceiptPath,
                      builder: (context, state) => AddEditReceiptPage(
                          receipt: state.extra as ReceiptEntity?)),
                ],
              ),
            ],
          ),
          // Branch 5: Payment Management
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.paymentManagementName,
                path: AppRoutes.paymentManagementPath,
                builder: (context, state) => const PaymentListPage(),
                routes: [
                  GoRoute(
                    name: AppRoutes.addPaymentName,
                    path: AppRoutes.addPaymentPath,
                    builder: (context, state) => const AddEditPaymentPage(),
                  ),
                  GoRoute(
                    name: AppRoutes.paymentDetailsName,
                    path: AppRoutes.paymentDetailsPath,
                    builder: (context, state) => PaymentDetailsPage(
                      payment: state.extra as PaymentEntity?,
                    ),
                  ),
                  GoRoute(
                    name: AppRoutes.editPaymentName,
                    path: AppRoutes.editPaymentPath,
                    builder: (context, state) => AddEditPaymentPage(
                      payment: state.extra as PaymentEntity?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch 4: Rent Record Management
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.rentRecordManagementName,
                path: AppRoutes.rentRecordManagementPath,
                builder: (context, state) => const RentRecordListPage(),
                routes: [
                  GoRoute(
                    name: AppRoutes.addRentRecordName,
                    path: AppRoutes.addRentRecordPath,
                    builder: (context, state) => const AddEditRentRecordPage(),
                  ),
                  GoRoute(
                    name: AppRoutes.rentRecordDetailsName,
                    path: AppRoutes.rentRecordDetailsPath,
                    builder: (context, state) => RentRecordDetailsPage(
                      record: state.extra as RentRecordEntity?,
                    ),
                  ),
                  GoRoute(
                    name: AppRoutes.editRentRecordName,
                    path: AppRoutes.editRentRecordPath,
                    builder: (context, state) => AddEditRentRecordPage(
                      record: state.extra as RentRecordEntity?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch 10: Expense Management
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.expenseManagementName,
                path: AppRoutes.expenseManagementPath,
                builder: (context, state) => const ExpenseListPage(),
                routes: [
                  GoRoute(
                    name: AppRoutes.expenseCategoryManagementName,
                    path: AppRoutes.expenseCategoryManagementPath,
                    builder: (context, state) =>
                        const ExpenseCategoryListPage(),
                  ),
                  GoRoute(
                    name: AppRoutes.addExpenseName,
                    path: AppRoutes.addExpensePath,
                    builder: (context, state) => const AddExpensePage(),
                  ),
                  GoRoute(
                    name: AppRoutes.editExpenseName,
                    path: AppRoutes.editExpensePath,
                    builder: (context, state) => EditExpensePage(
                      expense: state.extra as ExpenseEntity,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.goNamed(AppRoutes.homeName),
                child: const Text('Go to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
