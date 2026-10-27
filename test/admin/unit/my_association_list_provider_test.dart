import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' show verify;
import 'package:titan/admin/providers/my_association_list_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../generated/openapi_mock_factories.dart';
import '../../shared/mock_openapi.dart';

/// Unit coverage for [MyAssociationListNotifier]: `build()` kicks off
/// `associationsMeGet`, `loadAssociations` funnels the response through
/// `ListNotifierAPI.loadList`, and the derived [myAssociationListProvider]
/// flattens the AsyncValue, falling back to `[]` while loading or after a
/// failure.
///
/// Riverpod 3's `NotifierProvider` exposes no `.future`, so each test waits
/// for the fire-and-forget load from `build()` to settle by polling the state.
Future<AsyncValue<List<Association>>> _settled(
  ProviderContainer container,
) async {
  for (var i = 0; i < 100; i++) {
    final state = container.read(asyncMyAssociationListProvider);
    if (!state.isLoading) return state;
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(asyncMyAssociationListProvider);
}

void main() {
  late MockOpenapi repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockOpenapi();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('build loads the associations of the current user', () async {
    when(
      () => repo.associationsMeGet(),
    ).thenAnswer((_) async => repo.ok([MockAssociation.withOnly(id: 'a-1')]));

    final loaded = await _settled(container);

    expect(loaded.hasValue, isTrue);
    expect(loaded.value, hasLength(1));
    expect(loaded.value!.single.id, 'a-1');
    verify(() => repo.associationsMeGet()).called(1);
    expect(container.read(myAssociationListProvider), loaded.value);
  });

  test('loadAssociations can be re-run to refresh the list', () async {
    // mocktail allows one answer per `when`; swap the payload between the
    // build-triggered load and the explicit refresh.
    var calls = 0;
    when(() => repo.associationsMeGet()).thenAnswer((_) async {
      calls++;
      return repo.ok([MockAssociation.withOnly(id: 'a-${calls == 1 ? 1 : 2}')]);
    });

    await _settled(container);
    final second = await container
        .read(asyncMyAssociationListProvider.notifier)
        .loadAssociations();

    expect(second.value!.single.id, 'a-2');
    expect(container.read(myAssociationListProvider).single.id, 'a-2');
    verify(() => repo.associationsMeGet()).called(2);
  });

  test(
    'a failed fetch surfaces the error and empties the derived list',
    () async {
      when(() => repo.associationsMeGet())
          .thenAnswer((_) async => repo.fail<List<Association>>(500));

      final result = await _settled(container);

      expect(result.hasError, isTrue);
      expect(container.read(myAssociationListProvider), isEmpty);
    },
  );
}
