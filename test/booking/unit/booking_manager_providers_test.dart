import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:titan/booking/adapters/manager.dart';
import 'package:titan/booking/providers/is_manager_provider.dart';
import 'package:titan/booking/providers/manager_confirmed_booking_list_provider.dart';
import 'package:titan/booking/providers/manager_id_provider.dart';
import 'package:titan/booking/providers/manager_list_provider.dart';
import 'package:titan/booking/providers/user_manager_list_provider.dart';
import 'package:titan/booking/ui/calendar/appointment_data_source.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

/// Coverage for the booking manager providers that no page-level test reaches
/// (manager_list_provider CRUD, the user-managers list, isManagerProvider and
/// ManagerIdNotifier), plus the Syncfusion appointment data source whose
/// subject/recurrence getters cast the stored items.
void main() {
  group('ManagerListNotifier', () {
    late MockOpenapi mockRepository;
    late ProviderContainer container;
    late ManagerListNotifier provider;
    final managers = [
      Manager.empty().copyWith(id: '1', name: 'Alice'),
      Manager.empty().copyWith(id: '2', name: 'Bob'),
    ];
    final newManager = Manager.empty().copyWith(id: '3', name: 'Carol');

    setUp(() async {
      mockRepository = MockOpenapi();
      when(() => mockRepository.bookingManagersGet())
          .thenThrow(Exception('Failed to load managers'));
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      provider = container.read(managerListProvider.notifier);
      await Future(() {});
    });

    tearDown(() => container.dispose());

    test('loadManagers returns the managers on success', () async {
      when(() => mockRepository.bookingManagersGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), managers),
      );

      final result = await provider.loadManagers();

      expect(
        result.maybeWhen(data: (data) => data, orElse: () => []),
        managers,
      );
    });

    test('loadManagers settles into error on failure', () async {
      when(() => mockRepository.bookingManagersGet())
          .thenThrow(Exception('Failed to load managers'));

      final result = await provider.loadManagers();

      expect(
        result.maybeWhen(error: (error, _) => error, orElse: () => null),
        isA<Exception>(),
      );
    });

    test('addManager appends the created manager', () async {
      when(() => mockRepository.bookingManagersPost(body: any(named: 'body')))
          .thenAnswer(
            (_) async =>
                chopper.Response(http.Response('body', 200), newManager),
          );

      provider.state = AsyncValue.data([...managers]);
      final result = await provider.addManager(newManager.toManagerBase());

      expect(result, true);
      expect(provider.state.maybeWhen(data: (data) => data, orElse: () => []), [
        ...managers,
        newManager,
      ]);
    });

    test('addManager returns false when the POST throws', () async {
      when(() => mockRepository.bookingManagersPost(body: any(named: 'body')))
          .thenThrow(Exception('Failed to add manager'));

      provider.state = AsyncValue.data([...managers]);
      final result = await provider.addManager(newManager.toManagerBase());

      expect(result, false);
    });

    test('updateManager replaces the manager in the list', () async {
      when(
        () => mockRepository.bookingManagersManagerIdPatch(
          managerId: any(named: 'managerId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      final updated = managers.first.copyWith(name: 'Alice Updated');
      provider.state = AsyncValue.data([...managers]);
      final result = await provider.updateManager(updated);

      expect(result, true);
      expect(provider.state.maybeWhen(data: (data) => data, orElse: () => []), [
        updated,
        managers[1],
      ]);
    });

    test('deleteManager removes the manager from the list', () async {
      when(
        () => mockRepository.bookingManagersManagerIdDelete(
          managerId: any(named: 'managerId'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      provider.state = AsyncValue.data([...managers]);
      final result = await provider.deleteManager(managers.first);

      expect(result, true);
      expect(provider.state.maybeWhen(data: (data) => data, orElse: () => []), [
        managers[1],
      ]);
    });

    test('deleteManager returns false when the DELETE throws', () async {
      when(
        () => mockRepository.bookingManagersManagerIdDelete(
          managerId: any(named: 'managerId'),
        ),
      ).thenThrow(Exception('Failed to delete manager'));

      provider.state = AsyncValue.data([...managers]);
      final result = await provider.deleteManager(managers.first);

      expect(result, false);
    });
  });

  group('UserManagerListNotifier', () {
    late MockOpenapi mockRepository;
    late ProviderContainer container;
    late UserManagerListNotifier provider;
    final managers = [Manager.empty().copyWith(id: '1', name: 'Alice')];

    setUp(() async {
      mockRepository = MockOpenapi();
      when(() => mockRepository.bookingManagersUsersMeGet())
          .thenThrow(Exception('Failed to load managers'));
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      provider = container.read(userManagerListProvider.notifier);
      await Future(() {});
    });

    tearDown(() => container.dispose());

    test('loadManagers returns the user-managed managers', () async {
      when(() => mockRepository.bookingManagersUsersMeGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), managers),
      );

      final result = await provider.loadManagers();

      expect(
        result.maybeWhen(data: (data) => data, orElse: () => []),
        managers,
      );
    });

    test('loadManagers settles into error on failure', () async {
      when(() => mockRepository.bookingManagersUsersMeGet())
          .thenThrow(Exception('Failed to load managers'));

      final result = await provider.loadManagers();

      expect(
        result.maybeWhen(error: (error, _) => error, orElse: () => null),
        isA<Exception>(),
      );
    });
  });

  group('isManagerProvider', () {
    late MockOpenapi mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockOpenapi();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    test('is true when the user manages at least one manager', () async {
      when(() => mockRepository.bookingManagersUsersMeGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), [
          Manager.empty().copyWith(id: '1', name: 'Alice'),
        ]),
      );

      container.read(userManagerListProvider);
      await Future(() {});
      await Future(() {});

      expect(container.read(isManagerProvider), true);
    });

    test('is false while the user-managers list is still loading', () {
      // A never-completing future keeps the list provider in loading.
      when(
        () => mockRepository.bookingManagersUsersMeGet(),
      ).thenAnswer((_) => Completer<chopper.Response<List<Manager>>>().future);

      container.read(userManagerListProvider);

      expect(container.read(isManagerProvider), false);
    });

    test('is false when loading the user-managers list fails', () async {
      when(() => mockRepository.bookingManagersUsersMeGet())
          .thenThrow(Exception('Failed to load managers'));

      container.read(userManagerListProvider);
      await Future(() {});
      await Future(() {});

      expect(container.read(isManagerProvider), false);
    });
  });

  group('ManagerIdNotifier', () {
    test('setId updates the state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(managerIdProvider.notifier);

      expect(container.read(managerIdProvider), '');

      notifier.setId('manager-1');

      expect(container.read(managerIdProvider), 'manager-1');
    });
  });

  group('ManagerConfirmedBookingListProvider', () {
    late MockOpenapi mockRepository;
    late ProviderContainer container;
    late ManagerConfirmedBookingListProvider provider;
    final bookings = [
      BookingReturnSimpleApplicant.empty().copyWith(id: 'b-1'),
      BookingReturnSimpleApplicant.empty().copyWith(id: 'b-2'),
    ];

    setUp(() async {
      mockRepository = MockOpenapi();
      when(() => mockRepository.bookingBookingsConfirmedGet())
          .thenThrow(Exception('Failed to load bookings'));
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      provider = container.read(managerConfirmedBookingListProvider.notifier);
      await Future(() {});
    });

    tearDown(() => container.dispose());

    test(
      'loadConfirmedBookingForManager returns the confirmed bookings',
      () async {
        when(() => mockRepository.bookingBookingsConfirmedGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), bookings),
        );

        final result = await provider.loadConfirmedBookingForManager();

        expect(
          result.maybeWhen(data: (data) => data, orElse: () => []),
          bookings,
        );
      },
    );

    test(
      'loadConfirmedBookingForManager settles into error on failure',
      () async {
        when(() => mockRepository.bookingBookingsConfirmedGet())
            .thenThrow(Exception('Failed to load bookings'));

        final result = await provider.loadConfirmedBookingForManager();

        expect(
          result.maybeWhen(error: (error, _) => error, orElse: () => null),
          isA<Exception>(),
        );
      },
    );

    test('addBooking appends locally', () async {
      provider.state = AsyncValue.data([bookings.first]);
      final result = await provider.addBooking(bookings[1]);

      expect(result, true);
      expect(
        provider.state.maybeWhen(data: (data) => data, orElse: () => []),
        bookings,
      );
    });

    test('deleteBooking removes locally by id', () async {
      provider.state = AsyncValue.data([...bookings]);
      final result = await provider.deleteBooking(bookings.first);

      expect(result, true);
      expect(provider.state.maybeWhen(data: (data) => data, orElse: () => []), [
        bookings[1],
      ]);
    });
  });

  group('AppointmentDataSource', () {
    BookingReturnSimpleApplicant buildBooking({
      String? note,
      String? recurrenceRule,
      String roomName = 'Amphi',
    }) => BookingReturnSimpleApplicant.empty().copyWith(
      reason: 'Réunion',
      start: DateTime(2026, 10, 20, 14),
      end: DateTime(2026, 10, 20, 16),
      note: note,
      recurrenceRule: recurrenceRule,
      room: RoomComplete.empty().copyWith(id: 'r-1', name: roomName),
    );

    test('maps start, end, subject, color, notes and time zones', () {
      final booking = buildBooking(note: 'projector');
      final source = AppointmentDataSource([booking]);

      expect(source.appointments, hasLength(1));
      expect(source.getStartTime(0), DateTime(2026, 10, 20, 14));
      expect(source.getEndTime(0), DateTime(2026, 10, 20, 16));
      expect(source.getSubject(0), 'Amphi - Réunion');
      expect(source.getColor(0), isA<Color>());
      expect(source.isAllDay(0), false);
      expect(source.getNotes(0), 'projector');
      expect(source.getStartTimeZone(0), 'Europe/Paris');
      expect(source.getEndTimeZone(0), 'Europe/Paris');
    });

    test('returns the recurrence rule when set and null when empty', () {
      final withRule = buildBooking(recurrenceRule: 'FREQ=WEEKLY;BYDAY=TU');
      final withoutRule = buildBooking();
      final source = AppointmentDataSource([withRule, withoutRule]);

      expect(source.getRecurrenceRule(0), 'FREQ=WEEKLY;BYDAY=TU');
      expect(source.getRecurrenceRule(1), isNull);
    });

    test('convertAppointmentToObject hands the custom data back', () {
      final booking = buildBooking();
      final source = AppointmentDataSource([booking]);

      final converted = source.convertAppointmentToObject(
        BookingReturn.empty().copyWith(id: 'b-9'),
        Appointment(
          startTime: DateTime(2026, 10, 20, 14),
          endTime: DateTime(2026, 10, 20, 16),
        ),
      );

      expect(converted, isA<BookingReturn>());
      expect(converted!.id, 'b-9');
    });
  });
}
