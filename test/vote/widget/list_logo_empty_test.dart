import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/vote/providers/list_logos_provider.dart';
import 'package:titan/vote/ui/components/list_logo.dart';

import '../../shared/app_scaffold.dart';

/// The list logo renders from a map group that the loader fills with ONE
/// image; any other writer can leave that group `AsyncData([])`, and the card
/// used to reach `logo.first.image` on it — `Bad state: No element` inside a
/// list row's build.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('an empty logo group renders an empty circle', (tester) async {
    const listId = 'l-1';
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(listLogosProvider.notifier).state = {
      listId: const AsyncValue.data(<Image>[]),
    };

    await scaffold.pumpWidgetApp(
      tester,
      ListLogo(ListReturn.empty().copyWith(id: listId, name: 'Liste A')),
      container,
    );

    expect(find.byType(ListLogo), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
