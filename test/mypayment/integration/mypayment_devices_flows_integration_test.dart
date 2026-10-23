import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/key_service_provider.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../mypayment_fixtures.dart';
import '../../shared/app_scaffold.dart';

/// The devices page's two action chains, which the page-shell test never
/// reaches: add-device (device_info → Ed25519 keypair → register → persist →
/// activation dialog) and revoke (confirm dialog → revoke → toast → clear the
/// key iff the revoked device IS this device).
///
/// The three `getDeviceName` branches each get their own test: android is
/// the test binding's default and answers through a mocked
/// device_info_plus method channel, iOS comes from
/// `debugDefaultTargetPlatformOverride` + a utsname map, and the else arm
/// is the localized "Unknown device" (linux override, no channel).
const _deviceInfoChannel = MethodChannel(
  'dev.fluttercommunity.plus/device_info',
);

void stubTos(IntegrationScaffold scaffold, {required bool accepted}) {
  when(() => scaffold.repository.mypaymentUsersMeTosGet()).thenAnswer(
    (_) async => chopperResponse(
      TOSSignatureResponse.empty().copyWith(
        acceptedTosVersion: accepted ? 1 : 0,
        latestTosVersion: 1,
      ),
    ),
  );
}

/// The list endpoint answers [initial] on the mount load and [after] on any
/// later load — the register flow reloads the list once it saved the key.
void stubDevices(
  IntegrationScaffold scaffold, {
  required List<WalletDevice> initial,
  List<WalletDevice>? after,
}) {
  var calls = 0;
  when(() => scaffold.repository.mypaymentUsersMeWalletDevicesGet()).thenAnswer(
    (_) async =>
        chopperListResponse(calls++ == 0 ? initial : (after ?? initial)),
  );
}

void stubRegister(IntegrationScaffold scaffold, WalletDevice created) {
  when(
    () => scaffold.repository.mypaymentUsersMeWalletDevicesPost(
      body: any(named: 'body'),
    ),
  ).thenAnswer((_) async => chopperResponse(created));
}

/// The models require every non-nullable field (`late final String`,
/// `final int`, …) with no `?? default` in `fromMap`, so a partial map is a
/// `Null is not a subtype of String` — the values are the usual emulator
/// fixture; only `model` / `utsname.machine` are read by the page.
const _androidInfo = <String, Object?>{
  'board': 'goldfish_x86_64',
  'bootloader': 'unknown',
  'brand': 'Google',
  'device': 'sdk_gphone64_x86_64',
  'display': 'sdk_gphone64_x86_64-userdebug',
  'fingerprint':
      'google/sdk_gphone64_x86_64/emu64x:14/TEST:userdebug/test-keys',
  'hardware': 'ranchu',
  'host': 'abfarm-release',
  'id': 'TEST123',
  'manufacturer': 'Google',
  'model': 'Pixel 8',
  'product': 'sdk_gphone64_x86_64',
  'name': 'sdk_gphone64_x86_64',
  'tags': 'test-keys',
  'type': 'eng',
  'isPhysicalDevice': false,
  'freeDiskSize': 6442450944,
  'totalDiskSize': 8589934592,
  'isLowRamDevice': false,
  'physicalRamSize': 4294967296,
  'availableRamSize': 2147483648,
  'version': <String, Object?>{
    'codename': 'UpsideDownCake',
    'incremental': '11223344',
    'release': '14',
    'sdkInt': 34,
  },
};

const _iosInfo = <String, Object?>{
  'name': 'iPhone',
  'systemName': 'iOS',
  'systemVersion': '17.4',
  'model': 'iPhone',
  'modelName': 'iPhone 15',
  'localizedModel': 'iPhone',
  'isPhysicalDevice': false,
  'physicalRamSize': 4294967296,
  'availableRamSize': 2147483648,
  'isiOSAppOnMac': false,
  'isiOSAppOnVision': false,
  'freeDiskSize': 6442450944,
  'totalDiskSize': 8589934592,
  'utsname': <String, Object?>{
    'sysname': 'Darwin',
    'nodename': 'iPhone',
    'release': '23.4.0',
    'version': 'Darwin Kernel Version 23.4.0',
    'machine': 'iPhone15,2',
  },
};

