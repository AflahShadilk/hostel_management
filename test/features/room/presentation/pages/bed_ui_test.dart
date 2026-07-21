import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_management/core/theme/app_theme.dart';
import 'package:hostel_management/core/widgets/app_button.dart';
import 'package:hostel_management/core/widgets/app_empty_state.dart';
import 'package:hostel_management/core/widgets/app_loading_indicator.dart';
import 'package:hostel_management/features/room/domain/entities/bed_entity.dart';
import 'package:hostel_management/features/room/domain/entities/bed_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_entity.dart';
import 'package:hostel_management/features/room/domain/entities/room_status.dart';
import 'package:hostel_management/features/room/domain/entities/room_type.dart';
import 'package:hostel_management/features/room/presentation/cubit/bed_cubit.dart';
import 'package:hostel_management/features/room/presentation/cubit/bed_operation_status.dart';
import 'package:hostel_management/features/room/presentation/cubit/bed_state.dart';
import 'package:hostel_management/features/room/presentation/cubit/room_cubit.dart';
import 'package:hostel_management/features/room/presentation/cubit/room_state.dart';
import 'package:hostel_management/features/room/presentation/pages/bed_management_page.dart';

class FakeBedCubit extends Cubit<BedState> implements BedCubit {
  int loadBedsCalls = 0;
  BedStatus? lastUpdateStatus;

  FakeBedCubit(super.initialState);

  @override
  Future<void> loadBeds(int roomId) async {
    loadBedsCalls++;
  }

  @override
  Future<void> loadVacantBeds(int roomId) async {}

  @override
  Future<void> updateBedStatus(
      {required BedEntity bed, required BedStatus status}) async {
    lastUpdateStatus = status;
  }
}

class FakeRoomCubit extends Cubit<RoomState> implements RoomCubit {
  FakeRoomCubit(super.initialState);

  @override
  Future<void> loadRooms(int hostelId) async {}

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
  Future<void> deleteRoom(RoomEntity room) async {}
}

