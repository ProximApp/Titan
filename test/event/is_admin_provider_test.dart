import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/admin/class/simple_group.dart';
import 'package:titan/event/providers/is_admin_provider.dart';
import 'package:titan/user/class/user.dart';
import 'package:titan/tools/builders/empty_models.dart';
import 'package:titan/user/providers/user_provider.dart';

void main() {
  group('isEventAdmin', () {
    test('should return true if user is event admin', () {
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(
            EmptyModels.empty<CoreUser>().copyWith(
              groups: [
                EmptyModels.empty<CoreGroupSimple>().copyWith(
                  id: "b0357687-2211-410a-9e2a-144519eeaafa",
                  name: 'admin_calendar',
                ),
                EmptyModels.empty<CoreGroupSimple>().copyWith(
                  id: '123',
                  name: 'User',
                ),
              ],
            ),
          ),
        ],
      );

      final isEventAdminState = container.read(isEventAdminProvider);

      expect(isEventAdminState, true);
    });

    test('should return false if user is not event admin', () {
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(
            EmptyModels.empty<CoreUser>().copyWith(
              groups: [
                EmptyModels.empty<CoreGroupSimple>().copyWith(
                  id: '123',
                  name: 'User',
                ),
              ],
            ),
          ),
        ],
      );

      final isEventAdminState = container.read(isEventAdminProvider);

      expect(isEventAdminState, false);
    });
  });
}
