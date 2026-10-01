import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/widgets/image_picker_on_tap.dart';

import '../../shared/app_scaffold.dart';

/// The edit-mode residuals of add_event_page, in their own journey file
/// (the edit page mounts through the deferred route — see
/// feed_association_event_edit_integration_test.dart's note): the
/// prefilled all-day branch, the all-day checkbox that clears both date
/// controllers, the update round-trip WITH a poster upload (image picker
/// fake + the calendarEventsEventIdImagePost call), and the refused-update
/// error branch. Nothing overlaps the create-mode residual file.
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

  void stubEditJourney() {
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
  }

  /// Registers the image-picker fake at the platform-interface level: the
  /// returned XFile carries its bytes in memory (XFile.fromData), so
  /// readAsBytes() completes without touching the real filesystem — a
  /// MethodChannel fake would answer with a temp-file PATH whose read
  /// never completes inside the test binding's FakeAsync zone.
  void stubImagePicker() {
    final previous = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(_pngBytes());
    addTearDown(() => ImagePickerPlatform.instance = previous);
  }

  testWidgets(
    'edit mode prefills, the all-day toggle clears dates, and saving with a poster PATCHes then uploads',
    (tester) async {
      final container = scaffold.makeContainer(
        myAssociations: [Association(name: 'BDE', groupId: 'g-1', id: 'a-1')],
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubEditJourney();
      stubImagePicker();
      when(
        () => scaffold.repository.feedNewsGet(),
      ).thenAnswer((_) async => chopperListResponse(<News>[]));

      // The edit page mounts from the association-events card journey.
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
      // All-day event: date-only prefill (no HH:mm suffix) and the checkbox
      // renders checked (the edit-mode prefill branch of the controllers).
      expect(find.text('10/10/2026'), findsOneWidget);
      expect(find.text('10/11/2026'), findsOneWidget);

      // The all-day toggle clears BOTH controllers (its onChanged branch).
      // The row sits below the fold at this viewport.
      await tester.dragUntilVisible(
        find.text('All day'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      // The event-pages CheckBoxEntry flips its value on the Checkbox tap
      // only (the row's GestureDetector flips it WITHOUT the onChanged
      // hook, so tapping the text would skip the date-clearing branch).
      await tester.tap(
        find.descendant(
          of: find
              .ancestor(of: find.text('All day'), matching: find.byType(Row))
              .first,
          matching: find.byType(Checkbox),
        ),
      );
      await settle(tester, frames: 6);
      expect(find.widgetWithText(TextField, '10/10/2026'), findsNothing);
      expect(find.widgetWithText(TextField, '10/11/2026'), findsNothing);

      // Refill the dates as timed values.
      await tester.enterText(
        find.widgetWithText(TextField, 'Start date'),
        '10/10/2026 20:00',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'End date'),
        '10/11/2026 02:00',
      );
      await settle(tester, frames: 4);

      // Tap the poster picker: in edit mode the poster area shows the
      // EXISTING image branch (the 404 stub falls back to the logo asset),
      // not the (851/315) placeholder, so target the picker widget itself.
      await tester.dragUntilVisible(
        find.byType(ImagePickerOnTap),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await tester.tap(find.byType(ImagePickerOnTap));
      await settle(tester, frames: 10);

      // Save: the PATCH round-trips, then the poster upload fires, then
      // the page pops back to the feed with the modified toast.
      EventEdit? capturedEdit;
      when(
        () => scaffold.repository.calendarEventsEventIdPatch(
          eventId: any(named: 'eventId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((inv) async {
        capturedEdit = inv.namedArguments[#body] as EventEdit;
        return chopperResponse(EventCompleteTicketUrl.empty());
      });
      when(
        () => scaffold.repository.calendarEventsEventIdImagePost(
          eventId: any(named: 'eventId'),
          image: any(named: 'image'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());
      await tester.dragUntilVisible(
        find.text('Edit event'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      // Lift the submit row clear of the ScrollToHideNavbar band — a tap
      // under the overlay is silently dropped (README convention 11's
      // cousin).
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -80),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Edit event'), warnIfMissed: false);
      await settle(tester, frames: 14);

      expect(capturedEdit, isNotNull);
      expect(capturedEdit!.name, 'Gala de printemps');
      expect(capturedEdit!.start, isNotNull);
      expect(capturedEdit!.start!.year, 2026);
      verify(
        () => scaffold.repository.calendarEventsEventIdImagePost(
          eventId: 'e-1',
          image: any(named: 'image'),
        ),
      ).called(1);
      expect(find.text('Event modified'), findsOneWidget);
      // QR.back() lands on the association events list the journey started
      // from, not the feed root.
      expect(find.text('Gala de printemps'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );

  testWidgets('a refused event update shows the modifying error toast', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      myAssociations: [Association(name: 'BDE', groupId: 'g-1', id: 'a-1')],
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubEditJourney();
    when(
      () => scaffold.repository.feedNewsGet(),
    ).thenAnswer((_) async => chopperListResponse(<News>[]));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/feed/association_events',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);

    await scaffold.openModal(tester, find.text('Gala de printemps'));
    await scaffold.tapInModal(tester, find.text('Edit'));
    for (var i = 0; i < 20 && find.text('Edit event').evaluate().isEmpty; i++) {
      await settle(tester, frames: 4);
    }
    expect(find.text('Edit event'), findsOneWidget);

    when(
      // ignore: void_checks
      () => scaffold.repository.calendarEventsEventIdPatch(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<EventCompleteTicketUrl>(
        http.Response('{"detail": "nope"}', 409),
        null,
      ),
    );
    await tester.dragUntilVisible(
      find.text('Edit event'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -200),
    );
    await settle(tester, frames: 2);
    // Lift the submit row clear of the ScrollToHideNavbar band — a tap
    // under the overlay is silently dropped.
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -80),
    );
    await settle(tester, frames: 2);
    await tester.tap(find.text('Edit event'), warnIfMissed: false);
    await settle(tester, frames: 14);

    expect(find.text('Error while modifying'), findsOneWidget);
    await scaffold.drainToast(tester);
  });
}

class _FakeImagePickerPlatform extends ImagePickerPlatform {
  _FakeImagePickerPlatform(this.bytes);

  final List<int> bytes;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return XFile.fromData(Uint8List.fromList(bytes), mimeType: 'image/png');
  }
}

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
