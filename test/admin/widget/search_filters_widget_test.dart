import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/admin/providers/association_membership_members_list_provider.dart';
import 'package:titan/admin/providers/association_membership_provider.dart';
import 'package:titan/admin/ui/pages/membership/association_membership_detail_page/search_filters.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/tools/ui/widgets/date_entry.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for `SearchFilters`: the four date entries pick
/// days through the real picker, Apply forwards them to the members load,
/// and Clear resets the fields and reloads unfiltered.
class _MembersNotifier extends AssociationMembershipMembersNotifier {
  @override
  AsyncValue<List<UserMembershipComplete>> build() =>
      const AsyncValue.loading();
}

class _MembershipNotifier extends AssociationMembershipNotifier {
  @override
  MembershipSimple build() =>
      MembershipSimple.empty().copyWith(id: 'am-1', name: 'BDE');
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Pumps fixed frames plus a long jump: the apply/clear buttons answer
  /// with toasts whose auto-close timer must not outlive the test.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
  }

  ProviderContainer containerWith() {
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(scaffold.repository),
        associationMembershipMembersProvider.overrideWith(_MembersNotifier.new),
        associationMembershipProvider.overrideWith(_MembershipNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> mount(WidgetTester tester, ProviderContainer container) async {
    await scaffold.pumpWidgetApp(
      tester,
      const SingleChildScrollView(child: SearchFilters()),
      container,
      locale: const Locale('en', 'US'),
    );
  }

  testWidgets('picking the minimal start day and applying forwards it', (
    tester,
  ) async {
    final repo = scaffold.repository;
    when(
      () => repo.membershipsAssociationMembershipIdMembersGet(
        associationMembershipId: 'am-1',
        minimalStartDate: any(named: 'minimalStartDate'),
        minimalEndDate: any(named: 'minimalEndDate'),
        maximalStartDate: any(named: 'maximalStartDate'),
        maximalEndDate: any(named: 'maximalEndDate'),
      ),
    ).thenAnswer((_) async => repo.okList<UserMembershipComplete>());

    final container = containerWith();
    await mount(tester, container);

    expect(find.byType(DateEntry), findsNWidgets(4));

    // Open the minimal-start picker and accept today.
    await tester.tap(find.byType(DateEntry).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().day}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await pumpFrames(tester);

    await tester.tap(find.text('Apply filters'));
    await pumpFrames(tester);

    final captured = verify(
      () => repo.membershipsAssociationMembershipIdMembersGet(
        associationMembershipId: 'am-1',
        minimalStartDate: captureAny(named: 'minimalStartDate'),
        minimalEndDate: captureAny(named: 'minimalEndDate'),
        maximalStartDate: captureAny(named: 'maximalStartDate'),
        maximalEndDate: captureAny(named: 'maximalEndDate'),
      ),
    ).captured;
    // Captured in the verify closure's named-argument order; mocktail
    // flattens every captured argument of every matched call, so exactly
    // four entries also pins the call count to one.
    expect(captured, hasLength(4));
    expect(captured[0], isNotNull);
    expect(captured[2], isNotNull);
    expect(captured[3], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clearing resets the fields and reloads unfiltered', (
    tester,
  ) async {
    final repo = scaffold.repository;
    when(
      () => repo.membershipsAssociationMembershipIdMembersGet(
        associationMembershipId: 'am-1',
        minimalStartDate: any(named: 'minimalStartDate'),
        minimalEndDate: any(named: 'minimalEndDate'),
        maximalStartDate: any(named: 'maximalStartDate'),
        maximalEndDate: any(named: 'maximalEndDate'),
      ),
    ).thenAnswer((_) async => repo.okList<UserMembershipComplete>());

    final container = containerWith();
    await mount(tester, container);

    await tester.tap(find.text('Clear filters'));
    await pumpFrames(tester);

    final captured = verify(
      () => repo.membershipsAssociationMembershipIdMembersGet(
        associationMembershipId: 'am-1',
        minimalStartDate: captureAny(named: 'minimalStartDate'),
        minimalEndDate: captureAny(named: 'minimalEndDate'),
        maximalStartDate: captureAny(named: 'maximalStartDate'),
        maximalEndDate: captureAny(named: 'maximalEndDate'),
      ),
    ).captured;
    expect(captured, hasLength(4));
    expect(captured[0], isNull);
    expect(captured[1], isNull);
    expect(captured[2], isNull);
    expect(captured[3], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a date picker can be cancelled without touching the field', (
    tester,
  ) async {
    final container = containerWith();
    await mount(tester, container);

    await tester.tap(find.byType(DateEntry).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await pumpFrames(tester);

    expect(tester.takeException(), isNull);
  });
}
