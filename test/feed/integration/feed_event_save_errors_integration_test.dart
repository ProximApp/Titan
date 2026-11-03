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

/// The save-failure arm of add_event_page reached through the poster upload.
///
/// Reaching it needs a poster: without one both flows return through the short
/// success branch, which is why the happy paths and the refused-PATCH test all
/// miss it. Two findings are pinned here, both measured against the real
/// repository layer rather than assumed:
///
///  * a non-2xx upload response is reported as SUCCESS by the image notifier
///    (a 500 here popped the page with "Event modified"), so a refused upload
///    cannot reach the failure arm at all — only a transport-level throw can;
///  * a throwing upload is caught by the page's outer handler, which reports
///    the ADDING error and, crucially, does NOT pop: the user stays on the
///    form because nothing was saved.
///
/// The journey is the edit-residual one verbatim: an all-day event opened from
/// the association-events card, the all-day box cleared so the timed
/// validation passes (the Checkbox runs the clearing hook, the row text does
/// not), dates refilled, the poster picked through the platform-interface fake,
/// and the save tapped from a lifted scroll position (a tap under the
/// ScrollToHideNavbar band is silently dropped).
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
    'a throwing poster upload reports the error and stays on the form',
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

      // Attach the poster: in edit mode the area renders the existing-image
      // branch (the 404 stub falls back to the logo asset), so target the picker.
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
      when(
        () => scaffold.repository.calendarEventsEventIdImagePost(
          eventId: any(named: 'eventId'),
          image: any(named: 'image'),
        ),
      ).thenThrow(Exception('upload refused'));

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

      // The poster really was attached, so the upload really was attempted.
      verify(
        () => scaffold.repository.calendarEventsEventIdImagePost(
          eventId: 'e-1',
          image: any(named: 'image'),
        ),
      ).called(1);
      // The event was updated but the poster was not, so the save is reported as
      // a failure and the page does not pop.
      expect(find.text('Error while adding'), findsOneWidget);
      expect(find.text('Event modified'), findsNothing);
      expect(find.text('Edit event'), findsOneWidget);
      await scaffold.drainToast(tester);
    },
  );
}

/// A decodable 1x1 PNG, pinned as a literal (convention 34: file-private).
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
