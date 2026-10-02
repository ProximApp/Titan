import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chopper/chopper.dart' as chopper;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:toastification/toastification.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/auth/repository/auth_repository.dart';
import 'package:titan/booking/providers/user_manager_list_provider.dart';
import 'package:titan/loan/providers/user_loaner_list_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/mypayment/providers/bank_account_holder_provider.dart';
import 'package:titan/mypayment/providers/invoice_list_provider.dart';
import 'package:titan/mypayment/providers/key_service_provider.dart';
import 'package:titan/mypayment/providers/my_stores_provider.dart';
import 'package:titan/mypayment/providers/selected_structure_provider.dart';
import 'package:titan/mypayment/providers/store_sellers_list_provider.dart';
import 'package:titan/mypayment/providers/structure_list_provider.dart';
import 'package:titan/admin/providers/all_group_list_provider.dart';
import 'package:titan/admin/providers/my_association_list_provider.dart';
import 'package:titan/mypayment/tools/key_service.dart';
import 'package:titan/navigation/providers/navbar_animation.dart';
import 'package:titan/navigation/providers/should_setup_provider.dart';
import 'package:titan/purchases/providers/seller_list_provider.dart';
import 'package:titan/router.dart';
import 'package:titan/service/class/firebase_toke_expiration.dart';
import 'package:titan/service/providers/firebase_token_expiration_provider.dart';
import 'package:titan/service/providers/firebase_token_provider.dart';
import 'package:titan/super_admin/providers/permission_name_list_provider.dart';
import 'package:titan/tools/ui/layouts/app_template.dart';
import 'package:titan/super_admin/providers/permissions_list_provider.dart';
import 'package:titan/tools/logs/log.dart';
import 'package:titan/tools/logs/logger.dart';
import 'package:titan/tools/logs/logger_output.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/user/providers/user_provider.dart';
import 'package:titan/version/providers/titan_version_provider.dart';
import 'package:titan/version/providers/version_verifier_provider.dart';

class MockRepository extends Mock implements Openapi {}

/// The camera never runs under the test binding: every mobile_scanner
/// controller is driven by MobileScannerPlatform.instance, so replacing the
/// platform with this fake both boots any scanner surface (start returns a
/// granted-permission view state) and lets a test inject a scan result onto
/// the real barcode stream the app's ScannerState listens to.
///
/// The MobileScanner widget renders whatever buildCameraView() returns, so
/// a blank box stands in for the camera texture. Install with
/// `MobileScannerPlatform.instance = FakeMobileScannerPlatform()` (and
/// restore the previous instance in tearDown) BEFORE pumping the page.
/// The scan flow's 5s anti-double-scan gate compares DateTime.now()
/// (wall clock, unaffected by fake-async pumps) — clear
/// lastTimeScannedProvider instead of pumping time.
class FakeMobileScannerPlatform extends MobileScannerPlatform {
  final _barcodes = StreamController<BarcodeCapture?>.broadcast();
  int startCount = 0;
  int stopCount = 0;

  void emitScan(String rawValue) {
    _barcodes.add(BarcodeCapture(barcodes: [Barcode(rawValue: rawValue)]));
  }

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    startCount++;
    return MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: ui.Size(1280, 720),
      numberOfCameras: 2,
    );
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> toggleTorch() async {}

  @override
  Future<void> updateScanWindow(ui.Rect? window) async {}

  @override
  Future<void> resetZoomScale() async {}

  @override
  Future<void> setZoomScale(double zoomScale) async {}

  @override
  Future<void> setFocusPoint(ui.Offset position) async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) async => null;

  @override
  Widget buildCameraView() => const SizedBox.expand();

  @override
  Future<Set<CameraLensType>> getSupportedLenses({
    CameraFacing? facing,
  }) async => const {};

  @override
  Future<CameraLensType?> getBestCloseRangeScanningLens({
    CameraFacing facing = CameraFacing.back,
  }) async => null;
}

/// firebase_core's platform side. `Firebase.initializeApp()` and
/// `FirebaseMessaging.instance` both need a default app to exist —
/// Firebase.app() throws `[core/no-app]` otherwise, and no test has one,
/// because main() initializes Firebase outside any test's reach.
class FakeFirebaseCore extends FirebasePlatform {
  FirebaseAppPlatform? _app;

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    final app = FirebaseAppPlatform(
      name ?? defaultFirebaseAppName,
      options ??
          const FirebaseOptions(
            apiKey: 'fake-api-key',
            appId: '1:1:fake:1',
            messagingSenderId: '0',
            projectId: 'fake-project',
          ),
    );
    _app = app;
    return app;
  }

  /// FirebaseMessaging.instance resolves the default app through here, so a
  /// fake that only implemented initializeApp would still throw `[core/no-app]`
  /// the moment anything touched Firebase.app().
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    final app = _app;
    if (app == null || app.name != name) {
      throw StateError('No fake Firebase App "$name" has been created.');
    }
    return app;
  }

  @override
  List<FirebaseAppPlatform> get apps =>
      _app == null ? const [] : <FirebaseAppPlatform>[_app!];
}

/// firebase_messaging's platform side: answers the permission prompt and the
/// token request, and counts the token calls so a test can assert that the
/// token came from the platform and not from a provider override. Everything
/// else keeps the interface's UnimplementedError default.
/// local_auth's `authenticate()` is a method channel to the OS biometric
/// prompt, which does not exist in a test env. The pay and fund confirm
/// buttons call it on every submit, so the flows need a platform fake whose
/// answer a test can flip per case (denied / accepted).
class FakeLocalAuth extends LocalAuthPlatform {
  FakeLocalAuth(this.authenticateResult);

  /// What `authenticate()` resolves to. `false` is the "user cancelled"
  /// outcome the confirm buttons turn into an error toast.
  final bool authenticateResult;
  int authenticateCalls = 0;
  final List<String> reasons = [];

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    authenticateCalls++;
    reasons.add(localizedReason);
    return authenticateResult;
  }

  @override
  Future<bool> deviceSupportsBiometrics() async => authenticateResult;

  @override
  Future<bool> isDeviceSupported() async => authenticateResult;
}

/// Installs [fake] as local_auth's platform for the current test.
void stubLocalAuth(FakeLocalAuth fake) {
  LocalAuthPlatform.instance = fake;
}

