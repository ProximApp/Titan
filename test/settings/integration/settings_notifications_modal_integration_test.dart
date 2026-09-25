import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/settings/ui/pages/main_page/load_switch_topic.dart';
import 'package:titan/tools/ui/styleguide/list_item_template.dart';

import '../../shared/app_scaffold.dart';

/// The notifications sheet was the settings main page's biggest uncovered
/// surface (main_page lines ~202-292, plus the two 0%-covered helpers it
/// calls: `groupNotificationTopicsByModuleRoot` and `LoadSwitchTopic`).
/// `groupNotificationTopicsByModuleRoot` groups topics with more than one
/// entry per module under the module's display name and pools the rest
/// under 'others'; the module groups render collapsed/expandable.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    scaffold.stubProfilePicture();
    when(() => scaffold.repository.notificationTopicsGet()).thenAnswer(
      (_) async => chopperListResponse([
        // Two topics on the same module: they land in a named group.
        TopicUser.empty().copyWith(
          id: 't-1',
          name: 'Booking reminders',
          moduleRoot: '/booking',
          isUserSubscribed: true,
        ),
        TopicUser.empty().copyWith(
          id: 't-2',
          name: 'Booking news',
          moduleRoot: '/booking',
          isUserSubscribed: false,
        ),
        // A lone topic: it lands in the 'others' pool.
        TopicUser.empty().copyWith(
          id: 't-3',
          name: 'AMAP newsletters',
          moduleRoot: '/amap',
          isUserSubscribed: false,
        ),
      ]),
    );
    when(
      () => scaffold.repository.notificationTopicsTopicIdUnsubscribePost(
        topicId: any(named: 'topicId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    when(
      () => scaffold.repository.notificationTopicsTopicIdSubscribePost(
        topicId: any(named: 'topicId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
  });

  testWidgets(
    'the sheet pools the lone topic, groups the pair and toggles a switch',
    (tester) async {
      scaffold.setWideSurface(tester);
      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/settings',
      );
      await settle(tester, frames: 8);

      await scaffold.openModal(tester, find.text('Notifications'));
      expect(scaffold.isModalOpen(tester), isTrue);

      // The lone AMAP topic is pooled first; the booking pair renders under
      // its module group, expanded by default.
      expect(find.text('AMAP newsletters'), findsOneWidget);
      expect(find.text('Booking reminders'), findsOneWidget);
      expect(find.text('Booking news'), findsOneWidget);

      // Tapping a grouped topic's switch unsubscribes it through the real
      // endpoint (the topic was subscribed).
      final reminderRow = find.ancestor(
        of: find.text('Booking reminders'),
        matching: find.byType(ListItemTemplate),
      );
      await scaffold.tapInModal(
        tester,
        find.descendant(
          of: reminderRow,
          matching: find.byType(LoadSwitchTopic),
        ),
      );
      await settle(tester, frames: 10);
      verify(
        () => scaffold.repository.notificationTopicsTopicIdUnsubscribePost(
          topicId: 't-1',
        ),
      ).called(1);

      // The module group header carries the raw moduleRoot as its title
      // (the display-name lookup strips the leading '/', so '/booking'
      // misses and falls back); tapping it collapses the group and its
      // topics leave the tree. Match it by title — an ancestor-of-HeroIcon
      // finder reads the settings page behind the modal too.
      final groupHeader = find.ancestor(
        of: find.text('/booking'),
        matching: find.byType(ListItemTemplate),
      );
      await scaffold.tapInModal(tester, groupHeader);
      await settle(tester, frames: 6);

      expect(find.text('Booking reminders'), findsNothing);
      expect(find.text('Booking news'), findsNothing);
      // The pooled topic is unaffected by the collapse.
      expect(find.text('AMAP newsletters'), findsOneWidget);

      await scaffold.closeModal(tester);
      expect(scaffold.isModalOpen(tester), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a lone subscribed topic subscribes back on toggle', (
    tester,
  ) async {
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.notificationTopicsGet()).thenAnswer(
      (_) async => chopperListResponse([
        TopicUser.empty().copyWith(
          id: 't-9',
          name: 'Cinema alerts',
          moduleRoot: '/cinema',
          isUserSubscribed: true,
        ),
      ]),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/settings',
    );
    await settle(tester, frames: 8);

    await scaffold.openModal(tester, find.text('Notifications'));
    expect(find.text('Cinema alerts'), findsOneWidget);

    // Keep the managed toggle's future pending across a few frames: the
    // switch paints its spinner only while onToggle is in flight, which is
    // the sole path that calls LoadSwitchTopic's spinColor closure.
    when(
      () => scaffold.repository.notificationTopicsTopicIdUnsubscribePost(
        topicId: any(named: 'topicId'),
      ),
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return chopperResponseVoid();
    });

    final row = find.ancestor(
      of: find.text('Cinema alerts'),
      matching: find.byType(ListItemTemplate),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byType(LoadSwitchTopic)),
    );
    // Spin while the endpoint is pending…
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    // …then let it finish (settle pumps 60ms frames past the 300ms delay).
    await settle(tester, frames: 10);
    await tester.pumpAndSettle();

    verify(
      () => scaffold.repository.notificationTopicsTopicIdUnsubscribePost(
        topicId: 't-9',
      ),
    ).called(1);
    expect(tester.takeException(), isNull);
  });
}
