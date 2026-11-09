import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/tools/providers/locale_notifier.dart';

/// The app boots in French and only moves once the stored preference has been
/// read: a cold start must not flash the wrong language, and a change has to
/// survive the next launch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// `build` starts the async read without awaiting it, and that read hops
  /// through the platform channel, so poll the notifier instead of guessing how
  /// long the hop takes. An unchanged value simply means the store is empty.
  Future<Locale> settle(ProviderContainer container) async {
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final locale = container.read(localeProvider);
      if (locale != const Locale('fr', 'FR')) return locale;
    }
    return container.read(localeProvider);
  }

  test('no stored preference keeps French', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await settle(container), const Locale('fr', 'FR'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), isNull);
  });

  test('a stored preference wins over the default', () async {
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await settle(container), const Locale('en'));
  });

  test('setLocale stores the language and updates the state', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await settle(container);

    await container.read(localeProvider.notifier).setLocale(const Locale('en'));

    expect(container.read(localeProvider), const Locale('en'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'en');
  });
}