class FakeFirebaseMessaging extends FirebaseMessagingPlatform {
  FakeFirebaseMessaging(this.status);

  final AuthorizationStatus status;
  int tokenCalls = 0;

  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async {
    tokenCalls++;
    return 'fake-fcm-token';
  }

  /// FirebaseMessaging's constructor goes through instanceFor →
  /// delegateFor().setInitialValues(), so a fake that only overrides the two
  /// methods under test still throws UnimplementedError on first use.
  @override
  FirebaseMessagingPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseMessagingPlatform setInitialValues({bool? isAutoInitEnabled}) => this;

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async => NotificationSettings(
    alert: AppleNotificationSetting.enabled,
    announcement: AppleNotificationSetting.enabled,
    authorizationStatus: status,
    badge: AppleNotificationSetting.enabled,
    carPlay: AppleNotificationSetting.notSupported,
    criticalAlert: AppleNotificationSetting.disabled,
    lockScreen: AppleNotificationSetting.enabled,
    notificationCenter: AppleNotificationSetting.enabled,
    providesAppNotificationSettings: providesAppNotificationSettings
        ? AppleNotificationSetting.enabled
        : AppleNotificationSetting.disabled,
    showPreviews: AppleShowPreviewSetting.whenAuthenticated,
    sound: AppleNotificationSetting.enabled,
    timeSensitive: AppleNotificationSetting.disabled,
  );
}

/// Installs the messaging fake and returns it. No teardown: the platform
/// instance is process-global, every file that needs it runs in its own
/// isolate, and there is no meaningful previous value to restore (reading it
/// would construct the MethodChannel implementation just to throw it away).
FakeFirebaseMessaging stubFirebaseMessaging(AuthorizationStatus status) {
  final fake = FakeFirebaseMessaging(status);
  FirebaseMessagingPlatform.instance = fake;
  return fake;
}

chopper.Response<T> chopperResponse<T>(T body) =>
    chopper.Response(http.Response('body', 200), body);

chopper.Response<List<T>> chopperListResponse<T>(List<T> body) =>
    chopper.Response(http.Response('body', 200), body);

chopper.Response<void> chopperResponseVoid() =>
    chopper.Response(http.Response('body', 200), null);

/// Mirrors the private channel of flutter_local_notifications' platform
/// implementations. Returns the live list of every call the plugin made
/// through it, in order (initialize / show / periodicallyShow / cancel /
/// createNotificationChannelGroup / pendingNotificationRequests /
/// getActiveNotifications), so a test can assert on the plugin's behaviour
/// without the platform. Lives here because the service wrapper, the
/// background FCM handler and the notification-settings tests all drive the
/// same channel.
const MethodChannel _localNotificationsChannel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

List<MethodCall> stubLocalNotificationsChannel({
  List<Map<String, Object?>> pending = const [],
  List<Map<String, Object?>> active = const [],
}) {
  final calls = <MethodCall>[];
  TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_localNotificationsChannel, (call) async {
        calls.add(call);
        switch (call.method) {
          case 'initialize':
            return true;
          case 'pendingNotificationRequests':
            return pending;
          case 'getActiveNotifications':
            return active;
          default:
            return null;
        }
      });
  addTearDown(
    () => TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_localNotificationsChannel, null),
  );
  return calls;
}

/// Pumps a fixed number of frames for pages with a permanently-active
/// animation that never settle (see pumpApp's pumpAndSettle: false).
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// A 1x1 transparent PNG - the smallest thing `Image.network` can decode.
final _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

HttpOverrides? _imageOverrides;

/// Serves [_onePixelPng] for every image request.
///
/// `flutter_test` answers every HTTP request with a 400, so a widget that
/// builds an `Image.network` unconditionally - `LinkCard` draws its module
/// logo straight from a URL, with no provider to stub - dies with
/// `NetworkImageLoadException` before it lays out, which would make "no
/// overflow" true for the wrong reason. An `.svg` URL gets the PNG too;
/// `flutter_svg` fails to parse it and draws its placeholder, which is what
/// a broken asset looks like anyway.
void stubNetworkImages() {
  if (_imageOverrides != null) return;
  _imageOverrides = HttpOverrides.global = _PixelImageOverrides();
}

/// `implements` + `noSuchMethod` rather than `extends`: only [getUrl] is ever
/// called, and Dart lets the rest of the interface be absent that way.
class _PixelImageOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _PixelImageClient();
}

class _PixelImageClient implements HttpClient {
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('the card sweep only issues getUrl');

  /// `NetworkImage._sharedHttpClient` reads both of these off the client
  /// before it ever makes a request.
  @override
  bool autoUncompress = true;

  @override
  int? maxConnectionsPerHost = 6;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _PixelRequest();
}

class _PixelRequest implements HttpClientRequest {
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('the card sweep only closes the request');

  @override
  Future<HttpClientResponse> close() async => _PixelResponse();
}

/// Only `statusCode`, `contentLength` and the byte stream are ever read, and
/// `listen` is routed through [noSuchMethod] rather than declared: its
/// `void Function(StreamEvent<List<int>>)` parameter type is not available
/// to this SDK's `dart:async`, and `Stream.value(...).listen` is a drop-in
/// for it at runtime.
class _PixelResponse implements HttpClientResponse {
  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #listen) {
      final stream = Stream<List<int>>.value(_onePixelPng);
      return Function.apply(
        stream.listen,
        invocation.positionalArguments,
        Map.of(invocation.namedArguments),
      );
    }
    throw UnimplementedError('the image loader reads ${invocation.memberName}');
  }

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => _onePixelPng.length;

  /// The image loader checks this before decoding.
  @override
  HttpHeaders get headers => _PngHeaders();

  /// `consolidateHttpClientResponseBytes` branches on this.
  @override
  HttpClientResponseCompressionState compressionState =
      HttpClientResponseCompressionState.notCompressed;
}

/// `HttpHeaders` is abstract on the VM, and the loader only ever reads
/// `contentType` off it.
class _PngHeaders implements HttpHeaders {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  ContentType get contentType => ContentType('image', 'png');
}

