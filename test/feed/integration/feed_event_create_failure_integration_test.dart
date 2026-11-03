import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';

import 'package:titan/tools/ui/widgets/image_picker_on_tap.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/image_stub.dart';

/// Bug report 28/09 ("plusieurs assos n'arrivent pas à créer d'event … ça met
/// 'erreur lors de l'ajout'"): the CREATE-mode failure arm of add_event_page.
///
/// Every other feed test takes the create path with a stubbed success, and the
/// only `Error while adding` expectation in the suite belongs to the EDIT-mode
/// poster upload. So the exact journey the associations reported — fill the
/// form, press publish, get the generic error — had no test at all. Three
/// things are pinned here, because all three are what makes the report
/// confusing rather than merely failed:
///
///  * the failure is reported (`Error while adding`, and nothing claiming the
///    event exists — no `Event added` toast);
///  * the form STAYS open. Popping on a refused create would tell the user the
///    event was published, which is how a retry turns into a duplicate;
///  * the page does not retry the POST by itself. The reported users waited
///    1–2 h and eventually "got through", which is consistent with pressing
///    publish again — that has to be their action, once per attempt.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// A negative dy scrolls down the page, a positive one back up.
  Future<void> dragTo(WidgetTester tester, Finder finder, double dy) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(SingleChildScrollView).last,
      Offset(0, dy),
    );
    await settle(tester, frames: 2);
  }

  Future<void> submit(WidgetTester tester) async {
    await dragTo(tester, find.text('Create an event'), -600);
    await tester.tap(find.text('Create an event'));
    await settle(tester, frames: 10);
  }

  testWidgets(
    'a refused publish reports the error, stays on the form and does not retry',
    (tester) async {
      final container = scaffold.makeContainer(
        myAssociations: [Association(name: 'BDE', groupId: 'g-1', id: 'a-1')],
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);

      when(() => scaffold.repository.feedNewsGet())
          .thenAnswer((_) async => chopperListResponse(<News>[]));

      // What the associations got on 28/09: the create endpoint refusing the
      // event. A 500 with no body is the shape the server answered with.
      var posts = 0;
      when(
        () => scaffold.repository.calendarEventsPost(body: any(named: 'body')),
      ).thenAnswer((_) async {
        posts++;
        return chopper.Response<EventCompleteTicketUrl>(
          http.Response('{"detail": "Internal Server Error"}', 500),
          null,
          error: 'Internal Server Error',
        );
      });

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/feed/add_edit_event',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 40);
      expect(find.text('Create an event'), findsOneWidget);

      // The single association is selected by default; tapping its chip would
      // deselect it and block the submit before the endpoint is reached.
      expect(find.text('BDE'), findsOneWidget);

      await dragTo(tester, find.widgetWithText(TextField, 'Title'), 600);
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
      await settle(tester, frames: 4);

      await submit(tester);

      // The tap really reached the endpoint, so a missing toast below cannot be
      // a blocked submit wearing a failure message.
      expect(
        posts,
        1,
        reason: 'the publish tap must reach the create endpoint',
      );
      expect(find.text('Error while adding'), findsOneWidget);
      expect(find.text('Event added'), findsNothing);
      // Still on the form: nothing was saved, so leaving would be a lie.
      expect(find.text('Create an event'), findsOneWidget);
      // No poster was attached, so no upload may be attempted against an id
      // that does not exist.
      verifyNever(
        () => scaffold.repository.calendarEventsEventIdImagePost(
          eventId: any(named: 'eventId'),
          image: any(named: 'image'),
        ),
      );
      await scaffold.drainToast(tester);
    },
  );

  /// Fills the four required fields. The single association is pre-selected.
  Future<void> fillForm(WidgetTester tester) async {
    await dragTo(tester, find.widgetWithText(TextField, 'Title'), 600);
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
    await settle(tester, frames: 4);
  }

  void stubPosterPicker() {
    final previous = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = StubImagePicker(
      next: XFile.fromData(
        Uint8List.fromList(_pngBytes()),
        mimeType: 'image/png',
      ),
    );
    addTearDown(() => ImagePickerPlatform.instance = previous);
  }

  Future<void> pickPoster(WidgetTester tester) async {
    await dragTo(tester, find.byType(ImagePickerOnTap), -600);
    await tester.tap(find.byType(ImagePickerOnTap));
    await settle(tester, frames: 10);
  }

  /// The duplicate-generating path of 28/09: the event WAS created and only the
  /// poster failed. The page used to report "Error while adding" and stay open,
  /// so the next publish created a second event.
  for (final outcome in ['throws', 'refused']) {
    testWidgets(
      'a created event whose poster $outcome names the image and leaves the form',
      (tester) async {
        final container = scaffold.makeContainer(
          myAssociations: [Association(name: 'BDE', groupId: 'g-1', id: 'a-1')],
        );
        addTearDown(container.dispose);
        scaffold.setWideSurface(tester);
        stubPosterPicker();

        when(() => scaffold.repository.feedNewsGet())
            .thenAnswer((_) async => chopperListResponse(<News>[]));
        var posts = 0;
        when(
          () =>
              scaffold.repository.calendarEventsPost(body: any(named: 'body')),
        ).thenAnswer((_) async {
          posts++;
          return chopperResponse(
            EventCompleteTicketUrl.empty().copyWith(id: 'e-new'),
          );
        });
        when(
          () => scaffold.repository.calendarEventsEventIdImagePost(
            eventId: any(named: 'eventId'),
            image: any(named: 'image'),
          ),
        ).thenAnswer((_) async {
          if (outcome == 'throws') throw Exception('upload refused');
          return chopper.Response<void>(
            http.Response('{"detail": "nope"}', 500),
            null,
          );
        });

        await scaffold.pumpApp(
          tester,
          container,
          initialPath: '/feed/add_edit_event',
          pumpAndSettle: false,
        );
        await settle(tester, frames: 40);
        await fillForm(tester);
        await pickPoster(tester);
        await submit(tester);

        // The event exists: one POST, the failure names the IMAGE, and the form
        // is gone so a second tap cannot create a duplicate.
        expect(posts, 1);
        expect(find.text('Error adding the image'), findsOneWidget);
        expect(find.text('Event added'), findsNothing);
        expect(find.text('Error while adding'), findsNothing);
        expect(find.text('Create an event'), findsNothing);
        await scaffold.drainToast(tester);
      },
    );
  }
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
