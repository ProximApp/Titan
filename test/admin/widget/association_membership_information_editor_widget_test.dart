import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:titan/admin/providers/association_membership_provider.dart';
import 'package:titan/admin/ui/pages/membership/association_membership_detail_page/association_membership_information_editor.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The editor names the membership's manager group by looking its id up in
/// the group list. A membership whose group is missing from that list (a
/// group deleted under it, or a list that has not caught up) must still
/// render — with the "no group" placeholder — instead of throwing the
/// page's `firstWhere`.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
  });

  testWidgets('a member of an unknown group shows the placeholder', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      groups: [CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Admins')],
    );
    addTearDown(container.dispose);
    container
        .read(associationMembershipProvider.notifier)
        .setAssociationMembership(
          MembershipSimple.empty().copyWith(
            id: 'm-1',
            name: 'BDE membership',
            managerGroupId: 'g-gone',
          ),
        );

    await scaffold.pumpWidgetApp(
      tester,
      AssociationMembershipInformationEditor(),
      container,
      surface: const ui.Size(600, 900),
    );

    expect(find.text('No group'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
