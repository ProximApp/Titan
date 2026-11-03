import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/admin/providers/assocation_list_provider.dart';
import 'package:titan/admin/providers/structure_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../generated/openapi_mock_factories.dart';
import '../../shared/mock_openapi.dart';

/// Unit coverage for the two small admin providers with no widget under
/// them: [AssociationListNotifier.setAssociation] (in-place edit of the
/// loaded list, no-op for an unknown id) and [StructureNotifier]'s
/// set/reset pair.
Future<AsyncValue<List<Association>>> _settled(
  ProviderContainer container,
) async {
  for (var i = 0; i < 100; i++) {
    final state = container.read(associationListProvider);
    if (!state.isLoading) return state;
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(associationListProvider);
}

void main() {
  group('AssociationListNotifier.setAssociation', () {
    late MockOpenapi repo;
    late ProviderContainer container;

    setUp(() {
      repo = MockOpenapi();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
    });

    test('replaces the matching entry in the loaded list', () async {
      when(() => repo.associationsGet()).thenAnswer(
        (_) async => repo.ok([
          MockAssociation.withOnly(id: 'a-1'),
          MockAssociation.withOnly(id: 'a-2'),
        ]),
      );
      final loaded = await _settled(container);
      expect(loaded.value, hasLength(2));

      container
          .read(associationListProvider.notifier)
          .setAssociation(
            MockAssociation.withFields(
              name: 'Renamed',
              groupId: 'g-1',
              id: 'a-1',
            ),
          );

      final updated = container.read(associationListProvider).value!;
      expect(updated.map((a) => a.id), ['a-1', 'a-2']);
      expect(updated.first.name, 'Renamed');
    });

    test('ignores an id that is not in the list', () async {
      when(
        () => repo.associationsGet(),
      ).thenAnswer((_) async => repo.ok([MockAssociation.withOnly(id: 'a-1')]));
      await _settled(container);
      final before = container.read(associationListProvider).value;

      container
          .read(associationListProvider.notifier)
          .setAssociation(MockAssociation.withOnly(id: 'missing'));

      expect(container.read(associationListProvider).value, same(before));
    });
  });

  group('StructureNotifier', () {
    test('setStructure stores the structure and resetStructure clears it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(structureProvider.notifier);

      expect(container.read(structureProvider), Structure.empty());

      notifier.setStructure(Structure.empty().copyWith(id: 's-1'));
      expect(container.read(structureProvider).id, 's-1');

      notifier.resetStructure();
      expect(container.read(structureProvider), Structure.empty());
    });
  });
}
