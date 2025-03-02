import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/admin/class/simple_group.dart';
import 'package:titan/user/class/simple_users.dart';
import 'package:titan/user/providers/user_list_provider.dart';
import 'package:titan/user/repositories/user_list_repository.dart';

class MockUserListRepository extends Mock implements Openapi {}

void main() {
  group('UserListNotifier', () {
    late MockUserListRepository mockRepository;
    late UserListNotifier provider;
    final users = [
      CoreUserSimple.fromJson({}).copyWith(id: '1'),
      CoreUserSimple.fromJson({}).copyWith(id: '2'),
    ];

    setUp(() {
      mockRepository = MockUserListRepository();
      provider = UserListNotifier(userListRepository: mockRepository);
    });

    test('filterUsers returns expected data', () async {
      when(
        () => mockRepository.usersSearchGet(
          query: any(named: 'query'),
          includedGroups: any(named: 'includedGroups'),
          excludedGroups: any(named: 'excludedGroups'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(
          http.Response('body', 200),
          users,
        ),
      );

      final result = await provider.filterUsers('test');

      expect(
        result.maybeWhen(
          data: (data) => data,
          orElse: () => [],
        ),
        users,
      );
    });

    test('filterUsers handles error', () async {
      when(
        () => mockRepository.usersSearchGet(
          query: any(named: 'query'),
          includedGroups: any(named: 'includedGroups'),
          excludedGroups: any(named: 'excludedGroups'),
        ),
      ).thenThrow(Exception('Failed to filter users'));

      final result = await provider.filterUsers('test');

      expect(
        result.maybeWhen(
          error: (error, _) => error,
          orElse: () => null,
        ),
        isA<Exception>(),
      );
    });

    test('clear sets state to empty list', () async {
      await provider.clear();

      expect(
        provider.state.maybeWhen(
          data: (data) => data,
          orElse: () => null,
        ),
        [],
      );
    });
  });
}
