import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:titan/version/providers/minimal_hyperion_version_provider.dart';
import 'package:titan/version/providers/titan_version_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  /// Both notifiers fire their storage load unawaited from build(); poll the
  /// provider until the async assignment lands (plain test = real timers).
  Future<void> waitFor(bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test(
    'titanVersion starts at 0 and resolves the package build number',
    () async {
      PackageInfo.setMockInitialValues(
        appName: 'MyEMApp',
        packageName: 'fr.myemapp.titan',
        version: '1.2.3',
        buildNumber: '42',
        buildSignature: '',
      );

      // build() answers 0 before the unawaited package lookup completes.
      expect(container.read(titanVersionProvider), 0);

      await waitFor(() => container.read(titanVersionProvider) == 42);

      expect(container.read(titanVersionProvider), 42);
      final notifier = container.read(titanVersionProvider.notifier);
      expect(notifier.packageInfo.buildNumber, '42');
    },
  );

  test(
    'minimalHyperionVersion starts blank and loads the pubspec version',
    () async {
      expect(container.read(minimalHyperionVersionProvider), '');

      await waitFor(() => container.read(minimalHyperionVersionProvider) != '');

      expect(container.read(minimalHyperionVersionProvider), '6.0.0');
    },
  );
}
