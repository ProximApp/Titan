import 'dart:ui' as ui;

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/admin/ui/pages/membership/add_edit_user_membership_page/user_search_modal.dart'
    as membership;
import 'package:titan/admin/ui/pages/structure_page/add_edit_structure_page/user_search_modal.dart'
    as structure;
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// Both pick-a-manager modals are the same search bar over `userList`: a
/// query filters through `usersSearchGet`, and emptying the field resets the
/// list and the field itself instead of leaving the previous results (and the
/// stale text) behind.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
  });

  void stubSearch() {
    when(() => scaffold.repository.usersSearchGet(query: any(named: 'query')))
        .thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), <CoreUserSimple>[
                CoreUserSimple.empty().copyWith(id: 'u-1', name: 'Ariane'),
              ]),
        );
  }

  Future<void> clearSearch(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'Ari');
    await tester.pumpAndSettle();
    expect(find.text('Ari'), findsOneWidget);

    // Emptying the field is the arm under test.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Ari'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(tester.takeException(), isNull);
  }

  testWidgets('the membership picker clears its query', (tester) async {
    stubSearch();
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      const membership.UserSearchModal(),
      container,
      surface: const ui.Size(500, 900),
    );
    await clearSearch(tester);
  });

  testWidgets('the structure picker clears its query', (tester) async {
    stubSearch();
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      const structure.UserSearchModal(),
      container,
      surface: const ui.Size(500, 900),
    );
    await clearSearch(tester);
  });
}
