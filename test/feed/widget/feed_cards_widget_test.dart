import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/feed/ui/pages/association_events_page/association_event_card.dart';
import 'package:titan/feed/ui/pages/main_page/event_action.dart';
import 'package:titan/feed/ui/pages/main_page/event_card.dart';
import 'package:titan/feed/ui/widgets/adaptive_text_card.dart';
import 'package:titan/feed/ui/widgets/event_card_text_content.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
// The MODELS barrel on purpose: the umbrella `openapi.swagger.dart` also
// exports a `Size` ENUM, which shadows dart:ui's Size for every measurement.
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level tests for the feed cards the fixed-width sweep could not
/// reach. It mounts `TimelineItem` and `AdminEventCard`; this file covers
/// the rest of the module's leaf widgets — the timeline banner `EventCard`,
/// its text content, the `EventAction` call-to-action row, the
/// `AssociationEventCard` list row, and the `AdaptiveTextCard` that picks
/// the banner's text colour.
///
/// `EventCard` is the one worth reading first: it is an `AspectRatio`
/// banner (851x315, so 133px tall at 360 wide) with a `Positioned` badge
/// pinned 53px above the bottom, and its image is fetched through an
/// `AutoLoaderChild` that fires a repository call on the first build. Left
/// unstubbed the call returns null where a Future is expected and the card
/// dies before it lays out — which would make "no overflow" true for the
/// wrong reason.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  const longTitle =
      'Conference annuelle de l association des etudiants en medecine';

  /// A 404 for the banner image: the news bytes read as empty and the card
  /// falls back to its gradient placeholder, which is the branch that has to
  /// be exercised anyway (it is the one with no DecorationImage).
  final missingImage = chopper.Response(http.Response('', 404), <int>[]);

  void stubNewsImage() {
    when(
      () => scaffold.repository.feedNewsNewsIdImageGet(
        newsId: any(named: 'newsId'),
      ),
    ).thenAnswer((_) async => missingImage);
  }

  News news({
    String? title,
    String? location,
    DateTime? start,
    DateTime? end,
  }) => News.empty().copyWith(
    id: 'n-1',
    title: title ?? longTitle,
    location: location,
    start: start ?? DateTime(2020),
    end: end,
    entity: 'association',
    module: 'event',
    moduleObjectId: 'object-1',
    status: enums.NewsStatus.published,
  );

  testWidgets(
    'the timeline banner fits without an image, in every badge state',
    (tester) async {
      // The badge is Positioned at bottom: 53 — inside the 133px banner, so the
      // shape to watch is the badge against a short banner, not a tall one.
      // Ongoing/terminated/quiet are the three branches of the two `if`s.
      final states = <(String, News)>[
        ('ongoing', news(start: DateTime(2020), end: DateTime(2100))),
        ('terminated', news(start: DateTime(2020), end: DateTime(2021))),
        ('quiet', news(start: DateTime(2100))),
      ];

      for (final (label, item) in states) {
        final container = scaffold.makeContainer();
        addTearDown(container.dispose);
        stubNewsImage();

        await scaffold.pumpWidgetApp(
          tester,
          Scaffold(
            body: SingleChildScrollView(child: EventCard(item: item)),
          ),
          container,
          appFonts: true,
        );
        await settle(tester, frames: 4);

        expect(find.byType(EventCard), findsOneWidget, reason: label);
        // 851/315 at 360 wide: the banner keeps the ratio the design asks for.
        expect(
          tester.getSize(find.byType(EventCard)).height,
          closeTo(360 * 315 / 851, 1),
          reason: label,
        );
        expect(tester.takeException(), isNull, reason: 'event card ($label)');

        await scaffold.unmountApp(tester);
      }
    },
  );

  testWidgets('the banner text content fits its width-minus-140 box', (
    tester,
  ) async {
    // EventCardTextContent hardcodes `size.width - 140`, so at 360 it has
    // 220px for a title and a location on ONE line. The title is truncated
    // to 30 chars + "..." first, and the location takes what is left.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: EventCardTextContent(
            item: news(
              location: 'Amphitheatre Borda, campus de Pessac, Gironde',
            ),
            // Dead parameter: the widget takes it and never reads it, the
            // subtitle going through `context` instead. Passing null is
            // therefore honest about the shape, not a workaround.
            localizeWithContext: null,
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(EventCardTextContent), findsOneWidget);
    // 30 characters of title then an ellipsis, by substring rather than by
    // TextOverflow — the cut is done in Dart before the widget sees it.
    expect(
      find.textContaining('${longTitle.substring(0, 30)}...'),
      findsOneWidget,
    );
    expect(find.textContaining('Amphitheatre Borda'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the banner text content fits a short title with no location', (
    tester,
  ) async {
    // The other branch of the location `if`: no Expanded child at all, and
    // a title short enough to skip the substring truncation.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: EventCardTextContent(
            item: news(title: 'Short title', location: null),
            localizeWithContext: null,
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.text('Short title'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the action row fits long labels in all four button states', (
    tester,
  ) async {
    // The button is a fixed 100px wide with 12px of horizontal padding, so
    // 76px of text: a translated label longer than that has to ellipsize
    // rather than push the Row over. Four states, because the four label
    // sources are four different strings.
    final states = <(String, EventAction)>[
      (
        'enabled',
        EventAction(
          title: 'A long title that has to shrink or ellipsize',
          subtitle: 'A long subtitle that has to shrink or ellipsize too',
          actionEnableButtonText: 'Participer',
          actionValidatedButtonText: 'Inscrit',
          isActionValidated: false,
          isDisabled: false,
          timeOpening: DateTime(2020),
          eventEnd: DateTime(2100),
          waitingTitle: (s) => 'Ouverture dans $s',
        ),
      ),
      (
        'validated',
        EventAction(
          title: 'A long title that has to shrink or ellipsize',
          subtitle: 'A long subtitle that has to shrink or ellipsize too',
          actionEnableButtonText: 'Participer',
          actionValidatedButtonText: 'Deja inscrit',
          isActionValidated: true,
          isDisabled: false,
          timeOpening: DateTime(2020),
          eventEnd: DateTime(2100),
          waitingTitle: (s) => 'Ouverture dans $s',
        ),
      ),
      (
        'disabled',
        EventAction(
          title: 'A long title that has to shrink or ellipsize',
          subtitle: 'A long subtitle that has to shrink or ellipsize too',
          actionEnableButtonText: 'Participer',
          actionValidatedButtonText: 'Inscrit',
          isActionValidated: false,
          isDisabled: true,
          disabledLabel: 'Termine',
          timeOpening: DateTime(2020),
          eventEnd: DateTime(2100),
          waitingTitle: (s) => 'Ouverture dans $s',
        ),
      ),
      (
        // Waiting swaps the title for the l10n "get ready" line and puts a
        // Timeago (with its own 1s refresh timer) where the subtitle was.
        'waiting',
        EventAction(
          title: 'unused while waiting',
          subtitle: 'unused while waiting',
          actionEnableButtonText: 'Participer',
          actionValidatedButtonText: 'Inscrit',
          isActionValidated: false,
          isDisabled: false,
          timeOpening: DateTime.now().add(const Duration(days: 400)),
          eventEnd: DateTime(2100),
          waitingTitle: (s) => 'Ouverture dans $s',
        ),
      ),
    ];

    for (final (label, action) in states) {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        Scaffold(body: SingleChildScrollView(child: action)),
        container,
        appFonts: true,
      );

      expect(find.byType(EventAction), findsOneWidget, reason: label);
      expect(tester.takeException(), isNull, reason: 'event action ($label)');

      // The row arms a 1s Timer.periodic (and Timeago a second one); the
      // only way to retire it is to unmount, which is also what proves no
      // timer is left pending at the end of the test.
      await scaffold.unmountApp(tester);
    }
  });

  testWidgets('the association event row fits a long name and location', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: AssociationEventCard(
            event: EventCompleteTicketUrl.empty().copyWith(
              id: 'e-1',
              name: longTitle,
              location: 'Amphitheatre Borda, campus de Pessac, Gironde',
              start: DateTime(2100),
              end: DateTime(2100, 1, 2),
            ),
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(AssociationEventCard), findsOneWidget);
    expect(find.text(longTitle), findsOneWidget);
    expect(
      find.text('Amphitheatre Borda, campus de Pessac, Gironde'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the adaptive text card mounts with and without an image', (
    tester,
  ) async {
    // With no image the dominant-colour notifier resolves to null without
    // touching the codec; the image branch is the one that decodes, so the
    // app's own bundled logo is used — the very asset `Image.asset` falls back
    // to when a banner has no bytes.
    for (final hasImage in [false, true]) {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              height: 120,
              child: AdaptiveTextCard(
                hasImage: hasImage,
                imageProvider: hasImage
                    ? const AssetImage('assets/images/logo_prod.webp')
                    : null,
                child: const Text(longTitle),
              ),
            ),
          ),
        ),
        container,
        appFonts: true,
      );
      await settle(tester, frames: 4);

      expect(find.byType(AdaptiveTextCard), findsOneWidget);
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
    }
  });
}