/// The app's own font families, loaded from `assets/google_fonts/`.
///
/// `flutter_test` draws every glyph as a square of the font size, so the
/// default test font measures every localized label one to two times wider
/// than a device does. That is why convention 20 exists: an overflow under
/// the harness font is not evidence of a layout bug. Registering the REAL
/// faces turns the harness into a device-width oracle, which is the only way
/// a "mount it at 360 and fail on overflow" sweep can be trusted.
///
/// Lato is the body family — `main.dart` sets
/// `GoogleFonts.latoTextTheme(Theme.of(context).textTheme)`. Roboto is
/// declared in pubspec only so the web engine stops downloading it from
/// fonts.gstatic.com before the first paint. ElMessiri and Silkscreen are
/// bundled for the handful of `GoogleFonts.*` call sites (flappybird, and
/// one home page).
///
/// Only the weights actually bundled are registered; anything heavier is
/// faux-bolded by Skia, exactly as on device, where the font manifest
/// declares the same single face.
const Map<String, List<String>> appFontFiles = {
  'Lato': ['Lato-Regular.ttf', 'Lato-Bold.ttf'],
  'Roboto': ['Roboto-Regular.ttf'],
  'El Messiri': ['ElMessiri-Regular.ttf', 'ElMessiri-Bold.ttf'],
  'Silkscreen': ['Silkscreen-Regular.ttf', 'Silkscreen-Bold.ttf'],
};

/// `ThemeData` matching the app's, with Lato as the body family instead of
/// the harness font. Only `textTheme` is touched: the cards under test style
/// their own `Text`s with sizes and colours, and those merge with (and
/// therefore inherit the family from) this.
ThemeData get appTheme => ThemeData(
  useMaterial3: false,
  textTheme: Typography.material2021().black.apply(fontFamily: 'Lato'),
);

bool _appFontsLoaded = false;

