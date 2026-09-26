import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart' hide Answer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/admin/providers/my_association_list_provider.dart';
import 'package:titan/feed/providers/is_user_a_member_of_an_association.dart';
import 'package:titan/advert/providers/advert_list_provider.dart';
import 'package:titan/advert/providers/advert_provider.dart';
import 'package:titan/advert/providers/selected_association_provider.dart';
import 'package:chopper/chopper.dart' as chopper;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

class MockRepository extends Mock implements Openapi {}

chopper.Response<List<T>> chopperListResponse<T>(List<T> body) =>
    chopper.Response(http.Response('body', 200), body);

class FakeMyAssociationList extends MyAssociationListNotifier {
  FakeMyAssociationList(this.associations);

  final List<Association> associations;

  @override
  AsyncValue<List<Association>> build() => AsyncValue.data(associations);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockRepository();
  });

  group('AdvertNotifier', () {
    test('setAdvert replaces the selected advert', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final advert = AdvertComplete.empty().copyWith(
        id: 'a1',
        title: 'Garage sale',
        content: 'Everything must go',
      );

      container.read(advertProvider.notifier).setAdvert(advert);

      expect(container.read(advertProvider).title, 'Garage sale');
    });
  });

  group('AssociationNotifier (selected associations)', () {
    test('addAssociation appends a copy of the state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(selectedAssociationProvider.notifier);

      notifier.addAssociation(
        Association.empty().copyWith(id: 'a-1', name: 'BDE'),
      );
      notifier.addAssociation(
        Association.empty().copyWith(id: 'a-2', name: 'BDA'),
      );

      expect(
        notifier.state.map((e) => e.id),
        ['a-1', 'a-2'],
      );
    });

    test('removeAssociation filters by id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(selectedAssociationProvider.notifier);
      notifier.addAssociation(
        Association.empty().copyWith(id: 'a-1', name: 'BDE'),
      );
      notifier.addAssociation(
        Association.empty().copyWith(id: 'a-2', name: 'BDA'),
      );

      notifier.removeAssociation(
        Association.empty().copyWith(id: 'a-1', name: 'BDE'),
      );

      expect(notifier.state.map((e) => e.id), ['a-2']);
    });

    test('clearAssociation empties the selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(selectedAssociationProvider.notifier);
      notifier.addAssociation(
        Association.empty().copyWith(id: 'a-1', name: 'BDE'),
      );

      notifier.clearAssociation();

      expect(notifier.state, isEmpty);
    });
  });

  group('AdvertListNotifier', () {
    test('loads the advert list from the repository', () async {
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final advert = AdvertComplete.empty().copyWith(
        id: 'a1',
        title: 'Garage sale',
        content: 'Everything must go',
        advertiserId: 'asso-1',
        date: DateTime(2026, 5, 1),
      );
      when(() => repository.advertAdvertsGet()).thenAnswer(
        (_) async => chopperListResponse([advert]),
      );

      container.read(advertListProvider);
      await pumpEventQueue();

      expect(
        container.read(advertListProvider).value!.first.title,
        'Garage sale',
      );
    });

    test('surfaces a repository error as an error state', () async {
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      when(() => repository.advertAdvertsGet()).thenThrow(Exception('boom'));
      container.read(advertListProvider);
      await pumpEventQueue();

      expect(container.read(advertListProvider), isA<AsyncError>());
    });
  });

  group('isUserAMemberOfAnAssociationProvider', () {
    test('is true when my association list is non-empty', () {
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          asyncMyAssociationListProvider.overrideWith(
            () => FakeMyAssociationList([
              Association.empty().copyWith(id: 'a-1', name: 'BDE'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isUserAMemberOfAnAssociationProvider), isTrue);
    });

    test('is false when my association list is empty', () {
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          asyncMyAssociationListProvider.overrideWith(
            () => FakeMyAssociationList([]),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isUserAMemberOfAnAssociationProvider), isFalse);
    });
  });
}
