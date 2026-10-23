import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/selected_ticket_event_provider.dart';

import '../shared/app_scaffold.dart';

final _defaultStore = UserStore.empty().copyWith(id: 'store-1', name: 'BDE');

/// A container for the seller `me`: it owns [stores] and can manage events
/// on each of them.
ProviderContainer sellerContainer(
  IntegrationScaffold scaffold, {
  List<UserStore>? stores,
}) {
  final list = stores ?? [_defaultStore];
  return scaffold.makeContainer(
    user: CoreUser.empty().copyWith(id: 'me'),
    myStores: list,
    storeSellers: {
      for (final store in list)
        store.id: [
          Seller.empty().copyWith(userId: 'me', canManageEvents: true),
        ],
    },
  );
}

/// Pumps the edit page with [fixture] answering the event GET.
Future<void> pumpEdit(
  IntegrationScaffold scaffold,
  WidgetTester tester,
  ProviderContainer container,
  EventAdmin fixture,
) async {
  container.read(selectedTicketEventIdProvider.notifier).setId('evt-1');
  when(() => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'evt-1'))
      .thenAnswer((_) async => chopperResponse(fixture));

  scaffold.setWideSurface(tester);
  await scaffold.pumpApp(
    tester,
    container,
    initialPath: '/tickets/edit',
    pumpAndSettle: false,
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Raw pump loop for chains that never settle.
Future<void> pumpFrames(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Scrolls [finder] into view, then pins it visible.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
}
