import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// path_provider's platform seam: every temporary-directory lookup answers
/// with [root], a path the test chose, so the compression/cache round-trip
/// runs against a location that exists in the test environment.
///
/// Install with `PathProviderPlatform.instance = StubPathProvider(root)` and
/// restore the previous instance in an `addTearDown` — a leaked fake hands
/// the next test's cache writes a directory the test never created.
///
/// Carried by two files (settings' picture buttons and user's profile-picture
/// provider) before it lived here.
class StubPathProvider extends PathProviderPlatform {
  StubPathProvider(this.root);

  final String root;

  @override
  Future<String?> getTemporaryPath() async => root;
}
