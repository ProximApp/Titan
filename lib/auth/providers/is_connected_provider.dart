import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/version/providers/version_verifier_provider.dart';

/// Whether the backend answered the last time we asked.
///
/// This used to issue its own `GET {BACKEND_HOST}information` on startup, which
/// is the very request [versionVerifierProvider] already makes — that endpoint
/// exists to report the API version and, in Hyperion's own words, "can be used
/// to check if the API is up". Two providers therefore hit the same URL about
/// ten milliseconds apart on every cold start, one of them competing for
/// bandwidth with the bundle still downloading. Reusing the result costs
/// nothing and removes a round trip.
///
/// `loading` counts as disconnected so that the app shows its offline state
/// while the first check is still in flight, which is what the previous
/// implementation did by starting at `false`.
class IsConnectedProvider extends Notifier<bool> {
  @override
  bool build() => ref
      .watch(versionVerifierProvider)
      .maybeWhen(data: (_) => true, orElse: () => false);

  /// Asks again. Wired to the retry button of the no-internet page.
  Future<void> isInternet() async {
    await ref.read(versionVerifierProvider.notifier).loadVersion();
  }
}

final isConnectedProvider = NotifierProvider<IsConnectedProvider, bool>(
  IsConnectedProvider.new,
);
