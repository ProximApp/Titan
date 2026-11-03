import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/providers/tombola_logos_provider.dart';
import 'package:titan/raffle/ui/pages/creation_edit_page/ticket_handler.dart';
import 'package:titan/raffle/ui/pages/creation_edit_page/ticket_ui.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/image_stub.dart';
import '../../shared/repository_stubs.dart';
import '../../shared/repository_test_support.dart' show chopperError;
import '../raffle_fixtures.dart';

/// The raffle edit page's remaining edges (`/tombola/detail/creation`):
/// * its pull-to-refresh, which reloads cash, pack tickets and prizes,
/// * the picture journey — a picked logo previews from memory and, on save,
///   is uploaded before the page returns to the detail,
/// * the ticket strip's failed delete (error toast) and its list's
///   error/loading arms.
///
/// Dark lines still left, both proven unreachable:
/// * `ui/pages/creation_edit_page/creation_edit_page.dart:219-220` — the save
///   button only runs when `raffle.status` is `creation`, and `raffle` comes
///   from the very list whose `when` is read here, so the captured value is
///   always data.
/// * `ui/pages/creation_edit_page/prize_handler.dart:238` — `drawPrize`
///   returns `AsyncData` or `AsyncError` only.
final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(
      name: 'admin_raffle',
      id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
    ),
  ],
);

/// A decodable one-pixel PNG: small enough that the upload path keeps it
/// untouched, real enough that `Image.memory` accepts it.
Uint8List onePixelPng() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpCreation(
    WidgetTester tester, {
    List<PackTicketSimple> packTickets = const [],
    bool failPackTickets = false,
    bool holdPackTickets = false,
  }) async {
    stubCreationData(scaffold, packTickets: packTickets, withRaffleTickets: true);
    if (failPackTickets) {
      when(
        () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
          raffleId: any(named: 'raffleId'),
        ),
      ).thenAnswer((_) async => chopperError<List<PackTicketSimple>>(500));
    } else if (holdPackTickets) {
      when(
        () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
          raffleId: any(named: 'raffleId'),
        ),
      ).thenAnswer(
        (_) => Completer<List<PackTicketSimple>>().future.then(
          (value) => chopperListResponse(value),
        ),
      );
    }
    when(
      () => scaffold.repository.tombolaRafflesRaffleIdLogoGet(
        raffleId: any(named: 'raffleId'),
      ),
    ).thenAnswer((_) async => fileNotFound());

    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(user: adminUser);
    addTearDown(container.dispose);
    container.read(raffleIdProvider.notifier).setId('r-1');
    container
        .read(tombolaLogosProvider.notifier)
        .setTData('r-1', AsyncData([Image.memory(onePixelPng())]));
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tombola/detail/creation',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
    expect(QR.currentPath, '/tombola/detail/creation');
  }

  testWidgets('pull to refresh reloads cash, pack tickets and prizes', (
    tester,
  ) async {
    await pumpCreation(tester);

    clearInteractions(scaffold.repository);
    await tester.drag(find.byType(Refresher), const Offset(0, 400));
    await settle(tester, frames: 24);

    verify(() => scaffold.repository.tombolaUsersCashGet()).called(1);
    verify(
      () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
        raffleId: 'r-1',
      ),
    ).called(1);
    verify(
      () => scaffold.repository.tombolaRafflesRaffleIdPrizesGet(
        raffleId: 'r-1',
      ),
    ).called(1);
  });

  testWidgets('a picked logo previews from memory and uploads on save', (
    tester,
  ) async {
    when(
      // ignore: void_checks
      () => scaffold.repository.tombolaRafflesRaffleIdPatch(
        raffleId: any(named: 'raffleId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    when(
      () => scaffold.repository.tombolaRafflesRaffleIdLogoPost(
        raffleId: any(named: 'raffleId'),
        image: any(named: 'image'),
      ),
    ).thenAnswer(
      (_) async => chopperResponse(AppTypesStandardResponsesResult.empty()),
    );

    final previous = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = StubImagePicker(
      next: XFile.fromData(onePixelPng(), mimeType: 'image/png'),
    );
    addTearDown(() => ImagePickerPlatform.instance = previous);

    await pumpCreation(tester);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.photo,
      ),
    );
    await settle(tester, frames: 16);

    // The preview now draws the picked bytes: the circle's DecorationImage
    // switched from the loaded file to an in-memory provider.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).image?.image is MemoryImage,
      ),
      findsOneWidget,
    );

    await scaffold.ensureOnScreen(tester, find.text('Edit'));
    await tester.tap(find.text('Edit'));
    await settle(tester, frames: 24);

    verify(
      () => scaffold.repository.tombolaRafflesRaffleIdPatch(
        raffleId: 'r-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    verify(
      () => scaffold.repository.tombolaRafflesRaffleIdLogoPost(
        raffleId: 'r-1',
        image: any(named: 'image'),
      ),
    ).called(1);
    expect(QR.currentPath, '/tombola/detail');
  });

  testWidgets('a picture too big to compress is refused with a toast', (
    tester,
  ) async {
    final previous = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = StubImagePicker(
      next: XFile.fromData(
        Uint8List(1024 * 1024 + 4096),
        name: 'big.bin',
        mimeType: 'application/octet-stream',
      ),
    );
    addTearDown(() => ImagePickerPlatform.instance = previous);

    await pumpCreation(tester);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.photo,
      ),
    );
    // The compressor runs on a real isolate for a payload over the cap.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await settle(tester, frames: 12);

    expect(
      find.text('This image could not be compressed enough to be uploaded'),
      findsOneWidget,
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('a failed ticket delete reports the error', (tester) async {
    final ticket = PackTicketSimple.empty().copyWith(
      id: 'pt-1',
      price: 25,
      packSize: 10,
      raffleId: 'r-1',
    );
    when(
      // ignore: void_checks
      () => scaffold.repository.tombolaPackTicketsPackticketIdDelete(
        packticketId: any(named: 'packticketId'),
      ),
    ).thenAnswer((_) async => chopperError<void>(500));

    await pumpCreation(tester, packTickets: [ticket]);

    await tester.tap(
      find.descendant(
        of: find.byType(TicketUI),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.trash,
        ),
      ),
    );
    await settle(tester, frames: 12);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 16);

    expect(find.text('Error during deletion'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('the ticket strip reports a failed pack-ticket list', (
    tester,
  ) async {
    await pumpCreation(tester, failPackTickets: true);

    expect(
      find.descendant(
        of: find.byType(TicketHandler),
        matching: find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').startsWith('Error:'),
        ),
      ),
      findsWidgets,
    );
  });

  testWidgets('the ticket strip spins while its list loads', (tester) async {
    await pumpCreation(tester, holdPackTickets: true);

    expect(
      find.descendant(
        of: find.byType(TicketHandler),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsWidgets,
    );
  });
}
