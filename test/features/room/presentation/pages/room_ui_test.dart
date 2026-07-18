// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/core/constants/app_spacing.dart';
import 'package:hostel_management/core/router/app_routes.dart';
import 'package:hostel_management/core/theme/app_theme.dart';
import 'package:hostel_management/core/widgets/app_button.dart';
import 'package:hostel_management/core/widgets/app_empty_state.dart';
import 'package:hostel_management/core/widgets/app_loading_indicator.dart';
import 'package:hostel_management/features/hostel/domain/entities/hostel_entity.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_cubit.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_state.dart';
import 'package:hostel_management/features/hostel/presentation/cubit/hostel_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_entity.dart';
import 'package:hostel_management/features/room/domain/entities/room_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_type.dart';
import 'package:hostel_management/features/room/presentation/cubit/room_cubit.dart';
import 'package:hostel_management/features/room/presentation/cubit/room_operation_status.dart';
import 'package:hostel_management/features/room/presentation/cubit/room_state.dart';
import 'package:hostel_management/features/room/presentation/pages/add_room_page.dart';
import 'package:hostel_management/features/room/presentation/pages/edit_room_page.dart';
import 'package:hostel_management/features/room/presentation/pages/room_management_page.dart';
import 'package:hostel_management/features/room/presentation/widgets/room_card.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class FakeHostelCubit extends Cubit<HostelState> implements HostelCubit {
  FakeHostelCubit(HostelState initial) : super(initial);

  @override
  Future<void> checkHostelSetup(int ownerUserId) async {}

  @override
  Future<void> createHostel({
    required String name,
    String? logoPath,
    required String address,
    required String phone,
    required String email,
    required String ownerName,
    required int ownerUserId,
  }) async {}

  @override
  Future<void> updateHostel({
    required HostelEntity hostel,
    required String name,
    String? logoPath,
    required String address,
    required String phone,
    required String email,
    required String ownerName,
  }) async {}
}

class FakeRoomCubit extends Cubit<RoomState> implements RoomCubit {
  int loadRoomsCalls = 0;
  int deleteRoomCalls = 0;

  FakeRoomCubit(RoomState initial) : super(initial);

  @override
  Future<void> emit(RoomState state) async => super.emit(state);

  void simulateLoaded(List<RoomEntity> rooms) {
    // ignore: invalid_use_of_visible_for_testing_member
    super.emit(RoomState(status: RoomOperationStatus.loaded, rooms: rooms));
  }

  void simulateLoading() {
    // ignore: invalid_use_of_visible_for_testing_member
    super.emit(const RoomState(status: RoomOperationStatus.loading));
  }

  void simulateFailure(String msg) {
    // ignore: invalid_use_of_visible_for_testing_member
    super.emit(RoomState(
        status: RoomOperationStatus.failure,
        errorMessage: msg,
        rooms: const []));
  }

  void fakeLoadRooms(int hostelId) {
    loadRoomsCalls++;
  }

  @override
  Future<void> loadRooms(int hostelId) async {
    loadRoomsCalls++;
  }

  @override
  Future<void> createRoom({
    required int hostelId,
    required String roomNumber,
    required String floor,
    required RoomType roomType,
    required int numberOfBeds,
    required double monthlyRent,
  }) async {}

  @override
  Future<void> updateRoom({
    required RoomEntity currentRoom,
    required String roomNumber,
    required String floor,
    required RoomType roomType,
    required int numberOfBeds,
    required double monthlyRent,
  }) async {}

