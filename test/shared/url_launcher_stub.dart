import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// url_launcher's platform side: records every URL the app asks to open and
/// answers with whatever [launchSucceeds] says.
///
/// The fund confirm button's whole happy path ends in `launchUrl`, and a
/// `false` answer is what makes it throw `paiementCantLaunchURL` — so both
/// answers are worth being able to choose per test. `openLink` in
/// centralassociation sits on the same seam (its `canLaunchUrl` / `launchUrl`
/// pair) and flips the answer mid-test, which is why [launchSucceeds] is a
/// mutable field rather than a constructor-only one.
class FakeUrlLauncher extends UrlLauncherPlatform {
  FakeUrlLauncher({this.launchSucceeds = true, this.launchError});

  /// What a launch resolves to. `false` is the "no browser available" answer
  /// the fund button turns into an exception. Settable so one test can start
  /// launchable and flip to not.
  bool launchSucceeds;

  /// An optional platform failure, used to exercise callers' exception paths.
  Object? launchError;

  final List<String> launched = [];

  /// The launches with their full option set: `LaunchMode` never reaches the
  /// platform — `launchUrl` decomposes it into these named flags, and
  /// `useWebView` / `universalLinksOnly` are the only observable differences
  /// between the modes (ledger #60).
  final List<LaunchRecord> launches = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => launchSucceeds;

  // `launchUrl` on the base class is the non-virtual helper that decomposes a
  // LaunchOptions into these named flags, so overriding `launch` records every
  // launch whichever mode the caller asked for.
  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launched.add(url);
    launches.add(
      LaunchRecord(
        url: url,
        useSafariVC: useSafariVC,
        useWebView: useWebView,
        enableJavaScript: enableJavaScript,
        enableDomStorage: enableDomStorage,
        universalLinksOnly: universalLinksOnly,
      ),
    );
    final error = launchError;
    if (error != null) throw error;
    return launchSucceeds;
  }
}

/// What one launch was asked to do, recorded by [FakeUrlLauncher].
class LaunchRecord {
  const LaunchRecord({
    required this.url,
    required this.useSafariVC,
    required this.useWebView,
    required this.enableJavaScript,
    required this.enableDomStorage,
    required this.universalLinksOnly,
  });

  final String url;
  final bool useSafariVC;
  final bool useWebView;
  final bool enableJavaScript;
  final bool enableDomStorage;
  final bool universalLinksOnly;
}

/// Installs [fake] as url_launcher's platform for the current test, and puts
/// the method-channel implementation back afterwards — a leaked fake would
/// silently absorb the launch of any other test's url in the same isolate.
void stubUrlLauncher(FakeUrlLauncher fake) {
  final previous = UrlLauncherPlatform.instance;
  UrlLauncherPlatform.instance = fake;
  addTearDown(() => UrlLauncherPlatform.instance = previous);
}