Future<void> mockDeviceInfo(
  WidgetTester tester, {
  required Map<String, Object?> info,
}) async {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _deviceInfoChannel,
    (call) async => call.method == 'getDeviceInfo' ? info : null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _deviceInfoChannel,
      null,
    ),
  );
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<ProviderContainer> pumpDevices(
    WidgetTester tester, {
    String? deviceKeyId,
  }) async {
    final container = scaffold.makeContainer(deviceKeyId: deviceKeyId);
    addTearDown(container.dispose);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/mypayment/devices',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);
    return container;
  }

  testWidgets('add this device generates a key, registers it and confirms', (
    tester,
  ) async {
    stubTos(scaffold, accepted: true);
    stubDevices(
      scaffold,
      initial: <WalletDevice>[],
      after: [device('dev-9', 'Pixel 8')],
    );
    stubRegister(scaffold, device('dev-9', 'Pixel 8'));
    await mockDeviceInfo(tester, info: _androidInfo);

    final container = await pumpDevices(tester);

    expect(find.text('Add this device'), findsOneWidget);

    await tester.tap(find.text('Add this device'));
    await settle(tester, frames: 30);

    // The android branch named the device from the mocked Build.MODEL, and
    // the base64 key that went with it is a real Ed25519 public key.
    final body =
        verify(
              () => scaffold.repository.mypaymentUsersMeWalletDevicesPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as WalletDeviceCreation;
    expect(body.name, 'Pixel 8');
    expect(body.ed25519PublicKey, isNotEmpty);

    // saveKeyId ran with the id the POST answered: the fake's public field
    // is the flow's own record of what it persisted.
    expect(
      (container.read(keyServiceProvider) as FakeKeyService).keyId,
      'dev-9',
    );

    expect(find.text('Device activation request'), findsOneWidget);
    // displayAddDevice is false (and the refreshed list holds the active
    // device) — the add row is gone either way.
    expect(find.text('Add this device'), findsNothing);

    await tester.tap(find.text('Ok'));
    await settle(tester, frames: 10);
    expect(find.text('Device activation request'), findsNothing);
  });

  testWidgets('add this device without an accepted ToS toasts and stops', (
    tester,
  ) async {
    stubTos(scaffold, accepted: false);
    stubDevices(scaffold, initial: <WalletDevice>[]);

    final container = await pumpDevices(tester);

    await tester.tap(find.text('Add this device'));
    await settle(tester, frames: 20);

    expect(find.text('Please accept the Terms of Service.'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.mypaymentUsersMeWalletDevicesPost(
        body: any(named: 'body'),
      ),
    );
    // Stopped before generateKeyPair: nothing was persisted.
    expect(
      (container.read(keyServiceProvider) as FakeKeyService).keyId,
      isNull,
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('on iOS the device is named from the utsname machine', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    stubTos(scaffold, accepted: true);
    stubDevices(
      scaffold,
      initial: <WalletDevice>[],
      after: [device('dev-9', 'iPhone15,2')],
    );
    stubRegister(scaffold, device('dev-9', 'iPhone15,2'));
    await mockDeviceInfo(tester, info: _iosInfo);

    await pumpDevices(tester);

    await tester.tap(find.text('Add this device'));
    await settle(tester, frames: 30);

    final body =
        verify(
              () => scaffold.repository.mypaymentUsersMeWalletDevicesPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as WalletDeviceCreation;
    expect(body.name, 'iPhone15,2');
    expect(find.text('Device activation request'), findsOneWidget);

    // The binding's invariant check runs at the end of the test BODY, before
    // tearDown callbacks — leaving the override set fails it.
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('on any other platform the name falls back to the unknown one', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    stubTos(scaffold, accepted: true);
    stubDevices(
      scaffold,
      initial: <WalletDevice>[],
      after: [device('dev-9', 'Unknown device')],
    );
    stubRegister(scaffold, device('dev-9', 'Unknown device'));

    await pumpDevices(tester);

    await tester.tap(find.text('Add this device'));
    await settle(tester, frames: 30);

    final body =
        verify(
              () => scaffold.repository.mypaymentUsersMeWalletDevicesPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as WalletDeviceCreation;
    // No platform channel on this arm: the localized fallback name.
    expect(body.name, 'Unknown device');
    expect(find.text('Device activation request'), findsOneWidget);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('revoking THIS device confirms, revokes and clears the key', (
    tester,
  ) async {
    stubTos(scaffold, accepted: true);
    // Deliberately unsorted on the wire: the current device must come out
    // first anyway.
    stubDevices(
      scaffold,
      initial: [device('dev-2', 'Pixel'), device('dev-1', 'MacBook')],
    );
    when(
      () => scaffold.repository
          .mypaymentUsersMeWalletDevicesWalletDeviceIdRevokePost(
            walletDeviceId: any(named: 'walletDeviceId'),
          ),
      // The endpoint is a void one: the notifier only reads isSuccessful
      // and replaces the row with its own local revoked copy, so the stub
      // must not hand a typed body to a `void` parameter.
    ).thenAnswer((_) async => chopperResponseVoid());

    final container = await pumpDevices(tester, deviceKeyId: 'dev-1');

    // The current device sorts to the top, wears the marker, and — being
    // active — suppresses the add-device row.
    expect(find.text('(this device)'), findsOneWidget);
    expect(find.text('Add this device'), findsNothing);
    expect(
      tester.getTopLeft(find.text('MacBook')).dy,
      lessThan(tester.getTopLeft(find.text('Pixel')).dy),
    );

    await tester.tap(
      find
          .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash)
          .first,
    );
    await settle(tester, frames: 20);
    expect(find.text('Revoke device?'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 30);

    verify(
      () => scaffold.repository
          .mypaymentUsersMeWalletDevicesWalletDeviceIdRevokePost(
            walletDeviceId: 'dev-1',
          ),
    ).called(1);
    expect(find.text('Device revoked'), findsOneWidget);
    // savedId == device.id → keyService.clear() ran on the fake.
    expect(
      (container.read(keyServiceProvider) as FakeKeyService).keyId,
      isNull,
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('revoking ANOTHER device keeps this device\u2019s key', (
    tester,
  ) async {
    stubTos(scaffold, accepted: true);
    stubDevices(
      scaffold,
      initial: [device('dev-1', 'MacBook'), device('dev-2', 'Pixel')],
    );
    when(
      () => scaffold.repository
          .mypaymentUsersMeWalletDevicesWalletDeviceIdRevokePost(
            walletDeviceId: any(named: 'walletDeviceId'),
          ),
    ).thenAnswer((_) async => chopperResponseVoid());

    final container = await pumpDevices(tester, deviceKeyId: 'dev-1');

    // MacBook (this device) renders first, so the second trash is Pixel's.
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash)
          .at(1),
    );
    await settle(tester, frames: 20);
    expect(find.text('Revoke device?'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 30);

    verify(
      () => scaffold.repository
          .mypaymentUsersMeWalletDevicesWalletDeviceIdRevokePost(
            walletDeviceId: 'dev-2',
          ),
    ).called(1);
    expect(find.text('Device revoked'), findsOneWidget);
    // savedId('dev-1') != device.id('dev-2') → no clear().
    expect(
      (container.read(keyServiceProvider) as FakeKeyService).keyId,
      'dev-1',
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused revoke toasts the error and keeps the key', (
    tester,
  ) async {
    stubTos(scaffold, accepted: true);
    stubDevices(scaffold, initial: [device('dev-1', 'MacBook')]);
    when(
      () => scaffold.repository
          .mypaymentUsersMeWalletDevicesWalletDeviceIdRevokePost(
            walletDeviceId: any(named: 'walletDeviceId'),
          ),
    ).thenAnswer((_) async => scaffold.repository.fail(400));

    final container = await pumpDevices(tester, deviceKeyId: 'dev-1');

    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash),
    );
    await settle(tester, frames: 20);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 30);

    expect(find.text('Error while revoking device'), findsOneWidget);
    // The failure arm never reaches the clear().
    expect(
      (container.read(keyServiceProvider) as FakeKeyService).keyId,
      'dev-1',
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('pulling the page down reloads the device list', (tester) async {
    stubTos(scaffold, accepted: false);
    stubDevices(scaffold, initial: <WalletDevice>[]);

    await pumpDevices(tester);

    // Refresher takes the Cupertino path under the test binding (the host
    // is neither Android nor web): the canonical pull sequence is a long
    // drag to stretch the control, then a fling release.
    await tester.drag(find.byType(Refresher), const Offset(0, 1500));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    // mocktail's verify consumes matched calls, so this single verify
    // counts BOTH the mount load and the refresh load.
    verify(() => scaffold.repository.mypaymentUsersMeWalletDevicesGet())
        .called(2);
  });
}
