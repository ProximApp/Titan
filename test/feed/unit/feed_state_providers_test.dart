import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/admin/providers/my_association_list_provider.dart';
import 'package:titan/feed/class/filter_state.dart';
import 'package:titan/feed/providers/filter_state_provider.dart';
import 'package:titan/feed/providers/is_feed_admin_provider.dart';
import 'package:titan/feed/providers/is_user_a_member_of_an_association.dart';
import 'package:titan/feed/providers/news_images_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/user/providers/user_provider.dart';

class FakeMyAssociationListNotifier extends MyAssociationListNotifier {
  FakeMyAssociationListNotifier(this.initial);

  final List<Association> initial;

  @override
  AsyncValue<List<Association>> build() {
    return AsyncValue.data(initial);
  }
}

CoreUser userWithGroups(List<String> groupIds) => CoreUser.empty().copyWith(
  groups: groupIds.map((id) => CoreGroupSimple(id: id, name: id)).toList(),
);

void main() {
  group('FilterState', () {
    test('empty has no selected entity or module', () {
      final state = FilterState.empty();

      expect(state.selectedEntities, isEmpty);
      expect(state.selectedModules, isEmpty);
    });

    test('copyWith replaces only the given lists', () {
      final state = FilterState.empty().copyWith(selectedEntities: ['bde']);

      expect(state.selectedEntities, ['bde']);
      expect(state.selectedModules, isEmpty);

      final other = state.copyWith(selectedModules: ['event']);

      expect(other.selectedEntities, ['bde']);
      expect(other.selectedModules, ['event']);
    });
  });

  group('FilterNotifier', () {
    test('starts empty and keeps whatever state it is given', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // FilterState has no == override, so compare field-wise.
      final initial = container.read(filterStateProvider);
      expect(initial.selectedEntities, isEmpty);
      expect(initial.selectedModules, isEmpty);

      final state = FilterState(
        selectedEntities: ['bde'],
        selectedModules: ['event'],
      );
      container.read(filterStateProvider.notifier).setFilterState(state);

      expect(container.read(filterStateProvider), same(state));
    });
  });

  group('NewsImagesNotifier (MapNotifier)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    // Image widgets don't implement ==, so every test keeps a reference to
    // the exact instances it stores in the map.
    Image image(int byte) => Image.memory(Uint8List.fromList([byte]));

    test('starts with an empty map', () {
      expect(container.read(newsImagesProvider), isEmpty);
    });

    test('setTData stores the async list for the key', () {
      final notifier = container.read(newsImagesProvider.notifier);
      final img = image(1);

      notifier.setTData('news-1', AsyncData([img]));

      expect(container.read(newsImagesProvider)['news-1']!.value, [img]);
    });

    test('addT reserves a key with null data', () {
      final notifier = container.read(newsImagesProvider.notifier);

      notifier.addT('news-1');

      expect(container.read(newsImagesProvider)['news-1'], isNull);
    });

    test('addE appends to the existing list or starts a new one', () {
      final notifier = container.read(newsImagesProvider.notifier);
      final img1 = image(1);
      final img2 = image(2);

      // No entry yet: addE creates the list.
      notifier.state['news-1'] = const AsyncValue.loading();
      notifier.addE('news-1', img1);
      expect(container.read(newsImagesProvider)['news-1']!.value, [img1]);

      notifier.addE('news-1', img2);
      expect(container.read(newsImagesProvider)['news-1']!.value, [img1, img2]);
    });

    test('deleteT removes the key', () {
      final notifier = container.read(newsImagesProvider.notifier);
      notifier.setTData('news-1', AsyncData([image(1)]));

      notifier.deleteT('news-1');

      expect(container.read(newsImagesProvider).containsKey('news-1'), isFalse);
    });

    test('resetTData clears every entry back to null data', () {
      final notifier = container.read(newsImagesProvider.notifier);
      notifier.setTData('news-1', AsyncData([image(1)]));
      notifier.setTData('news-2', AsyncData([image(2)]));

      notifier.resetTData();

      final map = container.read(newsImagesProvider);
      expect(map['news-1'], isNull);
      expect(map['news-2'], isNull);
    });

    test('deleteE removes the element at the index', () {
      final notifier = container.read(newsImagesProvider.notifier);
      final img1 = image(1);
      final img2 = image(2);
      final img3 = image(3);
      notifier.setTData('news-1', AsyncData([img1, img2, img3]));

      final result = notifier.deleteE('news-1', 1);

      expect(result, isTrue);
      expect(container.read(newsImagesProvider)['news-1']!.value, [img1, img3]);
    });

    test(
      'deleteE crashes on a missing or still-loading entry (state[t]! unwrap)',
      () {
        final notifier = container.read(newsImagesProvider.notifier);

        // Documented as-is: deleteE unwraps state[t]! without guarding, so a
        // missing key or a null (loading) entry throws instead of returning
        // false.
        expect(() => notifier.deleteE('news-1', 0), throwsA(anything));

        notifier.addT('news-1');
        expect(() => notifier.deleteE('news-1', 0), throwsA(anything));
      },
    );
  });

  group('isFeedAdminProvider', () {
    test('is true when the user belongs to the admin_feed group', () {
      const adminFeedGroupId = '59e3c4c2-e60f-44b6-b0d2-fa1b248423bb';
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(userWithGroups([adminFeedGroupId])),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isFeedAdminProvider), isTrue);
    });

    test('is false for any other group membership', () {
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(userWithGroups(['other'])),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isFeedAdminProvider), isFalse);
    });

    test('is false when the user has no groups', () {
      final container = ProviderContainer(
        overrides: [userProvider.overrideWithValue(CoreUser.empty())],
      );
      addTearDown(container.dispose);

      expect(container.read(isFeedAdminProvider), isFalse);
    });
  });

  group('isUserAMemberOfAnAssociationProvider', () {
    test('is true when the association list is not empty', () {
      final container = ProviderContainer(
        overrides: [
          asyncMyAssociationListProvider.overrideWith(
            () => FakeMyAssociationListNotifier([
              Association.empty().copyWith(id: 'asso-1'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isUserAMemberOfAnAssociationProvider), isTrue);
    });

    test('is false when the association list is empty', () {
      final container = ProviderContainer(
        overrides: [
          asyncMyAssociationListProvider.overrideWith(
            () => FakeMyAssociationListNotifier([]),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isUserAMemberOfAnAssociationProvider), isFalse);
    });
  });
}
