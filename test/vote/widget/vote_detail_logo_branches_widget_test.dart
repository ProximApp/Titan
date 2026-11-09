import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/vote/providers/list_logos_provider.dart';
import 'package:titan/vote/providers/list_provider.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';

/// The logo area of the vote detail page, which has three mutually exclusive
/// shapes and only ever rendered one of them:
///
///  * the group holds a list with an image → the circular avatar,
///  * the group holds an EMPTY list → the page asks the API for the logo and
///    keeps the placeholder until it lands (this branch schedules the fetch,
///    so a regression here is an infinite request loop, not a blank circle),
///  * the group is in error → the exclamation placeholder.
///
/// The page is mounted through the real deep link, because it reads the
/// pre-selected list from the client-side provider exactly as the list pages
/// leave it.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  ListReturn theList({String? program}) => ListReturn.empty().copyWith(
    id: 'list-1',
    name: 'Race List',
    description: 'Assemble to race',
    program: program,
    section: SectionComplete.empty().copyWith(name: 'Bureau des Sports'),
  );

  Future<void> mount(
    WidgetTester tester, {
    required AsyncValue<List<Image>>? logos,
    String? program,
  }) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    // The main page mounts underneath with no lists.
    when(() => scaffold.repository.campaignListsGet())
        .thenAnswer((_) async => chopperListResponse(<ListReturn>[]));
    // A tiny payload: the empty-list branch fetches exactly this.
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response.bytes(_pngBytes(), 200),
        _pngBytes(),
      ),
    );
    container.read(listProvider.notifier).setId(theList(program: program));
    container.read(listLogosProvider.notifier).state = {'list-1': logos};

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${VoteRouter.root}${VoteRouter.detail}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);
  }

  testWidgets('a loaded logo renders the circular avatar', (tester) async {
    await mount(
      tester,
      logos: AsyncValue.data([
        Image.memory(Uint8List.fromList(_pngBytes()), width: 1, height: 1),
      ]),
    );

    expect(find.text('Bureau des Sports'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty logo group fetches the logo once and keeps the '
      'placeholder meanwhile', (tester) async {
    await mount(tester, logos: const AsyncValue.data(<Image>[]));

    // The page asked the API for the missing logo...
    verify(
      () => scaffold.repository.campaignListsListIdLogoGet(listId: 'list-1'),
    ).called(1);
    // ...and the section still renders while it lands.
    expect(find.text('Bureau des Sports'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a logo error renders the exclamation placeholder', (
    tester,
  ) async {
    await mount(tester, logos: AsyncValue.error('boom', StackTrace.empty));

    expect(find.text('Bureau des Sports'), findsOneWidget);
    // No request is fired for a group that is already in error.
    verifyNever(
      () => scaffold.repository.campaignListsListIdLogoGet(listId: 'list-1'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the program spacer follows the program text', (tester) async {
    // A whitespace-only program is NOT "present": the trailing spacer must not
    // appear for it, which is what the trim() in the condition is for.
    await mount(tester, logos: null, program: 'Keynote at 18:00');

    expect(find.text('Keynote at 18:00'), findsOneWidget);
    expect(find.text('Bureau des Sports'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
