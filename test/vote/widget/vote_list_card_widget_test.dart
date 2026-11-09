import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/layouts/card_button.dart';
import 'package:titan/vote/providers/selected_list_provider.dart';
import 'package:titan/vote/providers/sections_provider.dart';
import 'package:titan/vote/providers/status_provider.dart';
import 'package:titan/vote/ui/pages/main_page/list_card.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';

/// One vote candidate card.
///
/// Two states the deep-linked pages never hold are the point here: a card
/// painted before the campaign status has landed (it must read as closed, so
/// no vote control appears) and a card whose vote button is pressed while
/// the section catalog is still loading (the selection must be skipped
/// rather than throwing).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<ProviderContainer> pumpCard(
    WidgetTester tester, {
    required List<dynamic> overrides,
  }) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
      providerOverrides: overrides,
    );
    addTearDown(container.dispose);
    final animation = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 200),
    );
    addTearDown(animation.dispose);
    await pumpWidgetAt(
      tester,
      ListCard(
        list: voteListFixture('l-1', 'BDE'),
        animation: animation,
        index: 0,
        enableVote: true,
        votesPercent: 0,
      ),
      container: container,
      // The card's row is built for the wide shell, not a phone.
      surface: const ui.Size(1200, 800),
    );
    // The card sits at the END of its slide-in until this controller runs:
    // at its start offset it is off the surface and cannot be tapped.
    animation.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return container;
  }

  testWidgets('a card painted before the status lands shows no vote control', (
    tester,
  ) async {
    await pumpCard(
      tester,
      overrides: [
        statusProvider.overrideWith(
          () => FakeVoteStatusNotifier(const AsyncValue.loading()),
        ),
      ],
    );

    expect(find.text('BDE'), findsOneWidget);
    // Closed is the fallback: the open-only vote row stays away.
    expect(find.byType(CardButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pressing vote before the section catalog lands selects nothing '
      'instead of throwing', (tester) async {
    final container = await pumpCard(
      tester,
      overrides: [
        statusProvider.overrideWith(
          () => FakeVoteStatusNotifier(
            const AsyncValue.data(VoteStatus(status: StatusType.open)),
          ),
        ),
        // The catalog is still loading, so the card's sections guard must
        // take its orElse arm and leave the selection alone.
        sectionsProvider.overrideWith(
          () => FakeSectionsNotifier(const AsyncValue.loading()),
        ),
      ],
    );

    expect(find.byType(CardButton), findsOneWidget);
    // The card's row sits right at the surface edge, so aim at the button's
    // own centre instead of the text finder's derived point.
    await tester.tapAt(tester.getCenter(find.byType(CardButton)));
    await tester.pump();

    // The guard skipped the selection: no list was chosen, nothing threw.
    expect(container.read(selectedListProvider).id, '');
    expect(tester.takeException(), isNull);
  });
}
