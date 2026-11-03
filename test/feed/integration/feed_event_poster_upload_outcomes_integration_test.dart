import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/widgets/image_picker_on_tap.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/image_stub.dart';

/// The two poster-upload outcomes add_event_page had no witness for.
///
///  * An UPDATE that the server accepts while the poster upload comes back
///    non-2xx: the event is saved, the image is not, and the page must stay
///    open saying so. The existing save-error file only reaches the THROWING
///    upload, which the outer catch turns into the generic "error while
///    adding" — a different arm.
///  * A CREATE that succeeds WITH a poster: the page uploads the image to the
///    NEW id before it reports anything. This is the only arm that reaches
///    the upload inside the create branch at all; every other create test
///    submits without a poster, so a regression in it (uploading to an empty
///    id, or claiming success before the upload) would go unseen.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  EventCompleteTicketUrl event() => EventCompleteTicketUrl.empty().copyWith(
    id: 'e-1',
    name: 'Gala de printemps',
    location: 'Amphi Marie Curie',
    associationId: 'a-1',
    association: Association(name: 'BDE', groupId: 'g-1', id: 'a-1'),
    start: DateTime(2026, 10, 10, 20),
    end: DateTime(2026, 10, 11, 2),
    allDay: true,
    decision: enums.Decision.approved,
  );

  /// Platform-level picker fake: `XFile.fromData` keeps the bytes in memory,
  /// so `readAsBytes()` completes inside the test binding's zone.
  void stubImagePicker() {
    final previous = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = StubImagePicker(
      next: XFile.fromData(
        Uint8List.fromList(_pngBytes()),
        mimeType: 'image/png',
      ),
    );
    addTearDown(() => ImagePickerPlatform.instance = previous);
  }

  testWidgets(
    'an accepted update whose poster is refused stays on the form with the modifying error',
    (tester) async {
      final container = scaffold.makeContainer(
        myAssociations: [Association(name: 'BDE', groupId: 'g-1', id: 'a-1')],
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubImagePicker();
      when(
        () => scaffold.repository.calendarEventsAssociationsAssociationIdGet(
          associationId: any(named: 'associationId'),
        ),
      ).thenAnswer((_) async => chopperListResponse([event()]));
      when(
        () => scaffold.repository.calendarEventsEventIdImageGet(
          eventId: any(named: 'eventId'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<List<int>>(
          http.Response('{"detail": "File does not exist"}', 404),
          [],
          error: 'File does not exist',
        ),
      );
      when(() => scaffold.repository.feedNewsGet())
          .thenAnswer((_) async => chopperListResponse(<News>[]));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/feed/association_events',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 12);

      await scaffold.openModal(tester, find.text('Gala de printemps'));
      await scaffold.tapInModal(tester, find.text('Edit'));
      for (
        var i = 0;
        i < 20 && find.text('Edit event').evaluate().isEmpty;
        i++
      ) {
        await settle(tester, frames: 4);
      }
      expect(find.text('Edit event'), findsOneWidget);

      // All-day events prefill day-only; clear the box so the submit passes
      // the timed validation, then refill both dates.
      await tester.dragUntilVisible(
        find.text('All day'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await tester.tap(
        find.descendant(
          of: find
              .ancestor(of: find.text('All day'), matching: find.byType(Row))
              .first,
          matching: find.byType(Checkbox),
        ),
      );
      await settle(tester, frames: 6);
      await tester.enterText(
        find.widgetWithText(TextField, 'Start date'),
        '10/10/2026 20:00',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'End date'),
        '10/11/2026 02:00',
      );
      await settle(tester, frames: 4);

      await tester.dragUntilVisible(
        find.byType(ImagePickerOnTap),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await tester.tap(find.byType(ImagePickerOnTap));
      await settle(tester, frames: 10);

      when(
        () => scaffold.repository.calendarEventsEventIdPatch(
          eventId: any(named: 'eventId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopperResponse<EventCompleteTicketUrl>(
          EventCompleteTicketUrl.empty(),
        ),
      );
      // A 5xx upload: the notifier answers false, so the page's own
      // "event saved, image not" branch runs (it used to answer true
      // unconditionally and pop the page as a full success).
      when(
        () => scaffold.repository.calendarEventsEventIdImagePost(
          eventId: any(named: 'eventId'),
          image: any(named: 'image'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<void>(
          http.Response('{"detail": "upload refused"}', 500),
          null,
        ),
      );

      await tester.dragUntilVisible(
        find.text('Edit event'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -80),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Edit event'), warnIfMissed: false);
      await settle(tester, frames: 14);

      verify(
        () => scaffold.repository.calendarEventsEventIdImagePost(
          eventId: 'e-1',
          image: any(named: 'image'),
        ),
      ).called(1);
      expect(find.text('Error while modifying'), findsOneWidget);
      expect(find.text('Event modified'), findsNothing);
      // The form stays up: nothing was reported as saved.
      expect(find.text('Edit event'), findsOneWidget);
      await scaffold.drainToast(tester);
    },
  );

  testWidgets(
    'a created event uploads its poster to the new id before saving',
    (tester) async {
      final container = scaffold.makeContainer(
        myAssociations: [Association(name: 'BDE', groupId: 'g-1', id: 'a-1')],
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubImagePicker();
      when(() => scaffold.repository.feedNewsGet())
          .thenAnswer((_) async => chopperListResponse(<News>[]));
      when(
        () => scaffold.repository.calendarEventsPost(body: any(named: 'body')),
      ).thenAnswer(
        (_) async => chopperResponse(
          EventCompleteTicketUrl.empty().copyWith(
            id: 'e-new',
            name: 'Soirée de gala',
            associationId: 'a-1',
            decision: enums.Decision.pending,
          ),
        ),
      );
      when(
        () => scaffold.repository.calendarEventsEventIdImagePost(
          eventId: any(named: 'eventId'),
          image: any(named: 'image'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/feed/add_edit_event',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 40);
      expect(find.text('Create an event'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        'Soirée de gala',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Start date'),
        '10/10/2026 20:00',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'End date'),
        '10/11/2026 02:00',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Location'),
        'Amphi Marie Curie',
      );
      await settle(tester, frames: 6);

      await tester.dragUntilVisible(
        find.byType(ImagePickerOnTap),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await tester.tap(find.byType(ImagePickerOnTap));
      await settle(tester, frames: 10);

      await tester.dragUntilVisible(
        find.text('Create an event'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -80),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Create an event'), warnIfMissed: false);
      await settle(tester, frames: 14);

      // The upload targets the id the POST answered with, not the draft.
      verify(
        () => scaffold.repository.calendarEventsEventIdImagePost(
          eventId: 'e-new',
          image: any(named: 'image'),
        ),
      ).called(1);
      expect(find.text('Event added'), findsOneWidget);
      // Popped back to the feed after both steps finished.
      expect(find.text('No news available'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}

/// A decodable 1x1 PNG as a literal payload (convention 34: file-private).
List<int> _pngBytes() => <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1f,
  0x15,
  0xc4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9c,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0d,
  0x0a,
  0x2d,
  0xb4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4e,
  0x44,
  0xae,
  0x42,
  0x60,
  0x82,
];
