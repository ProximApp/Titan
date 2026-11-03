import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan/settings/tools/functions.dart';

import '../../shared/app_scaffold.dart';

/// `openLink` is the settings tools file's only other function besides the
/// topic grouping: it launches through url_launcher when a handler exists
/// and throws the raw string when none does.
void main() {
  test('openLink launches the url in the in-app browser', () async {
    final fake = FakeUrlLauncher(launchSucceeds: true);
    stubUrlLauncher(fake);

    openLink('https://titan.example/calendar');
    await Future<void>.delayed(Duration.zero);

    expect(fake.launched, ['https://titan.example/calendar']);
    // inAppBrowserView decomposes to Safari VC enabled.
    expect(fake.launches.single.useSafariVC, isTrue);
  });

  test('openLink throws when no platform can launch the url', () async {
    final fake = FakeUrlLauncher(launchSucceeds: false);
    stubUrlLauncher(fake);

    // openLink is `async void`: the throw surfaces through the zone, not
    // through a returned Future — guard the zone to observe it.
    final errors = <Object>[];
    await runZonedGuarded(() async {
      openLink('nowhere://x');
      await Future<void>.delayed(Duration.zero);
    }, (error, stack) => errors.add(error));

    expect(errors, ['Unable to open: nowhere://x']);
    expect(fake.launched, isEmpty);
  });
}
