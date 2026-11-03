import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';

/// OpeningVote's remaining branches: the third destructive action (the
/// "Fake" / pipo delete, whose whole dialog chain was never exercised) and
/// the two error toasts — a rejected open and a rejected delete-all. The
/// status alone decides which controls render, so each case boots the page
/// in the waiting status through the same deep link.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpWaiting(WidgetTester tester, {bool withLists = true}) async {
    stubVoteAdmin(
      scaffold,
      status: enums.StatusType.waiting,
      lists: [if (withLists) voteListFixture('l-1', 'BDE')],
      // The list card auto-loads its logo.
      withResults: true,
    );
    final container = scaffold.makeContainer(user: voteAdminUserFixture());
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${VoteRouter.root}${VoteRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 20);
  }

  Future<void> pumpFrames(WidgetTester tester, [int frames = 10]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('the Fake-lists dialog deletes only the pipo type', (
    tester,
  ) async {
    await pumpWaiting(tester);

    expect(find.text('Fake'), findsOneWidget);
    await scaffold.ensureOnScreen(tester, find.text('Fake'));
    when(
      () => scaffold.repository.campaignListsDelete(
        listType: any(named: 'listType'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await tester.tap(find.text('Fake'));
    await pumpFrames(tester, 8);
    expect(find.text('Delete fake lists'), findsOneWidget);
    expect(
      find.text('Do you really want to delete the fake lists?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 12);

    // The typed delete reaches the endpoint with the pipo filter, and the
    // success toast confirms the branch.
    verify(
      () => scaffold.repository.campaignListsDelete(
        listType: any(named: 'listType'),
      ),
    ).called(1);
    expect(find.text('Fake lists deleted'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a rejected open and a rejected delete-all toast their errors', (
    tester,
  ) async {
    await pumpWaiting(tester);

    when(() => scaffold.repository.campaignStatusOpenPost())
        .thenAnswer((_) async => scaffold.repository.fail(500));
    when(
      () => scaffold.repository.campaignListsDelete(
        listType: any(named: 'listType'),
      ),
    ).thenAnswer((_) async => scaffold.repository.fail(500));

    // Open fails: the status stays waiting, so the opening panel remains
    // and the error toast replaces the success one.
    await scaffold.ensureOnScreen(tester, find.text('Open votes'));
    await tester.tap(find.text('Open votes'));
    await pumpFrames(tester, 12);
    verify(() => scaffold.repository.campaignStatusOpenPost()).called(1);
    expect(find.text('Error opening votes'), findsOneWidget);
    expect(find.text('Open votes'), findsOneWidget);
    await scaffold.drainToast(tester);

    // Delete-all fails the same way: the endpoint rejects and the error
    // toast fires instead of "All deleted".
    await scaffold.ensureOnScreen(tester, find.text('All'));
    await tester.tap(find.text('All'));
    await pumpFrames(tester, 8);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 12);

    verify(
      () => scaffold.repository.campaignListsDelete(
        listType: any(named: 'listType'),
      ),
    ).called(1);
    expect(find.text('Error deleting'), findsOneWidget);
    expect(find.text('All deleted'), findsNothing);
    await scaffold.drainToast(tester);

    // The pipo delete's own error branch: same rejected endpoint, and the
    // Fake dialog's toast fires the error variant.
    await scaffold.ensureOnScreen(tester, find.text('Fake'));
    await tester.tap(find.text('Fake'));
    await pumpFrames(tester, 8);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 12);
    expect(find.text('Error deleting'), findsOneWidget);
    expect(find.text('Fake lists deleted'), findsNothing);
    await scaffold.drainToast(tester);
  });
}
