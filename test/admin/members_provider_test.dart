import 'package:flutter_test/flutter_test.dart';
import 'package:titan/super_admin/providers/members_provider.dart';
import 'package:titan/user/class/simple_users.dart';
import 'package:titan/tools/builders/empty_models.dart';

void main() {
  group('MembersNotifier', () {
    final user1 = EmptyModels.empty<CoreUserSimple>().copyWith(
      id: '1',
      name: 'John',
    );
    final user2 = EmptyModels.empty<CoreUserSimple>().copyWith(
      id: '2',
      name: 'Jane',
    );
    test('Adding a user to the list', () {
      final membersNotifier = MembersNotifier();
      membersNotifier.add(user1);
      expect(membersNotifier.state.length, 1);
      expect(membersNotifier.state[0], user1);
    });

    test('Removing a user from the list', () {
      final membersNotifier = MembersNotifier();
      membersNotifier.add(user1);
      membersNotifier.add(user2);
      membersNotifier.remove(user1);
      expect(membersNotifier.state.length, 1);
      expect(membersNotifier.state[0], user2);
    });

    test('Removing a user that doesn\'t exist in the list', () {
      final membersNotifier = MembersNotifier();
      membersNotifier.add(user1);
      membersNotifier.remove(user2);
      expect(membersNotifier.state.length, 1);
      expect(membersNotifier.state[0], user1);
    });
  });
}
