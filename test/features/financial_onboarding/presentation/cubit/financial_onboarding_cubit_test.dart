import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/financial_onboarding/presentation/cubit/financial_onboarding_cubit.dart';
import 'package:hostel_management/features/financial_onboarding/presentation/cubit/financial_onboarding_state.dart';
import 'package:hostel_management/features/rent/domain/constants/rent_status_constants.dart';
import 'package:hostel_management/features/rent/domain/entities/deposit_entity.dart';
import 'package:hostel_management/features/rent/domain/entities/payment_entity.dart';
import 'package:hostel_management/features/rent/domain/entities/rent_record_entity.dart';
import 'package:hostel_management/features/rent/domain/entities/stay_entity.dart';
import 'package:hostel_management/features/rent/domain/repositories/rent_repository.dart';
import 'package:hostel_management/features/room/domain/entities/bed_entity.dart';
import 'package:hostel_management/features/room/domain/entities/bed_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_entity.dart';
import 'package:hostel_management/features/room/domain/entities/room_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_type.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_entity.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_registration_context.dart';
import 'package:hostel_management/features/tenant/domain/entities/tenant_status.dart';

class _FakeRentRepository implements RentRepository {
  final deposits = <DepositEntity>[];
  final payments = <PaymentEntity>[];

  @override
  Future<DepositEntity> createDeposit(DepositEntity deposit) async {
    deposits.add(deposit);
    return deposit;
  }

  @override
  Future<PaymentEntity> createPayment(PaymentEntity payment) async {
    payments.add(payment);
    return payment;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TenantRegistrationContext _context() {
  final now = DateTime(2026, 1, 1);
  final tenant = TenantEntity(
    id: 1,
    bedId: 1,
    fullName: 'Asha',
    phoneNumber: '9999999999',
    checkInDate: now,
    status: TenantStatus.active,
    createdAt: now,
    updatedAt: now,
  );
  final stay = StayEntity(
    id: 1,
    tenantId: 1,
    roomId: 1,
    bedId: 1,
    checkInDate: now,
    monthlyRentSnapshot: 5000,
    dailyRate: 166.67,
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
      floor: '1',
      roomType: RoomType.single,
      numberOfBeds: 1,
      monthlyRent: 5000,
      status: RoomStatus.partiallyOccupied,
      createdAt: now,
      updatedAt: now,
    ),
    bed: BedEntity(
      id: 1,
      roomId: 1,
      bedNumber: 'A',
      monthlyRent: 5000,
      status: BedStatus.occupied,
      createdAt: now,
      updatedAt: now,
    ),
    initialRentRecord: RentRecordEntity(
      id: 1,
      stayId: 1,
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      dueDate: now,
      generatedAt: now,
      amountDue: 5000,
      amountPaid: 0,
      status: RentStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

void main() {
  late _FakeRentRepository repository;
  late FinancialOnboardingCubit cubit;

  setUp(() {
    repository = _FakeRentRepository();
    cubit = FinancialOnboardingCubit(repository);
  });

  test('skip creates no financial transactions', () async {
    await cubit.save(
      context: _context(),
      depositAmount: 0,
      depositNotes: '',
      rentAmount: 0,
      rentNotes: '',
    );

    expect(repository.deposits, isEmpty);
    expect(repository.payments, isEmpty);
    expect(cubit.state.status, FinancialOnboardingStatus.success);
  });

  test('records held deposit and partial rent using existing repository calls', () async {
    cubit.setCollectDeposit(true);
    cubit.setDepositPaymentMethod(PaymentMethod.cash);
    cubit.setCollectRent(true);
    cubit.setRentPaymentMethod(PaymentMethod.upi);

    await cubit.save(
      context: _context(),
      depositAmount: 2000,
      depositNotes: 'Cash received at check-in',
      rentAmount: 1500,
      rentNotes: 'UPI reference',
    );

    expect(repository.deposits.single.status, DepositStatus.held);
    expect(repository.deposits.single.amount, 2000);
    expect(repository.deposits.single.paymentMethod, PaymentMethod.cash);
    expect(repository.deposits.single.notes, 'Cash received at check-in');
    expect(repository.payments.single.amount, 1500);
    expect(repository.payments.single.paymentMethod, PaymentMethod.upi);
    expect(cubit.state.status, FinancialOnboardingStatus.success);
  });

  test('rejects rent amounts above the outstanding rent', () async {
    cubit.setCollectRent(true);
    cubit.setRentPaymentMethod(PaymentMethod.cash);

    await cubit.save(
      context: _context(),
      depositAmount: 0,
      depositNotes: '',
      rentAmount: 5000.01,
      rentNotes: '',
    );

    expect(repository.payments, isEmpty);
    expect(cubit.state.status, FinancialOnboardingStatus.failure);
  });
}
