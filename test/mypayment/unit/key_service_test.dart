import 'dart:convert';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/mypayment/tools/key_service.dart';

/// `KeyService` sits behind `flutter_secure_storage`'s method channel, which
/// has no platform implementation in tests — so the channel is faked with an
/// in-memory map and every public method is driven for real: pair generation,
/// persistence + read-back, the legacy pre-`migrated` branch of `getKeyPair`
/// (it re-encodes the stored strings once and stamps the flag), the key-id
/// round-trip, the wipe, and a genuine Ed25519 sign/verify round-trip.
const secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> stored;

  setUp(() {
    stored = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          switch (call.method) {
            case 'read':
              return stored[args['key']];
            case 'write':
              stored[args['key']] = args['value'] as String;
              return null;
            case 'delete':
              stored.remove(args['key']);
              return null;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorageChannel, null),
    );
  });

  test(
    'saveKeyPair persists base64 key material getKeyPair reads back',
    () async {
      final service = KeyService();
      final pair = await service.generateKeyPair();
      await service.saveKeyPair(pair);

      expect(stored.keys, containsAll(['privateKey', 'publicKey', 'migrated']));
      expect(stored['migrated'], 'true');
      expect(
        base64.decode(stored['privateKey']!),
        await pair.extractPrivateKeyBytes(),
      );

      final loaded = await service.getKeyPair();
      expect(loaded, isNotNull);
      final originalPublic = await pair.extractPublicKey();
      final loadedPublic = await loaded!.extractPublicKey();
      expect(loadedPublic.bytes, originalPublic.bytes);
    },
  );

  test('getKeyPair returns null when no key material is stored', () async {
    expect(await KeyService().getKeyPair(), isNull);
  });

  test('getKeyPair migrates a legacy entry once and stamps migrated', () async {
    stored['privateKey'] = 'legacy-private';
    stored['publicKey'] = 'legacy-public';

    final loaded = await KeyService().getKeyPair();

    expect(loaded, isNotNull);
    expect(stored['migrated'], 'true');
    // The legacy branch re-encodes the stored strings through base64 of their
    // code units — the one-way upgrade this branch exists for.
    expect(stored['privateKey'], base64.encode('legacy-private'.codeUnits));
    expect(stored['publicKey'], base64.encode('legacy-public'.codeUnits));
    expect(await loaded!.extractPublicKey(), isNotNull);
  });

  test('saveKeyId and getKeyId round-trip', () async {
    final service = KeyService();
    expect(await service.getKeyId(), isNull);

    await service.saveKeyId('kid-1');

    expect(await service.getKeyId(), 'kid-1');
  });

  test('clear deletes the key material and the key id', () async {
    stored['privateKey'] = 'a';
    stored['publicKey'] = 'b';
    stored['keyId'] = 'c';

    expect(await KeyService().clear(), isTrue);

    expect(stored.containsKey('privateKey'), isFalse);
    expect(stored.containsKey('publicKey'), isFalse);
    expect(stored.containsKey('keyId'), isFalse);
  });

  test(
    'signMessage produces a signature the stored public key verifies',
    () async {
      final service = KeyService();
      final pair = await service.generateKeyPair();
      final message = utf8.encode('pay 42 EUR to the amap');

      final signature = await service.signMessage(pair, message);
      // The signature carries the signer's public key, and the verify API
      // takes only the message + signature.
      expect(signature.publicKey, isNotNull);

      final verified = await Ed25519().verify(message, signature: signature);
      expect(verified, isTrue);
    },
  );
}
