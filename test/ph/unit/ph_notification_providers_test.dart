import 'package:flutter_test/flutter_test.dart';
import 'package:titan/ph/notification_service.dart';
import 'package:titan/ph/providers/ph_list_provider.dart';
import 'package:titan/ph/router.dart';
import 'package:titan/service/provider_list.dart';

/// A push about a ph session refreshes the module it points at: the service
/// looks the module up in `providers` and refreshes every provider listed
/// beside it. The table is what ties a notification topic to a route and a
/// list, so a stale root or a missing provider is a silent no-op on the phone.
void main() {
  test('the ph module registers its root and its list provider', () {
    final entry = phProviders['ph'];
    expect(entry, isNotNull);
    expect(entry!.item1, PhRouter.root);
    expect(entry.item2, contains(phListProvider));

    // And the service's own table is what holds it.
    expect(providers['ph'], same(phProviders));
  });
}
