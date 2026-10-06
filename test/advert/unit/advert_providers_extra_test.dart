import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/advert/providers/advert_list_provider.dart';
import 'package:titan/advert/providers/selected_association_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

class MockRepository extends Mock implements Openapi {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdvertListNotifier', () {
    late MockRepository mockRepository;
    final advert = AdvertComplete.empty().copyWith(
      id: 'ad-1',
      title: 'Soirée',
      content: 'Venez nombreux',
    );

    setUp(() {
      mockRepository = MockRepository();
      // build() fires loadAdverts() in a microtask: every CRUD test needs
      // the listing call stubbed so the state settles on data. Baseline is
      // an empty list; tests that need the advert pre-loaded re-stub below.
      when(() => mockRepository.advertAdvertsGet()).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('body', 200), <AdvertComplete>[]),
      );
    });

    test('loadAdverts loads the adverts', () async {
      when(() => mockRepository.advertAdvertsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), [advert]),
      );
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );

      final notifier = container.read(advertListProvider.notifier);
      final result = await notifier.loadAdverts();

      expect(result.value, [advert]);

      container.dispose();
    });

    test('loadAdverts reports an error when the call fails', () async {
      when(
        () => mockRepository.advertAdvertsGet(),
      ).thenThrow(Exception('adverts failed'));
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );

      final notifier = container.read(advertListProvider.notifier);
      final result = await notifier.loadAdverts();

      expect(result, isA<AsyncError<List<AdvertComplete>>>());

      container.dispose();
    });

    test('addAdvert appends the created advert', () async {
      final base = AdvertBase.empty();
      when(() => mockRepository.advertAdvertsPost(body: base)).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), advert),
      );
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );

      final notifier = container.read(advertListProvider.notifier);
      await notifier.loadAdverts();
      final ok = await notifier.addAdvert(base);

      expect(ok, isTrue);
      expect(container.read(advertListProvider).value, [advert]);

      container.dispose();
    });

    test('addAdvert returns false when the call fails', () async {
      when(() => mockRepository.advertAdvertsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), [advert]),
      );
      final base = AdvertBase.empty();
      when(() => mockRepository.advertAdvertsPost(body: base)).thenAnswer(
        (_) async => chopper.Response(
          http.Response('error', 400),
          null,
          error: 'cannot create',
        ),
      );
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );

      final notifier = container.read(advertListProvider.notifier);
      await notifier.loadAdverts();
      final ok = await notifier.addAdvert(base);

      expect(ok, isFalse);
      expect(container.read(advertListProvider).value, [advert]);

      container.dispose();
    });

    test('updateAdvert replaces the matching advert', () async {
      when(() => mockRepository.advertAdvertsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), [advert]),
      );
      final updated = advert.copyWith(title: 'Soirée 2');
      when(
        () => mockRepository.advertAdvertsAdvertIdPatch(
          advertId: 'ad-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );

      final notifier = container.read(advertListProvider.notifier);
      await notifier.loadAdverts();
      final ok = await notifier.updateAdvert(updated);

      expect(ok, isTrue);
      expect(container.read(advertListProvider).value, [updated]);

      container.dispose();
    });

    test('deleteAdvert removes the advert', () async {
      when(() => mockRepository.advertAdvertsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), [advert]),
      );
      when(
        () => mockRepository.advertAdvertsAdvertIdDelete(advertId: 'ad-1'),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );

      final notifier = container.read(advertListProvider.notifier);
      await notifier.loadAdverts();
      final ok = await notifier.deleteAdvert(advert);

      expect(ok, isTrue);
      expect(container.read(advertListProvider).value, isEmpty);

      container.dispose();
    });
  });

  group('AssociationNotifier (advert)', () {
    test('starts empty, adds, removes and clears associations', () {
      final container = ProviderContainer();

      expect(container.read(selectedAssociationProvider), isEmpty);

      final notifier = container.read(selectedAssociationProvider.notifier);
      final a1 = Association.empty().copyWith(id: 'a-1', name: 'BDE');
      final a2 = Association.empty().copyWith(id: 'a-2', name: 'BDF');

      notifier.addAssociation(a1);
      notifier.addAssociation(a2);
      expect(container.read(selectedAssociationProvider), [a1, a2]);

      notifier.removeAssociation(a1);
      expect(container.read(selectedAssociationProvider), [a2]);

      notifier.clearAssociation();
      expect(container.read(selectedAssociationProvider), isEmpty);

      container.dispose();
    });
  });
}
