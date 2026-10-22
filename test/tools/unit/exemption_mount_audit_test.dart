import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/booking/ui/pages/main_page/main_page.dart';
import 'package:titan/cinema/ui/pages/admin_page/admin_page.dart';
import 'package:titan/event/ui/pages/main_page/main_page.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/purchases/ui/pages/scan_page/scan_dialog.dart';
import 'package:titan/seed-library/ui/pages/species_page/species_page.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixed_size_card_fixtures.dart';

/// The exemption MOUNT AUDIT: every card the suites exempt from mounting
/// gets an actual mount attempt here, and each exemption's CLAIM has to
/// survive the outcome.
///
/// Exemption reasons are prose — nothing in the suite could check them,
/// which is exactly how `ModuleCard` hid at 37/37 for several rounds on a
/// reason that was simply false. This file turns each claim into a
/// falsifiable assertion:
///
/// * **Technical claims** (`cardLayoutNotMountedExemptions` minus the
///   page/modal boundary entries, plus `notMountedExemptions`) say the card
///   CANNOT mount without page-level provider state. The attempt must FAIL,
///   and the recorded error must match the documented one. A mount that
///   comes up clean means the exemption is STALE — the failure message says
///   to delete it and mount the card for real.
/// * **Level-boundary claims** ("a PAGE", "a MODAL") do not assert
///   unmountability — they assert coverage at the integration level, so the
///   audit verifies the integration target named by the reason actually
///   exists, and prints what the mount attempt did for information.
///
/// The file lives under `tools/unit/` DELIBERATELY: the mount ratchet
/// counts constructors under `test/**/widget/` (and the shared registry)
/// as coverage, and this file mounts to PROBE claims, not to cover
/// layouts. An exemption this audit disproves still needs a real widget
/// test before the ratchet will count it.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Every exempted card, with the widget an attempt actually pumps.
  final mountables = <String, Widget Function()>{
    'lib/purchases/ui/pages/scan_page/scan_dialog.dart ScanDialog': () =>
        ScanDialog(
          ticket: GenerateTicketComplete.empty(),
          sellerId: 'seller-1',
          productId: 'product-1',
        ),
    'lib/booking/ui/pages/main_page/main_page.dart BookingMainPage': () =>
        const BookingMainPage(),
    'lib/cinema/ui/pages/admin_page/admin_page.dart AdminPage': () =>
        const AdminPage(),
    'lib/event/ui/pages/main_page/main_page.dart EventMainPage': () =>
        const EventMainPage(),
    'lib/seed-library/ui/pages/species_page/species_page.dart SpeciesPage':
        () => const SpeciesPage(),
  };

  /// Technical exemptions: the mount attempt must produce this substring —
  /// the error the reason says the card throws. Pinned to the documented
  /// claim, not to whatever the attempt happens to print.
  ///
  /// EMPTY today: loan's two admin sections were the last technical
  /// entries, and they left once `loanerProvider` stopped throwing `Bad
  /// state: No element` on an empty list — the audit recorded the sections
  /// mounting clean (under coverage, where the timing made it obvious the
  /// success was real, not a lost error) and failed the stale claims. The
  /// sections are now swept for real through `cardFixtures`.
  final expectedErrors = <String, String>{};

  /// Level-boundary exemptions: the claim is coverage elsewhere. A target
  /// may be a file or a directory of tests; `EventMainPage` allows either
  /// integration suite its reason names (event has none of its own).
  final integrationTargets = <String, List<String>>{
    'lib/purchases/ui/pages/scan_page/scan_dialog.dart ScanDialog': [
      'test/purchases/integration/purchases_scan_integration_test.dart',
    ],
    'lib/booking/ui/pages/main_page/main_page.dart BookingMainPage': [
      'test/booking/integration',
    ],
    'lib/cinema/ui/pages/admin_page/admin_page.dart AdminPage': [
      'test/cinema/integration',
    ],
    'lib/event/ui/pages/main_page/main_page.dart EventMainPage': [
      'test/event/integration',
      'test/feed/integration',
    ],
    'lib/seed-library/ui/pages/species_page/species_page.dart SpeciesPage': [
      'test/seed-library/integration',
    ],
  };

  bool targetPresent(String target) {
    final dir = Directory(target);
    if (dir.existsSync()) {
      return dir.listSync().any(
        (e) =>
            e.path.endsWith('.dart') &&
            e.statSync().type == FileSystemEntityType.file,
      );
    }
    return File(target).existsSync();
  }

  /// The endpoints these cards fetch on build (the same five image stubs
  /// the sweeps use): an unstubbed mocktail call throws where a Future is
  /// expected, and that noise must not mask the documented error.
  void stubImages() {
    final missing = chopper.Response(http.Response('', 404), <int>[]);
    when(
      () => scaffold.repository.associationsAssociationIdLogoGet(
        associationId: any(named: 'associationId'),
      ),
    ).thenAnswer((_) async => missing);
    when(
      () => scaffold.repository.advertAdvertsAdvertIdPictureGet(
        advertId: any(named: 'advertId'),
      ),
    ).thenAnswer((_) async => missing);
    when(
      () => scaffold.repository.cinemaSessionsSessionIdPosterGet(
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((_) async => missing);
    when(
      () => scaffold.repository
          .recommendationRecommendationsRecommendationIdPictureGet(
            recommendationId: any(named: 'recommendationId'),
          ),
    ).thenAnswer((_) async => missing);
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => missing);
  }

  /// Pumps [widget] once and reports what happened: whether the card
  /// itself landed in the tree, and every error the attempt recorded.
  /// Errors are captured at `FlutterError.onError` (the pinned-320px
  /// pattern) so a failing attempt records instead of failing the audit —
  /// the ASSERTIONS below decide what a recorded error means.
  Future<({bool mounted, List<String> errors})> attemptMount(
    WidgetTester tester,
    Widget widget,
  ) async {
    final errors = <String>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString());
    addTearDown(() => FlutterError.onError = previousOnError);

    final container = scaffold.makeContainer();
    var disposed = false;
    addTearDown(() {
      if (!disposed) container.dispose();
    });
    stubImages();
    seedSharedMaps(container);

    // Riverpod delivers a provider's async build errors through the ZONE's
    // uncaught-error channel, not through FlutterError.onError: a late
    // delivery reaches the test binding's `_pendingExceptionDetails`
    // assertion and fails the audit with the wrong error. Fork a guarded
    // zone for the whole attempt — INCLUDING the unmount, where the last
    // pending provider futures settle — so both channels land in `errors`.
    late bool mounted;
    await runZonedGuarded(() async {
      await scaffold.pumpWidgetApp(
        tester,
        Scaffold(body: SingleChildScrollView(child: widget)),
        container,
        appFonts: true,
      );
      await settle(tester, frames: 2);

      // Provider builds fan out across `await`s; their errors land in the
      // error channel one or two microtask turns after the last frame. Pump
      // a couple more frames WHILE THE FILTER IS STILL INSTALLED, or the
      // late delivery reaches the restored handler and fails the test with
      // the binding's `_pendingExceptionDetails` assertion instead of being
      // recorded as the documented error.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      mounted = find.byType(widget.runtimeType).evaluate().length == 1;
      await scaffold.unmountApp(tester);
      // Dispose HERE, inside the guarded zone: a teardown-registered
      // dispose would run after this zone is gone, and the last pending
      // provider futures it settles would fail the test with the binding's
      // `_pendingExceptionDetails` assertion instead of being recorded.
      container.dispose();
      disposed = true;
      await tester.pump(const Duration(milliseconds: 50));
    }, (e, s) => errors.add(e.toString()));

    final snapshot = List<String>.of(errors);
    FlutterError.onError = previousOnError;
    return (mounted: mounted, errors: snapshot);
  }

  test('every exemption is classified and has a mount attempt', () {
    final exempted = {
      ...notMountedExemptions.keys,
      ...cardLayoutNotMountedExemptions.keys,
    };
    final classified = {...expectedErrors.keys, ...integrationTargets.keys};

    expect(
      classified.difference(exempted),
      isEmpty,
      reason:
          'the audit classifies an exemption that no longer exists; '
          'delete the stale entry above.',
    );
    expect(
      exempted.difference(classified),
      isEmpty,
      reason:
          'a new exemption landed without a mount attempt or a coverage '
          'claim — classify it here or it is ModuleCard all over again.',
    );
    expect(
      mountables.keys.toSet(),
      exempted,
      reason:
          'every exempted card must have a builder in this file or it '
          'is not actually being audited.',
    );
    expect(exempted, isNotEmpty, reason: 'the audit must have cards to probe');
  });

  for (final entry in {
    ...notMountedExemptions,
    ...cardLayoutNotMountedExemptions,
  }.entries) {
    final id = entry.key;
    final reason = entry.value;
    final expected = expectedErrors[id];

    if (expected != null) {
      testWidgets('technical exemption holds: $id', (tester) async {
        final result = await attemptMount(tester, mountables[id]!());

        if (result.errors.isEmpty && result.mounted) {
          fail(
            'STALE EXEMPTION: $id mounted clean at 360px, so its reason '
            '("…$reason…") is false — the ModuleCard pattern. Delete the '
            'entry and mount the card in a widget test so the ratchet '
            'counts it.',
          );
        }
        expect(
          result.errors,
          anyElement(contains(expected)),
          reason:
              '$id failed, but NOT for the documented reason (expected an '
              'error containing "$expected"). Either the card changed or '
              'the exemption reason is now wrong. Recorded: ${result.errors}',
        );
      });
    } else {
      testWidgets('level-boundary exemption: $id', (tester) async {
        final targets = integrationTargets[id]!;
        expect(
          targets.any(targetPresent),
          isTrue,
          reason:
              '$id is exempted as "covered at integration level", but none '
              'of its targets exist: $targets — the coverage claim is '
              'hollow.',
        );

        final result = await attemptMount(tester, mountables[id]!());
        // The mount is attempted for the record only: the claim under test
        // is the coverage, not unmountability. Both outcomes are printed.
        print(
          'AUDIT $id: '
          '${result.mounted && result.errors.isEmpty ? "mounted clean" : "errors: ${result.errors}"}',
        );
      });
    }
  }
}
