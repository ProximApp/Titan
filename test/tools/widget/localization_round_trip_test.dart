import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/card_fixtures.dart';
import '../../shared/fixed_size_card_fixtures.dart';

/// The localization round-trip: every card the fixed-size sweeps mount,
/// rendered TWICE at 360px — once against the English arb, once against the
/// French one — so a translation that is wider than the layout the English
/// labels were measured in fails HERE instead of shipping.
///
/// Flutter never falls back to a smaller box for a longer string: a `Row`
/// child laid out with French text is exactly as unbounded as it is with
/// English text, and the harness's overflow assertion is fatal (convention
/// 20 — the app's real Lato faces measure the glyphs, so the widths are the
/// device's). The suite has always measured English: ledger #48 found the
/// purchases header was already 319px against 300px in FRENCH while the
/// English run stayed green, and that card only broke in the locale a real
/// MyEM user reads.
///
/// The corpus is [cardFixtures] — the same mounted set the width sweep
/// ratchets against, so "every card this suite knows how to mount" stays one
/// list. The five `notMountedExemptions` are skipped for the same reason the
/// width sweep skips them: their content comes from provider maps no shared
/// container seeds, locale-independent.
///
/// Each test also asserts the card resolved the locale it was pumped with —
/// a MaterialApp that ignored the parameter would render English twice and
/// the second pass would prove nothing, which is the vacuous-green failure
/// mode this file exists to avoid.
const _locales = [Locale('en', 'US'), Locale('fr', 'FR')];

/// A 404 for every logo/picture the cards request on mount: the image
/// widgets render their error state and nothing reaches the network.
final _missingImage = chopper.Response(http.Response('', 404), <int>[]);

void main() {
  late IntegrationScaffold scaffold;

  // Prime both arb libraries BEFORE the first test: AppLocalizations loads
  // through the deferred-import loadLibrary(), and under flutter_test's
  // fake async only the first genuine library load in a file ever completes
  // — every later one waits for a real event-loop turn that fake pumps never
  // give it, leaving Localizations._locale null and the card replaced by
  // SizedBox.shrink(). setUpAll runs in the real zone, so both loads finish
  // there and every in-test load resolves as an already-completed future.
  setUpAll(() async {
    await lookupAppLocalizations(const Locale('en', 'US'));
    await lookupAppLocalizations(const Locale('fr', 'FR'));
  });

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// The endpoints the cards fetch while building — same five as the width
  /// sweep's, because the corpus is the same.
  void stubCardImages() {
    when(
      () => scaffold.repository.associationsAssociationIdLogoGet(
        associationId: any(named: 'associationId'),
      ),
    ).thenAnswer((_) async => _missingImage);
    when(
      () => scaffold.repository.advertAdvertsAdvertIdPictureGet(
        advertId: any(named: 'advertId'),
      ),
    ).thenAnswer((_) async => _missingImage);
    when(
      () => scaffold.repository.cinemaSessionsSessionIdPosterGet(
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((_) async => _missingImage);
    when(
      () => scaffold.repository
          .recommendationRecommendationsRecommendationIdPictureGet(
            recommendationId: any(named: 'recommendationId'),
          ),
    ).thenAnswer((_) async => _missingImage);
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => _missingImage);
    // The two endpoints the seed-library/vote cards fetch on build: their
    // providers' build() calls them and OVERWRITE a state seed once the
    // future lands, so the data has to come from the repository.
    when(() => scaffold.repository.seedLibrarySpeciesGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), speciesMap),
    );
    when(() => scaffold.repository.campaignSectionsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), [
        SectionComplete.empty().copyWith(id: 'section-1', name: 'Section 1'),
      ]),
    );
  }

  for (final locale in _locales) {
    group('${locale.languageCode} round-trip at 360px', () {
      for (final card in cardFixtures) {
        final id = '${card.source} ${card.className}';
        if (notMountedExemptions.containsKey(id)) continue;

        testWidgets('$id renders in ${locale.languageCode}', (tester) async {
          final container = scaffold.makeContainer(
            myStructures: [structure('structure-1', longName, 'user-1')],
          );
          stubCardImages();
          // Seed AFTER the stubs: reading a provider's notifier fires its
          // build()'s repository fetch on the spot, so a stub registered
          // afterwards would miss that call.
          seedSharedMaps(container);
          addTearDown(container.dispose);

          final anim = AnimationController(
            vsync: const TestVSync(),
            duration: const Duration(milliseconds: 200),
            value: 1,
          );
          addTearDown(anim.dispose);

          final cardWidget = card.build(container, anim);
          await scaffold.pumpWidgetApp(
            tester,
            Scaffold(
              body:
                  card.wrap?.call(cardWidget) ??
                  SingleChildScrollView(child: cardWidget),
            ),
            container,
            appFonts: true,
            locale: locale,
          );
          await settle(tester, frames: 4);

          // Non-vacuity twice over: the card mounted (an unstubbed fetch
          // would leave the tree empty and make "no overflow" true for the
          // wrong reason)...
          expect(
            find.byType(card.type),
            findsOneWidget,
            reason:
                '$id did not mount in ${locale.languageCode}: either it '
                'threw during build, or the fixture it needs is missing.',
          );
          // ...and it resolved the locale this pass claims to measure —
          // otherwise both passes render English and the round-trip is one
          // test pretending to be two.
          expect(
            Localizations.localeOf(tester.element(find.byType(card.type))),
            locale,
            reason:
                '$id resolved a different locale than ${locale.languageCode} '
                '- the round-trip would measure the same strings twice.',
          );

          await scaffold.unmountApp(tester);
        });
      }
    });
  }
}