Widget _buildTestApp({
  required Widget child,
  required FakeBedCubit bedCubit,
  required FakeRoomCubit roomCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<BedCubit>.value(value: bedCubit),
      BlocProvider<RoomCubit>.value(value: roomCubit),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

RoomEntity _makeRoom({int id = 1, int beds = 4}) {
  final now = DateTime.now();
  return RoomEntity(
    id: id,
    hostelId: 10,
    roomNumber: '101',
    floor: 'Ground',
    roomType: RoomType.single,
    numberOfBeds: beds,
    monthlyRent: 1000.0,
    status: RoomStatus.vacant,
    createdAt: now,
    updatedAt: now,
  );
}

BedEntity _makeBed(
    {int id = 1, String number = 'B1', BedStatus status = BedStatus.vacant}) {
  final now = DateTime.now();
  return BedEntity(
    id: id,
    roomId: 1,
    bedNumber: number, monthlyRent: 5000,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('BedManagementPage', () {
    testWidgets('Valid Room loads Beds exactly once', (tester) async {
      final room = _makeRoom();
      final bedCubit = FakeBedCubit(const BedState());
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      await tester.pumpAndSettle();

      expect(bedCubit.loadBedsCalls, 1);
    });

    testWidgets('Initial loading shows AppLoadingIndicator', (tester) async {
      final room = _makeRoom();
      final bedCubit =
          FakeBedCubit(const BedState(status: BedOperationStatus.loading));
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('Empty Beds shows AppEmptyState', (tester) async {
      final room = _makeRoom();
      final bedCubit = FakeBedCubit(
          const BedState(status: BedOperationStatus.loaded, beds: []));
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('No beds found'), findsOneWidget);
    });

    testWidgets('Load failure shows retry', (tester) async {
      final room = _makeRoom();
      final bedCubit = FakeBedCubit(const BedState(
        status: BedOperationStatus.failure,
        errorMessage: 'Test error',
      ));
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Test error'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(bedCubit.loadBedsCalls, 2); // 1st init, 2nd retry
    });

    testWidgets('Bed cards display Bed Number and Status', (tester) async {
      final room = _makeRoom();
      final beds = [
        _makeBed(id: 1, number: 'B1', status: BedStatus.vacant),
        _makeBed(id: 2, number: 'B2', status: BedStatus.occupied),
        _makeBed(id: 3, number: 'B3', status: BedStatus.inactive),
      ];
      final bedCubit =
          FakeBedCubit(BedState(status: BedOperationStatus.loaded, beds: beds));
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      await tester.pumpAndSettle();

      expect(find.text('B1'), findsOneWidget);
      expect(find.text('B2'), findsOneWidget);
      expect(find.text('B3'), findsOneWidget);

      expect(find.text('Vacant'), findsWidgets);
      expect(find.text('Occupied'), findsWidgets);
      expect(find.text('Inactive'), findsWidgets);
    });

    testWidgets('Summary counts are correct', (tester) async {
      final room = _makeRoom();
      final beds = [
        _makeBed(id: 1, number: 'B1', status: BedStatus.vacant),
        _makeBed(id: 2, number: 'B2', status: BedStatus.vacant),
        _makeBed(id: 3, number: 'B3', status: BedStatus.occupied),
      ];
      final bedCubit =
          FakeBedCubit(BedState(status: BedOperationStatus.loaded, beds: beds));
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      await tester.pumpAndSettle();

      // Check summary card numbers
      expect(find.text('3'), findsOneWidget); // Total
      expect(find.text('2'), findsWidgets); // Vacant
      expect(find.text('1'), findsWidgets); // Occupied
      expect(find.text('0'), findsWidgets); // Inactive
    });

    testWidgets('Vacant Bed shows Set Inactive and confirms', (tester) async {
      final room = _makeRoom();
      final beds = [_makeBed(id: 1, number: 'B1', status: BedStatus.vacant)];
      final bedCubit =
          FakeBedCubit(BedState(status: BedOperationStatus.loaded, beds: beds));
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      await tester.pumpAndSettle();

      final setInactiveFinder = find.text('Set Inactive');
      expect(setInactiveFinder, findsOneWidget);

      await tester.tap(setInactiveFinder);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Set Bed Inactive?'), findsOneWidget);

      // Confirm
      await tester.tap(find.text('Set Inactive').last); // The button in dialog
      await tester.pumpAndSettle();

      expect(bedCubit.lastUpdateStatus, BedStatus.inactive);
    });

    testWidgets('Inactive Bed shows Reactivate', (tester) async {
      final room = _makeRoom();
      final beds = [_makeBed(id: 1, number: 'B1', status: BedStatus.inactive)];
      final bedCubit =
          FakeBedCubit(BedState(status: BedOperationStatus.loaded, beds: beds));
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      await tester.pumpAndSettle();

      final reactivateFinder = find.text('Reactivate');
      expect(reactivateFinder, findsOneWidget);

      await tester.tap(reactivateFinder);
      await tester.pumpAndSettle();

      expect(bedCubit.lastUpdateStatus, BedStatus.vacant);
    });

    testWidgets('Occupied Bed shows no manual status mutation action',
        (tester) async {
      final room = _makeRoom();
      final beds = [_makeBed(id: 1, number: 'B1', status: BedStatus.occupied)];
      final bedCubit =
          FakeBedCubit(BedState(status: BedOperationStatus.loaded, beds: beds));
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Set Inactive'), findsNothing);
      expect(find.text('Reactivate'), findsNothing);
      expect(find.text('Managed through tenant assignment'), findsOneWidget);
    });

    testWidgets('Vacant filter shows only vacant beds', (tester) async {
      final room = _makeRoom();
      final beds = [
        _makeBed(id: 1, number: 'B1', status: BedStatus.vacant),
        _makeBed(id: 2, number: 'B2', status: BedStatus.occupied),
        _makeBed(id: 3, number: 'B3', status: BedStatus.inactive),
      ];
      final bedCubit =
          FakeBedCubit(BedState(status: BedOperationStatus.loaded, beds: beds));
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      await tester.pumpAndSettle();

      // Tap the Vacant filter chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Vacant'));
      await tester.pumpAndSettle();

      // Only B1 (vacant) should be visible; B2 and B3 should be hidden
      expect(find.text('B1'), findsOneWidget);
      expect(find.text('B2'), findsNothing);
      expect(find.text('B3'), findsNothing);
    });

    testWidgets('Occupied filter shows only occupied beds', (tester) async {
      final room = _makeRoom();
      final beds = [
        _makeBed(id: 1, number: 'B1', status: BedStatus.vacant),
        _makeBed(id: 2, number: 'B2', status: BedStatus.occupied),
        _makeBed(id: 3, number: 'B3', status: BedStatus.inactive),
      ];
      final bedCubit =
          FakeBedCubit(BedState(status: BedOperationStatus.loaded, beds: beds));
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Occupied'));
      await tester.pumpAndSettle();

      expect(find.text('B1'), findsNothing);
      expect(find.text('B2'), findsOneWidget);
      expect(find.text('B3'), findsNothing);
    });

    testWidgets('Inactive filter shows only inactive beds', (tester) async {
      final room = _makeRoom();
      final beds = [
        _makeBed(id: 1, number: 'B1', status: BedStatus.vacant),
        _makeBed(id: 2, number: 'B2', status: BedStatus.occupied),
        _makeBed(id: 3, number: 'B3', status: BedStatus.inactive),
      ];
      final bedCubit =
          FakeBedCubit(BedState(status: BedOperationStatus.loaded, beds: beds));
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Inactive'));
      await tester.pumpAndSettle();

      expect(find.text('B1'), findsNothing);
      expect(find.text('B2'), findsNothing);
      expect(find.text('B3'), findsOneWidget);
    });

    testWidgets('All filter shows all beds after switching back', (tester) async {
      final room = _makeRoom();
      final beds = [
        _makeBed(id: 1, number: 'B1', status: BedStatus.vacant),
        _makeBed(id: 2, number: 'B2', status: BedStatus.occupied),
      ];
      final bedCubit =
          FakeBedCubit(BedState(status: BedOperationStatus.loaded, beds: beds));
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      await tester.pumpAndSettle();

      // Switch to Vacant
      await tester.tap(find.widgetWithText(ChoiceChip, 'Vacant'));
      await tester.pumpAndSettle();

      expect(find.text('B2'), findsNothing);

      // Switch back to All
      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();

      expect(find.text('B1'), findsOneWidget);
      expect(find.text('B2'), findsOneWidget);
    });

    testWidgets('Filter empty state shows specific message for vacant',
        (tester) async {
      final room = _makeRoom();
      // Only occupied beds — no vacant
      final beds = [
        _makeBed(id: 1, number: 'B1', status: BedStatus.occupied),
      ];
      final bedCubit =
          FakeBedCubit(BedState(status: BedOperationStatus.loaded, beds: beds));
      final roomCubit = FakeRoomCubit(const RoomState());

      await tester.pumpWidget(_buildTestApp(
        child: BedManagementPage(roomIdStr: '1', room: room),
        bedCubit: bedCubit,
        roomCubit: roomCubit,
      ));

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Vacant'));
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('No vacant beds found.'), findsOneWidget);
    });
  });
}
