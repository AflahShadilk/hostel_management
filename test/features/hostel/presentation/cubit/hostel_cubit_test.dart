import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/features/hostel/domain/entities/hostel_entity.dart';
import 'package:hostel_management/features/hostel/domain/repositories/hostel_repository.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_cubit.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_status.dart';

// ---------------------------------------------------------------------------
// Hand-written fake repository
// ---------------------------------------------------------------------------

class FakeHostelRepository implements HostelRepository {
  HostelEntity? _stored;
  bool createFails = false;
  bool updateFails = false;
  bool getFails = false;
  int _idCounter = 1;

  void seed(HostelEntity entity) => _stored = entity;

  @override
  Future<HostelEntity> createHostel(HostelEntity hostel) async {
    if (createFails) throw Exception('DB error');
    _stored = HostelEntity(
      id: _idCounter++,
      name: hostel.name,
      logoPath: hostel.logoPath,
      address: hostel.address,
      phone: hostel.phone,
      email: hostel.email,
      ownerName: hostel.ownerName,
      gstNumber: hostel.gstNumber,
      website: hostel.website,
      ownerUserId: hostel.ownerUserId,
      createdAt: hostel.createdAt,
      updatedAt: DateTime.now(),
    );
    return _stored!;
  }

  @override
  Future<HostelEntity?> getHostelById(int id) async {
    if (getFails) throw Exception('DB error');
    return _stored?.id == id ? _stored : null;
  }

  @override
  Future<HostelEntity?> getHostelByOwnerUserId(int ownerUserId) async {
    if (getFails) throw Exception('DB error');
    return _stored?.ownerUserId == ownerUserId ? _stored : null;
  }

  @override
  Future<bool> hasHostelForOwner(int ownerUserId) async {
    return _stored?.ownerUserId == ownerUserId;
  }

