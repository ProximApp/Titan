import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/structure_list_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

/// `StructureListNotifier`'s four backend calls. The list loader had its
/// success and failure paths covered by the page tests; the three mutations
/// (create/update/delete) and the loader's own error arm had no test at all.
void main() {
  group('StructureListNotifier', () {
    late MockOpenapi mockRepository;
    late ProviderContainer container;
    late StructureListNotifier notifier;

    final structure = Structure.empty().copyWith(
      id: 'structure-1',
      name: 'BDE',
      managerUserId: 'u-1',
      shortId: 'bde',
    );

    setUp(() {
      mockRepository = MockOpenapi();
      when(() => mockRepository.mypaymentStructuresGet()).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('body', 200), <Structure>[]),
      );
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(structureListProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('getStructures loads the structures', () async {
      when(() => mockRepository.mypaymentStructuresGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), [structure]),
      );

      final result = await notifier.getStructures();

      expect(result.value, [structure]);
    });

    test('getStructures reports a backend failure as an error', () async {
      when(() => mockRepository.mypaymentStructuresGet())
          .thenThrow(Exception('structures failed'));

      final result = await notifier.getStructures();

      expect(result, isA<AsyncError<List<Structure>>>());
    });

    test('createStructure adds the created structure to the list', () async {
      final created = structure.copyWith(id: 'structure-2', name: 'Foyer');
      when(
        () => mockRepository.mypaymentStructuresPost(body: any(named: 'body')),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), created),
      );

      notifier.state = AsyncValue.data([]);
      final result = await notifier.createStructure(
        created.copyWith(id: 'structure-2'),
      );

      expect(result, true);
      expect(notifier.state.value!.map((s) => s.id), contains('structure-2'));
    });

    test('createStructure returns false when the backend refuses', () async {
      when(
        () => mockRepository.mypaymentStructuresPost(body: any(named: 'body')),
      ).thenThrow(Exception('create failed'));

      notifier.state = AsyncValue.data([]);
      final result = await notifier.createStructure(structure);

      expect(result, false);
    });

    test('updateStructure replaces the structure in the list', () async {
      final updated = structure.copyWith(name: 'Renamed');
      when(
        () => mockRepository.mypaymentStructuresStructureIdPatch(
          structureId: 'structure-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      notifier.state = AsyncValue.data([structure]);
      final result = await notifier.updateStructure(updated);

      expect(result, true);
      expect(notifier.state.value!.single.name, 'Renamed');
    });

    test('updateStructure returns false on a backend failure', () async {
      when(
        () => mockRepository.mypaymentStructuresStructureIdPatch(
          structureId: 'structure-1',
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('update failed'));

      notifier.state = AsyncValue.data([structure]);
      final result = await notifier.updateStructure(structure);

      expect(result, false);
    });

    test('deleteStructure removes the structure from the list', () async {
      when(
        () => mockRepository.mypaymentStructuresStructureIdDelete(
          structureId: 'structure-1',
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      notifier.state = AsyncValue.data([structure]);
      final result = await notifier.deleteStructure(structure);

      expect(result, true);
      expect(notifier.state.value, isEmpty);
    });

    test('deleteStructure returns false when the backend refuses', () async {
      when(
        () => mockRepository.mypaymentStructuresStructureIdDelete(
          structureId: 'structure-1',
        ),
      ).thenThrow(Exception('delete failed'));

      notifier.state = AsyncValue.data([structure]);
      final result = await notifier.deleteStructure(structure);

      expect(result, false);
    });
  });
}