/// Registers [appFontFiles] with the engine. Idempotent, and safe to call
/// from every test that needs it — `FontLoader` replaces a family wholesale.
Future<void> loadAppFonts() async {
  if (_appFontsLoaded) return;
  _appFontsLoaded = true;
  for (final entry in appFontFiles.entries) {
    final loader = FontLoader(entry.key);
    for (final name in entry.value) {
      final bytes = File('assets/google_fonts/$name').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

/// A structure the given user manages: myStructuresProvider matches on
/// managerUser.id, not managerUserId.
Structure structure(String id, String name, String userId) =>
    Structure.empty().copyWith(
      id: id,
      name: name,
      managerUserId: userId,
      managerUser: CoreUserSimple.empty().copyWith(id: userId),
    );

/// A confirmed direct transaction, the shape every history-list page reads.
History history(String id, HistoryDirection direction, int total) =>
    History.empty().copyWith(
      id: id,
      type: HistoryType.directTransaction,
      direction: direction,
      otherWalletName: 'BDE',
      total: total,
      creation: DateTime(2026, 1, 5, 12, 30),
      status: TransactionStatus.confirmed,
    );

/// The store fixture shared by the mypayment store pages.
final myPaymentStore = UserStore.empty().copyWith(
  id: 'store-1',
  name: 'Fridge',
  structureId: 'structure-1',
  structure: Structure.empty().copyWith(id: 'structure-1', name: 'BDE'),
);

/// The real KeyService reads the APP_ID_PREFIX dart-define at construction
/// and throws without it, and reads secure storage for every getter. The
/// payment pages only need getKeyId() (the FutureBuilder in DevicesPage
/// dereferences it), so a fake with a configurable key id keeps every test
/// command free of build-specific defines.
///
/// It also answers `getKeyPair()` and `signMessage()`, because the pay
/// flow's QR modal is built from a REAL Ed25519 signature
/// (`getQRCodeContent` signs the payload and base64s the bytes). Leaving
/// those unimplemented would make `QrCode`'s FutureBuilder render its error
/// branch, and the whole point of that test is the QR appearing. The keys
/// are pure Dart — cryptography_plus has no platform side — so a real
/// in-memory pair is both cheaper and more honest than a stubbed signature.
class FakeKeyService extends Fake implements KeyService {
  FakeKeyService([this.keyId]);

  /// A plain mutable field so a test can reach the branches that read the key
  /// a SECOND time after the first read already passed — the pay confirm
  /// button re-reads `getKeyId()` after the biometric and refuses the QR when
  /// it has gone.
  String? keyId;

  final _algorithm = Ed25519();
  SimpleKeyPair? _keyPair;

  @override
  Future<String?> getKeyId() async => keyId;

  /// Null when [keyId] is null, mirroring the real service's "no device
  /// registered" answer rather than handing back a key nothing points at.
  @override
  Future<SimpleKeyPair?> getKeyPair() async {
    if (keyId == null) return null;
    return _keyPair ??= await _algorithm.newKeyPair();
  }

  @override
  Future<Signature> signMessage(SimpleKeyPair keyPair, List<int> message) =>
      _algorithm.sign(message, keyPair: keyPair);
}

/// The real Logger kicks off an async init() that REPLACES loggerOutput
/// (PrintLoggerOutput on web, FileLoggerOutput on IO); under tests that would
/// wipe the injected fake after the first await. The stub skips init and
/// serves the injected output from the start.
class _StubLogger extends Logger {
  _StubLogger(LoggerOutput output) {
    loggerOutput = output;
  }

  @override
  Future<void> init() async {}
}

/// Records what the logger actually handed to its output, so a test can tell
/// a line that was WRITTEN from one the logger's threshold silently dropped:
/// both look like a logger that was never called. Pair it with
/// [IntegrationScaffold.stubLoggerOutput].
class CapturingLoggerOutput implements LoggerOutput {
  final List<Log> logs = [];
  final List<Log> notifications = [];

  @override
  Future<void> init() async {}

  @override
  void writeLog(Log log) {
    if (log.level == LogLevel.notification) {
      notifications.add(log);
      return;
    }
    logs.add(log);
  }

  @override
  List<Log> getLogs() => logs;

  @override
  List<Log> getNotificationLogs() => notifications;

  @override
  void clearLogs() => logs.clear();

  @override
  void clearNotificationLogs() => notifications.clear();
}

/// The real verifier calls the backend through the repository; the middleware
/// only needs the data branch to decide the app is up to date.
class FakeVersionVerifierNotifier extends VersionVerifierNotifier {
  @override
  AsyncValue<CoreInformation> build() => AsyncValue.data(
    CoreInformation(ready: true, version: '1.0.0', minimalTitanVersionCode: 1),
  );
}

/// The boot screen's LoadingPage answers to this notifier's `when`: on data it
/// routes to the update page, the login page, or the forwarded path, so a test
/// that wants to observe its spinner has to keep it unresolved.
class FakeHoldingVersionVerifierNotifier extends VersionVerifierNotifier {
  @override
  AsyncValue<CoreInformation> build() => AsyncValue<CoreInformation>.loading();
}

/// The real notifier calls PackageInfo.fromPlatform(), which has no platform
/// channel in tests; the middleware only needs an int to compare against the
/// backend's minimal version.
class FakeTitanVersionNotifier extends TitanVersionNotifier {
  @override
  int build() => 999;
}

/// The real provider derives the session from the OIDC token storage, which
/// does not exist in the test environment; the flow under test needs a user
/// that is already signed in.
class FakeIsLoggedInNotifier extends IsLoggedInProvider {
  @override
  bool build() => true;
}

/// Same, for the signed-out branch (the login page): the real build watches
/// the connectivity probe and decodes JWTs from storage.
class FakeIsLoggedOutNotifier extends IsLoggedInProvider {
  @override
  bool build() => false;
}

/// The real notifier calls getTokenFromStorage() on build, which hits the
/// repository; the signed-out login page only needs the loading state to be
/// resolved so no unstubbed repo call fires.
class FakeOpenIdTokenNotifier extends OpenIdTokenProvider {
  @override
  AsyncValue<models.TokenResponse> build() =>
      AsyncValue.error('no token in tests', StackTrace.empty);
}

/// The real notifier fetches the user from the backend; the module catalog
/// only needs the user record to compute the granted module roots.
class FakeAsyncUserNotifier extends UserNotifier {
  FakeAsyncUserNotifier(this.user);

  final CoreUser user;

  @override
  AsyncValue<CoreUser> build() => AsyncValue.data(user);
}

/// The real notifiers fetch the permission catalog; the module catalog only
/// needs the loading state resolved.
class FakePermissionsNamesListNotifier extends PermissionsNamesListNotifier {
  @override
  AsyncValue<List<String>> build() => AsyncValue.data(const []);
}

class FakePermissionsNotifier extends PermissionsNotifier {
  @override
  AsyncValue<List<CorePermission>> build() => AsyncValue.data(const []);
}

/// The real notifier reads the shared preferences cache; the notification
/// setup only needs a never-expiring record to skip re-registering tokens.
class FakeFirebaseTokenExpirationNotifier
    extends FirebaseTokenExpirationNotifier {
  @override
  FirebaseTokenExpiration build() => FirebaseTokenExpiration(
    'me',
    DateTime.now().add(const Duration(days: 30)),
  );
}

/// Pre-seeds the associations the signed-in user is a member of: the advert
/// admin gate (isUserAMemberOfAnAssociationProvider), the advert
/// AssociationBar and AdminAdvertCard derive from this list without backend
/// calls (the real notifier fires associationsMeGet).
class FakeMyAssociationListNotifier extends MyAssociationListNotifier {
  FakeMyAssociationListNotifier(this.associations);

  final List<Association> associations;

  @override
  AsyncValue<List<Association>> build() => AsyncValue.data(associations);
}

/// Pre-seeds the structures the user manages: isStructureAdminProvider and
/// the structure-stores page derive from this list without backend calls.
class FakeStructureListNotifier extends StructureListNotifier {
  FakeStructureListNotifier(this.structures);

  final List<Structure> structures;

  @override
  AsyncValue<List<Structure>> build() => AsyncValue.data(structures);
}

/// Pre-seeds the bank account holder structure: the invoices-admin
/// AdminMiddleware gate reads it asynchronously at redirect time.
class FakeBankAccountHolderNotifier extends BankAccountHolderNotifier {
  FakeBankAccountHolderNotifier(this.holder);

  final Structure holder;

  @override
  AsyncValue<Structure> build() => AsyncValue.data(holder);
}

/// Pre-seeds the structure the admin is currently working on (the structure
/// stores and structure invoices pages render its name and filter on it).
class FakeSelectedStructureNotifier extends SelectedStructureNotifier {
  FakeSelectedStructureNotifier(this.structure);

  final Structure structure;

  @override
  Structure build() => structure;
}

/// Pre-seeds the invoice list. The real notifier's build() returns loading
/// and the invoices pages only call the repository from pull-to-refresh or
/// the pagination callbacks, so without this the pages render their loading
/// branch forever (see README known bugs).
class FakeInvoiceListNotifier extends InvoiceListNotifier {
  FakeInvoiceListNotifier(this.invoices);

  final List<Invoice> invoices;

  @override
  AsyncValue<List<Invoice>> build() => AsyncValue.data(invoices);
}

/// Pre-seeds the manager list for the signed-in user: isManagerProvider —
/// the booking manager-route gate — watches it asynchronously, so a deep
/// link would be bounced before the repository answer lands.
class FakeUserManagerListNotifier extends UserManagerListNotifier {
  FakeUserManagerListNotifier(this.managers);

  final List<Manager> managers;

  @override
  AsyncValue<List<Manager>> build() => AsyncValue.data(managers);
}

class FakeUserLoanerListNotifier extends UserLoanerListNotifier {
  FakeUserLoanerListNotifier(this.loaners);

  final List<Loaner> loaners;

  @override
  AsyncValue<List<Loaner>> build() => AsyncValue.data(loaners);
}

/// Pre-seeds the stores the user sells for: the tickets admin gate derives
/// canManageTicketEventsProvider from this list without backend calls.
class FakeMyStoresNotifier extends MyStoresNotifier {
  FakeMyStoresNotifier(this.stores);

  final List<models.UserStore> stores;

  @override
  AsyncValue<List<models.UserStore>> build() => AsyncValue.data(stores);
}

/// Pre-seeds the sellers of one store (the family member of the tickets
/// admin gate): Seller.canManageEvents decides whether AdminMiddleware
/// lets the user into the tickets admin routes.
class FakeStoreSellerListNotifier extends StoreSellerListNotifier {
  FakeStoreSellerListNotifier(super.storeId, this.sellers);

  final List<Seller> sellers;

  @override
  AsyncValue<List<Seller>> build() => AsyncValue.data(sellers);
}

/// Pre-seeds the sellers the user scans for: isPurchasesAdminProvider (the
/// purchases scan-route gate) watches sellerListProvider asynchronously —
/// pre-seeding makes the AdminMiddleware verdict deterministic instead of
/// racing cdrSellersGet, and the scan page renders these chips directly.
class FakePurchasesSellerListNotifier extends SellerListNotifier {
  FakePurchasesSellerListNotifier(this.sellers);

  final List<SellerComplete> sellers;

  @override
  AsyncValue<List<SellerComplete>> build() => AsyncValue.data(sellers);
}

/// The real provider defaults to true, which triggers the notification setup
/// (Firebase, local notifications) for signed-in users; none of that exists
/// in the test environment.
class FakeShouldSetupNotifier extends ShouldSetupProvider {
  @override
  bool build() => false;
}

/// Boots the full real route table through the real Qlevar delegate: real
/// middlewares, real deferred page loading, real l10n and the real
/// NavigationTemplate — only the network edge and the session bootstrap are
/// mocked. Shared by every main-page integration test.
class IntegrationScaffold {
  /// Set by [stubLoggerOutput] before [makeContainer]; when present the
  /// container wires loggerProvider to a logger reading from it instead of
  /// opening the on-disk log file.
  LoggerOutput? _loggerOutput;
  final MockRepository repository = MockRepository();

  /// The standard shell-file preamble: reset the router, mock shared prefs,
  /// and stub the two endpoints the boot redirect chain touches ('/' always
  /// forwards to /feed before the page under test is processed). Call from
  /// `setUp`, with the scaffold as the file's `late` field — every shell
  /// file previously repeated these five lines by hand.
  void shellSetUp() {
    TestWidgetsFlutterBinding.ensureInitialized();
    QR.reset();
    SharedPreferences.setMockInitialValues({});
    stubInformation();
    stubFeed();
  }

  /// Stubs the admin main page's background loads. Admin sub-page shells
  /// mount the admin main page underneath (route-tree parent), and its
  /// module cards fan out across the catalog endpoints — all five were
  /// copy-pasted into every admin sub-page test file.
  void stubAdminMainPage() {
    when(() => repository.groupsGet()).thenAnswer(
      (_) async =>
          chopper.Response(http.Response('body', 200), <CoreGroupSimple>[]),
    );
    when(() => repository.mypaymentBankAccountHolderGet()).thenAnswer(
      (_) async => chopper.Response(
        http.Response('body', 200),
        models.Structure.empty(),
      ),
    );
    when(() => repository.mypaymentStructuresGet()).thenAnswer(
      (_) async =>
          chopper.Response(http.Response('body', 200), <models.Structure>[]),
    );
    when(() => repository.associationsGet()).thenAnswer(
      (_) async =>
          chopper.Response(http.Response('body', 200), <models.Association>[]),
    );
    when(() => repository.membershipsGet()).thenAnswer(
      (_) async => chopper.Response(
        http.Response('body', 200),
        <models.MembershipSimple>[],
      ),
    );
  }

  /// [userId] overrides the JWT-derived session id consumed by pages that
  /// fetch user-scoped data (raffle tickets, amap cash and orders).
  ///
  /// [seedAsyncUser] also pins asyncUserProvider to [user]. Pages that SAVE
  /// through it (EditProfile) call the real UserNotifier otherwise: its
  /// build fires usersMeGet against the mock and never resolves to data, and
  /// SingleNotifierAPI silently refuses the update while loading. Opt-in
  /// because resolving the async user on frame 1 shifts when every page
  /// watching it rebuilds — several older shells depend on the loading
  /// window (amap's known-quirk filtering).
  ///
  /// [myStructures], [bankAccountHolder] and [selectedStructure] pre-seed the
  /// mypayment admin state: AdminMiddleware gates on providers that resolve
  /// asynchronously from the repository, so a deep link would be bounced
  /// before the data lands. Fake notifiers make the gate deterministic.
  ProviderContainer makeContainer({
    CoreUser? user,
    String? userId,
    List<Structure> myStructures = const [],
    Structure? bankAccountHolder,
    Structure? selectedStructure,
    List<Invoice> invoices = const [],
    List<Association> myAssociations = const [],
    List<Manager> myManagerRoles = const [],
    List<Loaner> myLoaners = const [],
    bool seedAsyncUser = false,
    List<models.UserStore> myStores = const [],
    Map<String, List<Seller>> storeSellers = const {},
    List<CoreGroupSimple> groups = const [],
    List<SellerComplete> purchasesSellers = const [],

    /// Opt-in for the ONE test surface the harness normally gates shut:
    /// NavigationTemplate only calls setUpNotification for a non-empty user
    /// while shouldSetupProvider is true, and both Firebase providers hit
    /// platform channels that do not exist in tests. A test that passes this
    /// owns the FirebaseMessagingPlatform/FirebasePlatform fakes itself.
    bool runNotificationSetup = false,

    /// Holds the version verifier in its loading state, so a page that routes
    /// on its answer (the boot screen's LoadingPage) stays put instead of
    /// resolving and redirecting away on the first frame. Riverpod 3 exports
    /// no Override type, so overrides are swapped by flag, not by list.
    bool holdVersionVerifier = false,

    /// What `KeyService.getKeyId()` resolves to. Null (the default) is the
    /// "no device registered" answer, which is what most tests want: it keeps
    /// the mypayment pay/fund confirm buttons on their error branch instead of
    /// reaching the platform. Pass a value to let the pay flow get past the
    /// account card's device gate.
    String? deviceKeyId,
  }) {
    return ProviderContainer(
      overrides: [
        if (_loggerOutput != null)
          loggerProvider.overrideWith((ref) => _StubLogger(_loggerOutput!)),
        repositoryProvider.overrideWithValue(repository),
        versionVerifierProvider.overrideWith(
          holdVersionVerifier
              ? FakeHoldingVersionVerifierNotifier.new
              : FakeVersionVerifierNotifier.new,
        ),
        titanVersionProvider.overrideWith(FakeTitanVersionNotifier.new),
        isLoggedInProvider.overrideWith(FakeIsLoggedInNotifier.new),
        userProvider.overrideWithValue(user ?? CoreUser.empty()),
        if (seedAsyncUser && user != null)
          asyncUserProvider.overrideWith(() => FakeAsyncUserNotifier(user)),
        keyServiceProvider.overrideWith((ref) => FakeKeyService(deviceKeyId)),
        if (myAssociations.isNotEmpty)
          asyncMyAssociationListProvider.overrideWith(
            () => FakeMyAssociationListNotifier(myAssociations),
          ),
        userManagerListProvider.overrideWith(
          () => FakeUserManagerListNotifier(myManagerRoles),
        ),
        // The loan admin gate (`isLoanAdminProvider`) derives from the
        // repository-backed userLoanerListProvider — same deep-link-bounce
        // trap as the other async gates; pre-seed makes it deterministic.
        userLoanerListProvider.overrideWith(
          () => FakeUserLoanerListNotifier(myLoaners),
        ),
        if (myStructures.isNotEmpty)
          structureListProvider.overrideWith(
            () => FakeStructureListNotifier(myStructures),
          ),
        if (bankAccountHolder != null)
          bankAccountHolderProvider.overrideWith(
            () => FakeBankAccountHolderNotifier(bankAccountHolder),
          ),
        if (selectedStructure != null)
          selectedStructureProvider.overrideWith(
            () => FakeSelectedStructureNotifier(selectedStructure),
          ),
        invoiceListProvider.overrideWith(
          () => FakeInvoiceListNotifier(invoices),
        ),
        if (userId != null)
          idProvider.overrideWith((ref) => Future<String>.value(userId)),
        // NavigationTemplate runs the notification setup for any non-empty
        // user when shouldSetup is true; both Firebase providers hit platform
        // channels that do not exist in tests, so the gate stays shut unless
        // the test opts in with runNotificationSetup: true.
        firebaseTokenProvider.overrideWithValue(Future.value('test-token')),
        if (!runNotificationSetup)
          shouldSetupProvider.overrideWith(FakeShouldSetupNotifier.new),
        // The tickets admin gate (canManageTicketEventsProvider) chains
        // myStoresProvider → sellerStoreProvider(store.id) → canManageEvents;
        // pre-seeding makes the gate deterministic instead of racing the
        // middleware's redirectGuard against repository answers.
        if (myStores.isNotEmpty)
          myStoresProvider.overrideWith(() => FakeMyStoresNotifier(myStores)),
        ...storeSellers.entries.map(
          (entry) => sellerStoreProvider(entry.key).overrideWith(
            () => FakeStoreSellerListNotifier(entry.key, entry.value),
          ),
        ),
        // Pages resolve group names from the group list with bare
        // firstWhere calls; pre-seeding the derived provider makes those
        // lookups deterministic instead of racing groupsGet.
        if (groups.isNotEmpty) allGroupList.overrideWithValue(groups),
        if (purchasesSellers.isNotEmpty)
          sellerListProvider.overrideWith(
            () => FakePurchasesSellerListNotifier(purchasesSellers),
          ),
      ],
    );
  }

  /// Same as [makeContainer] but for the signed-out session the login page
  /// renders under: no navbar user, no stored token, resolved permission
  /// state so AppSignIn's data-wait logic never blocks on a repo call.
  /// [authRepository] replaces the default repository-backed one — pass a
  /// real AuthRepository wired to [repository] to exercise the actual
  /// sign-in flow (Riverpod 3 does not export its Override type, so an
  /// overrides list parameter is not possible here).
  ProviderContainer makeLoggedOutContainer({AuthRepository? authRepository}) {
    return ProviderContainer(
      overrides: [
        if (_loggerOutput != null)
          loggerProvider.overrideWith((ref) => _StubLogger(_loggerOutput!)),
        repositoryProvider.overrideWithValue(repository),
        versionVerifierProvider.overrideWith(FakeVersionVerifierNotifier.new),
        titanVersionProvider.overrideWith(FakeTitanVersionNotifier.new),
        isLoggedInProvider.overrideWith(FakeIsLoggedOutNotifier.new),
        authTokenProvider.overrideWith(FakeOpenIdTokenNotifier.new),
        if (authRepository != null)
          authRepositoryProvider.overrideWithValue(authRepository),
        userProvider.overrideWithValue(CoreUser.empty()),
        asyncUserProvider.overrideWith(
          () => FakeAsyncUserNotifier(CoreUser.empty()),
        ),
        permissionsNamesListProvider.overrideWith(
          FakePermissionsNamesListNotifier.new,
        ),
        permissionsProvider.overrideWith(FakePermissionsNotifier.new),
        firebaseTokenProvider.overrideWithValue(Future.value('test-token')),
        shouldSetupProvider.overrideWith(FakeShouldSetupNotifier.new),
      ],
    );
  }

  /// Container for the real sign-in flow: like [makeLoggedOutContainer] but
  /// WITHOUT the isLoggedIn fake — the real IsLoggedInProvider derives the
  /// session from the token state (error → signed out at boot, data → signed
  /// in after the flow), so middlewares see the transition the login
  /// produces instead of a pinned false.
  ProviderContainer makeSignInFlowContainer({
    required AuthRepository authRepository,
  }) {
    return ProviderContainer(
      overrides: [
        if (_loggerOutput != null)
          loggerProvider.overrideWith((ref) => _StubLogger(_loggerOutput!)),
        repositoryProvider.overrideWithValue(repository),
        versionVerifierProvider.overrideWith(FakeVersionVerifierNotifier.new),
        titanVersionProvider.overrideWith(FakeTitanVersionNotifier.new),
        authTokenProvider.overrideWith(FakeOpenIdTokenNotifier.new),
        authRepositoryProvider.overrideWithValue(authRepository),
        userProvider.overrideWithValue(CoreUser.empty()),
        asyncUserProvider.overrideWith(
          () => FakeAsyncUserNotifier(CoreUser.empty()),
        ),
        permissionsNamesListProvider.overrideWith(
          FakePermissionsNamesListNotifier.new,
        ),
        permissionsProvider.overrideWith(FakePermissionsNotifier.new),
        firebaseTokenProvider.overrideWithValue(Future.value('test-token')),
        shouldSetupProvider.overrideWith(FakeShouldSetupNotifier.new),
      ],
    );
  }

  /// Same as [makeContainer] but resolves the module catalog chain (user,
  /// permissions, permission names) without backend calls. Pages backed by
  /// modulesProvider — the all-modules page, the navbar — need this.
  ProviderContainer makeContainerWithModules({CoreUser? user}) {
    return ProviderContainer(
      overrides: [
        if (_loggerOutput != null)
          loggerProvider.overrideWith((ref) => _StubLogger(_loggerOutput!)),
        repositoryProvider.overrideWithValue(repository),
        versionVerifierProvider.overrideWith(FakeVersionVerifierNotifier.new),
        titanVersionProvider.overrideWith(FakeTitanVersionNotifier.new),
        isLoggedInProvider.overrideWith(FakeIsLoggedInNotifier.new),
        userProvider.overrideWithValue(user ?? CoreUser.empty()),
        asyncUserProvider.overrideWith(
          () => FakeAsyncUserNotifier(user ?? CoreUser.empty()),
        ),
        permissionsNamesListProvider.overrideWith(
          FakePermissionsNamesListNotifier.new,
        ),
        permissionsProvider.overrideWith(FakePermissionsNotifier.new),
        // NavigationTemplate runs the notification setup for signed-in users
        // on non-web platforms; both Firebase providers hit platform
        // channels that do not exist in tests.
        firebaseTokenProvider.overrideWithValue(Future.value('test-token')),
        firebaseTokenExpirationProvider.overrideWith(
          () => FakeFirebaseTokenExpirationNotifier(),
        ),
        shouldSetupProvider.overrideWith(FakeShouldSetupNotifier.new),
      ],
    );
  }

  /// The WIDGET-test shell (`test/<module>/widget/`): the real
  /// ProviderScope, the real l10n delegates and the real toast wrapper, but
  /// NO router and no AppTemplate — for mounting one widget (a card, a row,
  /// a chip) instead of a whole page. Cards are where the fixed-width
  /// layout bugs live (ledgers #4/#38), and a card mounts in milliseconds
  /// where a page needs a navigation journey plus the one-deep-link-per-file
  /// rules of conventions 1/10.
  ///
  /// [surface] defaults to a 360x640 phone, deliberately far narrower than
  /// the integration shell's 1920x1080: a card that only fits on a desktop
  /// is the bug, and nothing filters overflows here.
  Future<void> pumpWidgetApp(
    WidgetTester tester,
    Widget child,
    ProviderContainer container, {
    // `ui.Size`, not `Size`: openapi.swagger.dart exports the amap slot enum
    // with a `Size` constant that shadows dart:ui's in this file.
    ui.Size surface = const ui.Size(360, 640),
    bool appFonts = false,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    if (appFonts) await loadAppFonts();
    if (appFonts) stubNetworkImages();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ToastificationWrapper(
          child: MaterialApp(
            theme: appFonts ? appTheme : null,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', 'US'), Locale('fr', 'FR')],
            home: Scaffold(body: child),
          ),
        ),
      ),
    );
    await settle(tester, frames: 4);
  }

  Future<void> pumpApp(
    WidgetTester tester,
    ProviderContainer container, {
    String initialPath = AppRouter.root,
    bool pumpAndSettle = true,
  }) async {
    // The real app wires the navbar animation controller in main.dart;
    // NavigationTemplate unwraps it with `animation!` and only shows the
    // navbar when the animation is completed, so a finished controller has
    // to be in place before any page renders.
    final animationNotifier = container.read(navbarAnimationProvider.notifier);
    final navbarController = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    addTearDown(navbarController.dispose);
    animationNotifier.setController(navbarController);
    // The middleware flips this on the first real redirect; the navbar is
    // only rendered for users it considers signed in. It is intentionally
    // NOT forwarded to a path: forward(path) would make every later
    // redirectGuard bounce the router back to that first path.

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        // Mirrors lib/main.dart's ToastificationWrapper: toasts fired with
        // a dead context (confirm flows that pop first) fall back to this
        // global overlay.
        child: ToastificationWrapper(
          child: MaterialApp.router(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', 'US'), Locale('fr', 'FR')],
            // The real app wraps every routed page in AppTemplate through this
            // builder; without it the NavigationTemplate (navbar, quit dialog)
            // never mounts.
            builder: (context, child) =>
                child == null ? const SizedBox() : AppTemplate(child: child),
            routeInformationParser: const QRouteInformationParser(),
            routerDelegate: QRouterDelegate(
              container.read(appRouterProvider).routes,
              initPath: initialPath,
            ),
          ),
        ),
      ),
    );
    if (pumpAndSettle) {
      await tester.pumpAndSettle();
    } else {
      // Pages with a permanently-active animation (a loader over a provider
      // that never resolves, a repeating timer) never settle; pump a fixed
      // number of frames instead so the test still observes rendered state.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }
  }

  /// The app targets desktop web widths; the default 800×600 test surface
  /// overflows wide rows on pages that render card lists. Call at the start
  /// of a testWidgets to opt into a desktop-sized viewport (1920×1080
  /// logical at DPR 1).
  void setWideSurface(WidgetTester tester) {
    tester.view.physicalSize = const ui.Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Stubs the connectivity probe the session bootstrap watches.
  void stubInformation() {
    when(() => repository.informationGet()).thenAnswer(
      (_) async => chopper.Response(
        http.Response('body', 200),
        CoreInformation(
          ready: true,
          version: '1.0.0',
          minimalTitanVersionCode: 1,
        ),
      ),
    );
  }

  /// Stubs the feed endpoints the boot redirect chain touches: '/' forwards
  /// to /feed through AuthenticatedMiddleware before the page under test is
  /// processed, so every initial-path test needs these in place.
  void stubFeed() {
    when(() => repository.feedNewsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), <News>[]),
    );
    when(
      () => repository.feedNewsNewsIdImageGet(newsId: any(named: 'newsId')),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "File does not exist"}', 404),
        [],
        error: 'File does not exist',
      ),
    );
  }

  /// Stubs the profile picture (a 404 reads as "no bytes" and falls back to
  /// the placeholder asset instead of crashing).
  void stubProfilePicture() {
    when(
      () =>
          repository.usersUserIdProfilePictureGet(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "File does not exist"}', 404),
        [],
        error: 'File does not exist',
      ),
    );
  }

  /// Registers an in-memory clipboard. Without a handler the Clipboard
  /// platform channel's reply never arrives inside the test zone: setData's
  /// .then callback never runs (no toast) and awaiting getData hangs the
  /// test body forever — FakeAsync cannot time out a pending future.
  void stubClipboard(WidgetTester tester) {
    String? text;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            text = (call.arguments as Map)['text'] as String?;
            return null;
          case 'Clipboard.getData':
            return text == null ? null : <String, dynamic>{'text': text};
          default:
            return null;
        }
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  /// Stubs the logger with a fake output so the log page renders from an
  /// in-memory list instead of opening the on-disk log file (IO paths do not
  /// exist under the test binding). Call it BEFORE makeContainer():
  /// overrides are applied at construction time.
  void stubLoggerOutput(LoggerOutput output) {
    _loggerOutput = output;
  }

  /// ---- Modal drivers ----
  ///
  /// Bottom-sheet modals are real `showModalBottomSheet` routes on the root
  /// navigator. They animate through a fixed-duration curve, so `settle()`
  /// alone cannot cross the transition; these helpers pump the modal open,
  /// run a step, and pump it closed. Use them instead of hand-rolled pump
  /// sequences so the modal lifecycle (navbar hide/show, frame pumping) is
  /// handled in one place.

  /// Taps [finder] and pumps the bottom sheet that the tap opens, until it
  /// stops animating. The modal renders on the ROOT navigator, so assertions
  /// afterwards use plain finders.
  Future<void> openModal(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump(); // start the modal route push
    await tester.pumpAndSettle(); // finish the slide-in animation
  }

  /// Pumps the currently open bottom sheet closed (taps nothing; use
  /// [tapInModal] or Navigator.pop first when the flow closes itself).
  Future<void> closeModal(WidgetTester tester) async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pop();
    await tester.pump(); // start the modal route pop
    await tester.pumpAndSettle(); // finish the slide-out animation
  }

  /// Taps a widget INSIDE the currently open bottom sheet. `find.text` etc.
  /// search the whole tree anyway; this just pumps the resulting modal
  /// transitions (nested sheets, self-closing flows).
  Future<void> tapInModal(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.pumpAndSettle();
  }

  /// True while a bottom-sheet modal route is on the root navigator.
  bool isModalOpen(WidgetTester tester) => tester
      .widgetList<ModalBarrier>(find.byType(ModalBarrier))
      .where((barrier) => barrier.dismissible)
      .isNotEmpty;

  /// ---- Form/tap helpers ----
  ///
  /// Reusable sequences every form page needs: scrolling a target into the
  /// real viewport, releasing field focus before tapping a submit button,
  /// and draining the shared toast timer.

  /// Brings [finder] into the actual viewport. scrollUntilVisible only
  /// guarantees the widget is BUILT (a ListView builds into its cache
  /// extent ahead of the viewport), which can leave it below the fold.
  /// The FloatingNavbar also overlays the bottom ~90px of the shell, so a
  /// bottom-aligned target is occluded: pass [bottomBand] to lift targets
  /// clear of it before the caller taps.
  Future<void> ensureOnScreen(
    WidgetTester tester,
    Finder finder, {
    double bottomBand = 0,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    if (bottomBand > 0) {
      final viewHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      var overlap = tester.getRect(finder).bottom - (viewHeight - bottomBand);
      while (overlap > 0) {
        await tester.drag(
          find.byType(Scrollable).first,
          Offset(0, -overlap - 10),
        );
        await settle(tester, frames: 4);
        overlap = tester.getRect(finder).bottom - (viewHeight - bottomBand);
      }
    }
    await settle(tester, frames: 2);
  }

  /// Releases the field focus so the next tap reaches the button instead
  /// of a page-level unfocus GestureDetector (convention 12).
  Future<void> unfocus(WidgetTester tester) async {
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
  }

  /// Drains the shared toast timer (`displayToast` auto-closes after
  /// 2500ms + a 400ms animation): without this the pending timer fails the
  /// test at teardown.
  Future<void> drainToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  }

  /// Unmounts the tree inside the test body and pumps once.
  ///
  /// Riverpod's ProviderScheduler defers autoDispose work to a zero-duration
  /// Timer. When an autoDisposed provider loses its last listener while the
  /// tree is being torn down, that Timer is armed AFTER the test's last pump,
  /// and flutter_test's "A Timer is still pending even after the widget tree
  /// was disposed" assertion fires. Unmounting here gives the scheduler a
  /// frame to run in. Needed by tests that leave a provider permanently
  /// loading (a hanging repository call), which is exactly the shape of the
  /// pages with a Loader on screen.
  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }
}