  @override
  Future<void> updateHostel(HostelEntity hostel) async {
    if (updateFails) throw Exception('DB error');
    _stored = hostel;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

HostelEntity _seededHostel({int ownerUserId = 1}) => HostelEntity(
      id: 1,
      name: 'Sunrise Hostel',
      address: '42 Baker Street',
      phone: '123456789',
      email: 'seed@hostel.com',
      ownerName: 'Seed Owner',
      ownerUserId: ownerUserId,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeHostelRepository repo;
  late HostelCubit cubit;

  setUp(() {
    repo = FakeHostelRepository();
    cubit = HostelCubit(repo);
  });

  tearDown(() => cubit.close());

  // -------------------------------------------------------------------------
  // checkHostelSetup
  // -------------------------------------------------------------------------

  group('HostelCubit checkHostelSetup', () {
    test('emits configured when hostel exists', () async {
      repo.seed(_seededHostel());

      await cubit.checkHostelSetup(1);

      expect(cubit.state.status, HostelStatus.configured);
      expect(cubit.state.hostel, isNotNull);
      expect(cubit.state.hostel!.name, 'Sunrise Hostel');
    });

    test('emits notConfigured when no hostel exists', () async {
      await cubit.checkHostelSetup(1);

      expect(cubit.state.status, HostelStatus.notConfigured);
      expect(cubit.state.hostel, isNull);
    });

    test('emits failure with safe message on repository error', () async {
      repo.getFails = true;

      await cubit.checkHostelSetup(1);

      expect(cubit.state.status, HostelStatus.failure);
      expect(cubit.state.errorMessage,
          'Unable to load hostel information. Please try again.');
    });

    test('is a no-op when ownerUserId is non-positive', () async {
      await cubit.checkHostelSetup(0);

      expect(cubit.state.status, HostelStatus.initial);
    });
  });

  // -------------------------------------------------------------------------
  // createHostel
  // -------------------------------------------------------------------------

  group('HostelCubit createHostel', () {
    test('emits success with persisted entity on valid data', () async {
      await cubit.createHostel(
        name: 'New Hostel',
        address: '10 Main Street',
        phone: '1234567890',
        email: 'new@hostel.com',
        ownerName: 'Bob',
        ownerUserId: 2,
      );

      expect(cubit.state.status, HostelStatus.configured);
      expect(cubit.state.hostel, isNotNull);
      expect(cubit.state.hostel!.id, isNotNull);
      expect(cubit.state.hostel!.name, 'New Hostel');
    });

    test('does not create duplicate; loads existing and emits configured',
        () async {
      repo.seed(_seededHostel(ownerUserId: 1));

      await cubit.createHostel(
        name: 'Duplicate',
        address: 'Any',
        phone: '000',
        email: 'dup@x.com',
        ownerName: 'Owner',
        ownerUserId: 1,
      );

      expect(cubit.state.status, HostelStatus.configured);
      expect(cubit.state.hostel!.name, 'Sunrise Hostel'); // existing hostel
      expect(repo._stored!.name, 'Sunrise Hostel'); // not overwritten
    });

    test('emits failure with message when name is empty', () async {
      await cubit.createHostel(
        name: '  ',
        address: 'Addr',
        phone: '123',
        email: 'a@b.com',
        ownerName: 'Owner',
        ownerUserId: 1,
      );

      expect(cubit.state.status, HostelStatus.failure);
      expect(cubit.state.errorMessage, 'Please enter the hostel name.');
    });

    test('emits failure with message when email is invalid', () async {
      await cubit.createHostel(
        name: 'Hostel',
        address: 'Addr',
        phone: '123',
        email: 'not-an-email',
        ownerName: 'Owner',
        ownerUserId: 1,
      );

      expect(cubit.state.status, HostelStatus.failure);
      expect(cubit.state.errorMessage, 'Please enter a valid email address.');
    });

    test('emits failure with safe message on repository error', () async {
      repo.createFails = true;

      await cubit.createHostel(
        name: 'Hostel',
        address: 'Addr',
        phone: '123',
        email: 'a@b.com',
        ownerName: 'Owner',
        ownerUserId: 1,
      );

      expect(cubit.state.status, HostelStatus.failure);
      expect(cubit.state.errorMessage,
          'Unable to save hostel information. Please try again.');
    });
  });

  // -------------------------------------------------------------------------
  // updateHostel
  // -------------------------------------------------------------------------

  group('HostelCubit updateHostel', () {
    test('emits success with updated entity on valid update', () async {
      final existing = _seededHostel();
      repo.seed(existing);

      await cubit.updateHostel(
        hostel: existing,
        name: 'Updated Name',
        address: 'New Address',
        phone: '9999999999',
        email: 'updated@hostel.com',
        ownerName: 'Alice Updated',
      );

      expect(cubit.state.status, HostelStatus.configured);
      expect(cubit.state.hostel!.name, 'Updated Name');
      expect(cubit.state.hostel!.ownerUserId, existing.ownerUserId);
      expect(cubit.state.hostel!.createdAt, existing.createdAt);
      expect(cubit.state.hostel!.updatedAt.isAfter(existing.updatedAt), isTrue);
    });

    test('retains pre-update hostel entity on repository failure', () async {
      final existing = _seededHostel();
      repo.seed(existing);
      repo.updateFails = true;

      await cubit.updateHostel(
        hostel: existing,
        name: 'Updated Name',
        address: 'New Address',
        phone: '9999999999',
        email: 'updated@hostel.com',
        ownerName: 'Alice',
      );

      expect(cubit.state.status, HostelStatus.failure);
      // The original hostel is retained
      expect(cubit.state.hostel, existing);
      expect(cubit.state.errorMessage,
          'Unable to update hostel information. Please try again.');
    });

    test('emits failure immediately when hostel.id is null', () async {
      final noIdHostel = HostelEntity(
        name: 'No ID',
        address: 'Addr',
        phone: '123456',
        email: 'test@hostel.com',
        ownerName: 'Test Owner',
        ownerUserId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cubit.updateHostel(
        hostel: noIdHostel,
        name: 'Updated',
        address: 'Addr',
        phone: '123',
        email: 'a@b.com',
        ownerName: 'Owner',
      );

      expect(cubit.state.status, HostelStatus.failure);
    });
  });
}
