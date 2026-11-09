import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/vote/providers/selected_list_provider.dart';
import 'package:titan/vote/providers/status_provider.dart';
import 'package:titan/vote/providers/voted_section_provider.dart';
import 'package:titan/vote/providers/votes_provider.dart';
import 'package:titan/vote/ui/pages/main_page/vote_button.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';

/// `VoteButton` — the campaign's single vote action, which no test mounted
/// before (its route to a tap needs a chosen list AND an open status, so the
/// page shells never get there).
///
/// Covers the three things the button derives from provider state: which
/// label it shows for each campaign status (waiting / closed / counting),
/// the `orElse` that keeps a still-loading vote history from reading as
/// "already voted", and the tap → dialog → confirm journey down its error
/// branch, where the vote is refused and the failure toast is shown instead
/// of the vote being recorded.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<ProviderContainer> pumpButton(
    WidgetTester tester, {
    required AsyncValue<VoteStatus> status,
    ListReturn? selected,
    bool votesAccepted = false,
    List<dynamic> extraOverrides = const [],
  }) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
      providerOverrides: [
        statusProvider.overrideWith(() => FakeVoteStatusNotifier(status)),
        votesProvider.overrideWith(() => FakeVotesNotifier(votesAccepted)),
        ...extraOverrides,
      ],
    );
    addTearDown(container.dispose);
    if (selected != null) {
      container.read(selectedListProvider.notifier).changeSelection(selected);
    }
    await pumpWidgetAt(
      tester,
      const VoteButton(),
      container: container,
      surface: const ui.Size(400, 400),
    );
    return container;
  }

  testWidgets('an open campaign with no vote history still offers the list '
      'choice instead of claiming a vote', (tester) async {
    // The real vote-history notifier starts LOADING; the button's orElse must
    // read that as "nothing voted yet", not as an already-cast vote.
    await pumpButton(
      tester,
      status: const AsyncValue.data(VoteStatus(status: StatusType.open)),
    );

    expect(find.text('Choose a list'), findsOneWidget);
    expect(find.text('You already voted'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a closed campaign says so, and counting says it is counting', (
    tester,
  ) async {
    await pumpButton(
      tester,
      status: const AsyncValue.data(VoteStatus(status: StatusType.closed)),
    );
    expect(find.text('Votes closed'), findsOneWidget);
  });

  testWidgets('a counting campaign is labelled as counting in progress', (
    tester,
  ) async {
    await pumpButton(
      tester,
      status: const AsyncValue.data(VoteStatus(status: StatusType.counting)),
    );
    expect(find.text('Counting in progress'), findsOneWidget);
  });

  testWidgets('a refusing backend keeps the vote out and shows the error '
      'toast', (tester) async {
    await pumpButton(
      tester,
      status: const AsyncValue.data(VoteStatus(status: StatusType.open)),
      selected: voteListFixture('l-1', 'BDE'),
    );
    expect(find.text('Vote for BDE'), findsOneWidget);

    // Tap the button: the confirmation dialog is the only way to the call.
    await tester.tap(find.text('Vote for BDE'));
    await settle(tester, frames: 6);
    expect(find.text('Confirm vote'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 8);

    expect(find.text('Error recording vote'), findsOneWidget);
    expect(find.text('Your vote has been recorded'), findsNothing);
    await scaffold.drainToast(tester);
  });

  testWidgets('a status that has not landed reads as closed', (tester) async {
    // The button paints before `campaignStatusGet` answers; the fallback must
    // be the closed label rather than an open-looking button.
    await pumpButton(tester, status: const AsyncValue.loading());

    expect(find.text('Votes closed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a campaign that has not opened votes says so', (tester) async {
    await pumpButton(
      tester,
      status: const AsyncValue.data(VoteStatus(status: StatusType.waiting)),
    );
    expect(find.text('Vote not opened'), findsOneWidget);
  });

  testWidgets('a vote history that failed still lets the voter choose', (
    tester,
  ) async {
    await pumpButton(
      tester,
      status: const AsyncValue.data(VoteStatus(status: StatusType.open)),
      extraOverrides: [
        votedSectionProvider.overrideWith(
          () => FakeVotedSectionNotifier(
            AsyncValue.error(Exception('offline'), StackTrace.empty),
          ),
        ),
      ],
    );
    expect(find.text('Choose a list'), findsOneWidget);
  });
}
