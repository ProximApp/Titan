import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/vote/providers/result_provider.dart';
import 'package:titan/vote/providers/sections_list_provider.dart';
import 'package:titan/vote/providers/sections_provider.dart';
import 'package:titan/vote/providers/status_provider.dart';
import 'package:titan/vote/ui/pages/admin_page/vote_bars.dart';
import 'package:titan/vote/ui/pages/main_page/list_list_card.dart';
import 'package:titan/vote/ui/pages/main_page/section_title.dart';
import 'package:titan/vote/ui/pages/main_page/side_item.dart';

import '../../shared/app_scaffold.dart';
import '../vote_fixtures.dart';

/// The vote main page's small parts, each mounted on its own: the section
/// title and side items (which fall back to "No section" and to a dimmed
/// label), the candidates list before the section's lists have landed, and
/// the admin chart while that same read is still loading.
///
/// These are the states the page shells never sit in — a deep link resolves
/// the campaign first — so the widgets were dark there.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget widget, {
    List<dynamic> overrides = const [],
    ui.Size surface = const ui.Size(400, 600),
  }) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
      providerOverrides: overrides,
    );
    addTearDown(container.dispose);
    await pumpWidgetAt(tester, widget, container: container, surface: surface);
  }

  testWidgets('the section title says there is no section when the campaign '
      'has none', (tester) async {
    await pump(
      tester,
      const SectionTitle(sectionList: []),
      overrides: [
        sectionsProvider.overrideWith(
          () => FakeSectionsNotifier(const AsyncValue.data([])),
        ),
      ],
    );

    expect(find.text('No section'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a section the voter already voted in is dimmed unless it is '
      'the selected one', (tester) async {
    var tapped = 0;
    await pump(
      tester,
      SideItem(
        section: sectionFixture('s-1', 'Bureau des Sports'),
        isSelected: false,
        alreadyVoted: true,
        onTap: () => tapped++,
      ),
      surface: const ui.Size(200, 300),
    );

    final label = tester.widget<Text>(find.text('Bureau des Sports'));
    expect(label.style!.color, Colors.grey.shade500);

    await tester.tap(find.text('Bureau des Sports'));
    expect(tapped, 1);
  });

  testWidgets('the candidates list falls back to its empty line while the '
      'section holds no lists', (tester) async {
    final animation = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 200),
    );
    addTearDown(animation.dispose);

    await pump(
      tester,
      ListListCard(animation: animation),
      overrides: [
        // No sections: the page's status read has not landed, so its orElse
        // must read as closed rather than waiting on an answer.
        sectionsProvider.overrideWith(
          () => FakeSectionsNotifier(const AsyncValue.data([])),
        ),
        statusProvider.overrideWith(
          () => FakeVoteStatusNotifier(const AsyncValue.loading()),
        ),
      ],
    );

    // Let the card's 200 ms reveal finish before the tree goes away.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No list of candidates'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the admin chart draws nothing while its section is still '
      'loading', (tester) async {
    final section = sectionFixture('s-1', 'Bureau des Sports');
    await pump(
      tester,
      const VoteBars(),
      surface: const ui.Size(600, 400),
      overrides: [
        sectionsProvider.overrideWith(
          () => FakeSectionsNotifier(AsyncValue.data([section])),
        ),
        // The chart reads the section's lists out of this map: pin the entry
        // to a state the derived map never holds once the read lands.
        sectionListProvider.overrideWith(
          () => FakeSectionListNotifier({section: const AsyncValue.loading()}),
        ),
        statusProvider.overrideWith(
          () => FakeVoteStatusNotifier(
            const AsyncValue.data(VoteStatus(status: StatusType.counting)),
          ),
        ),
        resultProvider.overrideWith(
          () => FakeResultNotifier(
            const AsyncValue.data(<AppModulesCampaignSchemasCampaignResult>[]),
          ),
        ),
      ],
    );

    expect(find.byType(VoteBars), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