  @override
  Future<void> deleteRoom(RoomEntity room) async {
    deleteRoomCalls++;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

HostelState get _configuredHostelState => HostelState(
      status: HostelStatus.configured,
      hostel: HostelEntity(
        id: 10,
        name: 'Test Hostel',
        address: 'Address',
        phone: '1234567890',
        email: 'test@hostel.com',
        ownerName: 'Owner',
        ownerUserId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

RoomEntity _makeRoom({int id = 1, String number = '101'}) {
  final now = DateTime.now();
  return RoomEntity(
    id: id,
    hostelId: 10,
    roomNumber: number,
    floor: 'Ground',
    roomType: RoomType.single,
    numberOfBeds: 1,
    monthlyRent: 1000.0,
    status: RoomStatus.vacant,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildTestApp({
  required Widget child,
  required FakeHostelCubit hostelCubit,
  required FakeRoomCubit roomCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<HostelCubit>.value(value: hostelCubit),
      BlocProvider<RoomCubit>.value(value: roomCubit),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

// ---------------------------------------------------------------------------
// Room Management Page Tests
// ---------------------------------------------------------------------------

void main() {
  group('RoomManagementPage', () {
    testWidgets('shows AppLoadingIndicator when loading with empty rooms',
        (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final roomCubit =
          FakeRoomCubit(const RoomState(status: RoomOperationStatus.loading));

      await tester.pumpWidget(_buildTestApp(
        child: const RoomManagementPage(),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('shows AppEmptyState when no rooms loaded', (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final roomCubit =
          FakeRoomCubit(const RoomState(status: RoomOperationStatus.loaded));

      await tester.pumpWidget(_buildTestApp(
        child: const RoomManagementPage(),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('No rooms added yet'), findsOneWidget);
    });

    testWidgets('shows Room cards when rooms are loaded', (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final room = _makeRoom();
      final roomCubit = FakeRoomCubit(RoomState(
        status: RoomOperationStatus.loaded,
        rooms: [room],
      ));

      await tester.pumpWidget(_buildTestApp(
        child: const RoomManagementPage(),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      expect(find.byType(RoomCard), findsOneWidget);
      expect(find.textContaining('101'), findsAny);
    });

    testWidgets('shows retry option on initial load failure', (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final roomCubit = FakeRoomCubit(RoomState(
        status: RoomOperationStatus.failure,
        errorMessage: 'Unable to load rooms.',
        rooms: const [],
      ));

      await tester.pumpWidget(_buildTestApp(
        child: const RoomManagementPage(),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      expect(find.text('Unable to load rooms'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Room card displays all required information', (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final room = _makeRoom();
      final roomCubit = FakeRoomCubit(RoomState(
        status: RoomOperationStatus.loaded,
        rooms: [room],
      ));

      await tester.pumpWidget(_buildTestApp(
        child: const RoomManagementPage(),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      // Number, floor, type, beds, status should all be visible.
      expect(find.textContaining('101'), findsAny);
      expect(find.textContaining('Ground'), findsAny);
      expect(find.textContaining('Single'), findsAny);
      expect(find.textContaining('1'), findsAny);
      expect(find.textContaining('Vacant'), findsAny);
    });
  });

  // ---------------------------------------------------------------------------
  // RoomCard Tests
  // ---------------------------------------------------------------------------

  group('RoomCard', () {
    testWidgets('Edit and Delete tooltips are present', (tester) async {
      final room = _makeRoom();
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: RoomCard(room: room, onEdit: () {}, onDelete: () {}),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byTooltip('Edit Room'), findsOneWidget);
      expect(find.byTooltip('Delete Room'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // AddRoomPage Tests
  // ---------------------------------------------------------------------------

  group('AddRoomPage', () {
    testWidgets('renders all required fields', (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final roomCubit =
          FakeRoomCubit(const RoomState(status: RoomOperationStatus.initial));

      await tester.pumpWidget(_buildTestApp(
        child: const AddRoomPage(),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      expect(find.text('Room Number'), findsOneWidget);
      expect(find.text('Floor'), findsOneWidget);
      expect(find.text('Room Type'), findsOneWidget);
      expect(find.text('Number of Beds'), findsOneWidget);
      expect(find.text('Monthly Rent (₹)'), findsOneWidget);
    });

    testWidgets('shows validation error on empty Room Number', (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final roomCubit =
          FakeRoomCubit(const RoomState(status: RoomOperationStatus.initial));

      await tester.pumpWidget(_buildTestApp(
        child: const AddRoomPage(),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter the room number.'), findsOneWidget);
    });

    testWidgets('shows validation error on empty Floor', (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final roomCubit =
          FakeRoomCubit(const RoomState(status: RoomOperationStatus.initial));

      await tester.pumpWidget(_buildTestApp(
        child: const AddRoomPage(),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), '101');
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter the floor.'), findsOneWidget);
    });

    testWidgets('shows validation error on invalid Number of Beds',
        (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final roomCubit =
          FakeRoomCubit(const RoomState(status: RoomOperationStatus.initial));

      await tester.pumpWidget(_buildTestApp(
        child: const AddRoomPage(),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), '101');
      await tester.enterText(find.byType(TextField).at(1), 'Ground');
      // Beds field is at index 2, rent at index 3 (after dropdown)
      // Leave beds empty.
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter the number of beds.'), findsOneWidget);
    });

    testWidgets('shows creating state with loading button', (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final roomCubit =
          FakeRoomCubit(const RoomState(status: RoomOperationStatus.creating));

      await tester.pumpWidget(_buildTestApp(
        child: const AddRoomPage(),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      // When creating, button shows loading indicator.
      expect(find.byType(CircularProgressIndicator), findsAny);
    });
  });

  // ---------------------------------------------------------------------------
  // EditRoomPage Tests
  // ---------------------------------------------------------------------------

  group('EditRoomPage', () {
    testWidgets('shows safe fallback when room is null', (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final roomCubit =
          FakeRoomCubit(const RoomState(status: RoomOperationStatus.initial));

      await tester.pumpWidget(_buildTestApp(
        child: const EditRoomPage(room: null),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      expect(find.text('Room information is unavailable.'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('prefills room fields correctly', (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final roomCubit =
          FakeRoomCubit(const RoomState(status: RoomOperationStatus.initial));
      final room = _makeRoom();

      await tester.pumpWidget(_buildTestApp(
        child: EditRoomPage(room: room),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      expect(find.text('101'), findsAny);
      expect(find.text('Ground'), findsAny);
      expect(find.text('1'), findsAny); // beds
    });

    testWidgets('shows capacity warning text', (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final roomCubit =
          FakeRoomCubit(const RoomState(status: RoomOperationStatus.initial));
      final room = _makeRoom();

      await tester.pumpWidget(_buildTestApp(
        child: EditRoomPage(room: room),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      expect(find.textContaining('Increasing beds creates new beds'), findsAny);
    });

    testWidgets('shows updating state when updating', (tester) async {
      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final roomCubit =
          FakeRoomCubit(const RoomState(status: RoomOperationStatus.updating));
      final room = _makeRoom();

      await tester.pumpWidget(_buildTestApp(
        child: EditRoomPage(room: room),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAny);
    });
  });

  // ---------------------------------------------------------------------------
  // Responsive smoke test
  // ---------------------------------------------------------------------------

  group('Responsive Layout', () {
    testWidgets('renders without overflow at phone width (360)',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final room = _makeRoom();
      final roomCubit = FakeRoomCubit(RoomState(
        status: RoomOperationStatus.loaded,
        rooms: [room],
      ));

      await tester.pumpWidget(_buildTestApp(
        child: const RoomManagementPage(),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at tablet width (800)',
        (tester) async {
      tester.view.physicalSize = const Size(800 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final hostelCubit = FakeHostelCubit(_configuredHostelState);
      final room = _makeRoom();
      final roomCubit = FakeRoomCubit(RoomState(
        status: RoomOperationStatus.loaded,
        rooms: [room],
      ));

      await tester.pumpWidget(_buildTestApp(
        child: const RoomManagementPage(),
        hostelCubit: hostelCubit,
        roomCubit: roomCubit,
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // AppRoutes constants
  // ---------------------------------------------------------------------------

  group('AppRoutes room constants', () {
    test('roomManagement route constants are defined', () {
      expect(AppRoutes.roomManagementName, 'roomManagement');
      expect(AppRoutes.roomManagementPath, '/rooms');
      expect(AppRoutes.addRoomName, 'addRoom');
      expect(AppRoutes.addRoomPath, 'add');
      expect(AppRoutes.editRoomName, 'editRoom');
      expect(AppRoutes.editRoomPath, ':roomId/edit');
    });
  });
}
