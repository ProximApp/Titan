import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/vote/router.dart';
import 'package:titan/vote/ui/pages/admin_page/section_bar.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';

/// The section strip's leading + chip (`section_bar.dart` lines 41-43): in
/// waiting status the strip starts with an ItemChip whose plus routes to
/// the deferred add-section form — the only branch of firstChild the
/// status gate opens.
///
/// Own file (convention 19): qlevar keeps the active route branch in
/// process-global state, so a second router-driven hop in the same isolate
/// never renders its page. vote_admin_section_list_flows owns the
/// non-navigating strip dialogs.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets("the strip's + chip hops to the add-section form", (
    tester,
  ) async {
    final container = scaffold.makeContainer(user: voteAdminUserFixture());
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubVoteAdmin(
      scaffold,
      status: enums.StatusType.waiting,
      sections: [sectionFixture('s-1', 'Bureau des Sports')],
      lists: const [],
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${VoteRouter.root}${VoteRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    // The waiting-status strip's leading + chip (scoped to SectionBar — the
    // Lists header carries its own plus icon).
    await tester.tap(
      find.descendant(
        of: find.byType(SectionBar),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.plus,
        ),
      ),
    );
    for (
      var i = 0;
      i < 25 && find.text('Add a section').evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }
    expect(find.text('Add a section'), findsOneWidget);
  });
}
