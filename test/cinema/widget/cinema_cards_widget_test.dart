import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/cinema/ui/cinema.dart';
import 'package:titan/cinema/ui/pages/admin_page/admin_session_card.dart';
import 'package:titan/cinema/ui/pages/main_page/session_card.dart';
import 'package:titan/cinema/ui/pages/session_pages/tmdb_button.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/widgets/loader.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level tests for the cinema shell and its cards.
///
/// The fixed-width sweep mounts `SessionCard` and `AdminSessionCard`, but
/// only with a long `name` and every other field empty — the shape a
/// generator produces. This file mounts the same cards with the content a
/// real TMDB record carries (a tagline, a genre, a multi-hour runtime, a
/// synopsis) and adds the two widgets the sweep has no reason to know about:
/// the page shell `CinemaTemplate` and the `TmdbButton` pill.
///
/// `SessionCard` has two entirely different layouts behind
/// `isWebFormatProvider`, which flips at a 500px safe width. Testing only
/// one of them would leave half the card unmeasured, so both are mounted —
/// each at a surface where the provider really does return true or false,
/// rather than by forcing the flag against the width it derives from.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// `HeroIcon` draws an `SvgPicture.string`, not a Material `Icon`, so
  /// `find.byIcon` never sees it — the widget itself has to be matched.
  Finder heroIcon(HeroIcons icon) => find.byWidgetPredicate(
    (w) => w is HeroIcon && w.icon == icon,
    description: 'HeroIcon($icon)',
  );

  const longMovieName =
      'Les aventures extraordinaires de Jean-Baptiste Delaunay Deserialize';
  const longOverview =
      'Un synopsis bien plus long que la moyenne, parce que TMDB accepte '
      'des descriptions de plusieurs phrases et que la carte les affiche en '
      'entier dans la colonne de droite.';

  final missingPoster = chopper.Response(http.Response('', 404), <int>[]);

  /// The poster and the topic list. The poster is what turns a 404 into the
  /// bundled logo asset, and the topics decide whether the card draws its
  /// bell badge. Unstubbed, either one returns null where a Future is
  /// expected and the card dies before it lays out.
  void stubSessionLoads({List<TopicUser> topics = const []}) {
    when(
      () => scaffold.repository.cinemaSessionsSessionIdPosterGet(
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((_) async => missingPoster);
    when(
      () => scaffold.repository.notificationTopicsGet(),
    ).thenAnswer((_) async => chopperListResponse(topics));
  }

  CineSessionComplete session({
    String name = longMovieName,
    String overview = longOverview,
    int duration = 145,
    DateTime? start,
  }) => CineSessionComplete.empty().copyWith(
    id: 's-1',
    name: name,
    overview: overview,
    tagline: 'A tagline that is also longer than usual',
    genre: 'Science fiction',
    // 145 minutes is 2h 25min: the "Xh Ymin" branch, not the short one.
    duration: duration,
    start: start ?? DateTime(2100, 12, 24, 20, 30),
  );

  testWidgets('the session card fits a full record in the phone branch', (
    tester,
  ) async {
    stubSessionLoads();
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: SessionCard(session: session(), index: 0),
        ),
      ),
      container,
      appFonts: true,
    );
    await settle(tester, frames: 4);

    expect(find.byType(SessionCard), findsOneWidget);
    // The phone branch prints the date and the duration under the title.
    expect(find.textContaining('24/12/2100 - 20h30'), findsOneWidget);
    expect(find.text('2h 25min'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the session card fits a full record in the web branch', (
    tester,
  ) async {
    // A 900px surface, so isWebFormatProvider really returns true: the card
    // then pads by 50 on every side and lays the poster out beside the text
    // instead of behind it.
    stubSessionLoads();
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: SessionCard(session: session(), index: 0),
        ),
      ),
      container,
      surface: const Size(900, 700),
      appFonts: true,
    );
    await settle(tester, frames: 4);

    expect(find.byType(SessionCard), findsOneWidget);
    // The web branch is the only one that prints the overview, because the
    // phone branch hides it behind the poster.
    expect(find.text(longOverview), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the session card fits its notification badge', (tester) async {
    // A subscribed session draws an 80x60 black badge pinned to the poster's
    // top right, but only when the session has not started yet.
    stubSessionLoads(
      topics: [TopicUser.empty().copyWith(id: 's-1', name: longMovieName)],
    );
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: SessionCard(
            session: session(start: DateTime(2100, 1, 1)),
            index: 0,
          ),
        ),
      ),
      container,
      appFonts: true,
    );
    await settle(tester, frames: 4);

    expect(find.byType(SessionCard), findsOneWidget);
    expect(heroIcon(HeroIcons.bell), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the admin session card fits a full record', (tester) async {
    // 155x300 with a 95px info box: the name gets two AutoSizeText lines and
    // the edit/delete buttons share the rest.
    stubSessionLoads();
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: AdminSessionCard(
            session: session(),
            onTap: () {},
            onEdit: () {},
            onDelete: () async {},
          ),
        ),
      ),
      container,
      appFonts: true,
    );
    await settle(tester, frames: 4);

    expect(find.byType(AdminSessionCard), findsOneWidget);
    expect(heroIcon(HeroIcons.pencil), findsOneWidget);
    expect(heroIcon(HeroIcons.trash), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the tmdb pill fits an icon and a loader', (tester) async {
    // The pill is the add/edit session field's suffix: an arrow icon when
    // idle, a Loader while the TMDB lookup runs. Both children are fixed
    // size, which is the only reason the pill is stable.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: Column(
          children: [
            const TmdbButton(
              child: HeroIcon(
                HeroIcons.arrowRight,
                size: 22,
                color: Colors.black,
              ),
            ),
            const TmdbButton(child: Loader()),
          ],
        ),
      ),
      container,
      appFonts: true,
    );
    await settle(tester, frames: 4);

    expect(find.byType(TmdbButton), findsNWidgets(2));
    expect(find.byType(Loader), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the cinema shell fits a tall child at 360', (tester) async {
    // CinemaTemplate is a Column with a TopBar and an Expanded body — the one
    // shape in the module whose height math depends on the surface, and the
    // page the integration tests only ever open at desktop width.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      CinemaTemplate(
        child: ListView(
          children: List.generate(
            12,
            (i) => SizedBox(height: 120, child: Text('Session $i')),
          ),
        ),
      ),
      container,
      appFonts: true,
    );
    await settle(tester, frames: 4);

    expect(find.byType(CinemaTemplate), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