/// Filters the ONE Riverpod 3 quirk the amap cards cannot avoid.
///
/// `UserCashNotifier` and `UserOrderListNotifier` `return state` from
/// `build()`, which throws "Tried to read the state of an uninitialized
/// provider" once on the first build before the load they scheduled heals
/// the state. It is a real bug in the app (bug #3 in the README's list) and
/// filtering it is the only way to mount anything that watches those
/// providers — but the filter is deliberately narrow: it matches that one
/// message and nothing else, so every `A RenderFlex overflowed` still reaches
/// `FlutterError.onError` and stays fatal. That narrowness is what makes a
/// card layout test under this filter a real guard rather than a no-op.
void ignoreAmapKnownQuirks() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final message = details.exception.toString();
    if (message.contains(
      'Tried to read the state of an uninitialized provider',
    )) {
      return;
    }
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
}

/// url_launcher's platform side: records every URL the app asks to open and
/// answers with whatever [launchSucceeds] says.
///
/// The fund confirm button's whole happy path ends in `launchUrl`, and a
/// `false` answer is what makes it throw `paiementCantLaunchURL` — so both
/// answers are worth being able to choose per test.
class FakeUrlLauncher extends UrlLauncherPlatform {
  FakeUrlLauncher({this.launchSucceeds = true});

  /// What a launch resolves to. `false` is the "no browser available" answer
  /// the fund button turns into an exception.
  final bool launchSucceeds;

  final List<String> launched = [];

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
    return launchSucceeds;
  }
}

/// Installs [fake] as url_launcher's platform for the current test, and puts
/// the method-channel implementation back afterwards — a leaked fake would
/// silently absorb the launch of any other test's url in the same isolate.
void stubUrlLauncher(FakeUrlLauncher fake) {
  final previous = UrlLauncherPlatform.instance;
  UrlLauncherPlatform.instance = fake;
  addTearDown(() => UrlLauncherPlatform.instance = previous);
}
