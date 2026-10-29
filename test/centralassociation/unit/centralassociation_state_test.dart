import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:titan/centralassociation/class/asso.dart';
import 'package:titan/centralassociation/providers/centralassociation_asso_provider.dart';
import 'package:titan/centralassociation/repositories/asso_repository.dart';
import 'package:titan/centralassociation/tools/constants.dart';
import 'package:titan/centralassociation/tools/functions.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Serves canned [canLaunchUrl] / [launchUrl] answers: `openLink` goes
/// straight through `UrlLauncherPlatform.instance`, so this is the seam.
class _FakeUrlLauncher extends UrlLauncherPlatform {
  bool canLaunchResult = true;
  final List<String> launched = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // AssoRepository holds a static Logger whose FileLoggerOutput resolves
    // <documents> through path_provider (same shim as asso_repository_test).
    await Directory.systemTemp.createTemp('titan_test_documents').then((dir) {
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            switch (call.method) {
              case 'getApplicationDocumentsDirectory':
              case 'getTemporaryDirectory':
                return dir.path;
            }
            return null;
          });
    });
  });

  group('Asso', () {
    test('the default constructor stores its fields', () {
      final asso = Asso(name: 'BDE', description: 'Bureau', icon: 'bde.png');

      expect(asso.name, 'BDE');
      expect(asso.description, 'Bureau');
      expect(asso.icon, 'bde.png');
    });

    test('Asso.empty() starts blank with no links', () {
      final asso = Asso.empty();

      expect(asso.name, '');
      expect(asso.description, '');
      expect(asso.linkList, isEmpty);
      // The empty factory never assigns the late `icon`, and toString reads
      // it — pinned as-built so a fix flips this expectation loudly. The
      // runtime error class is not nameable from user code (it surfaces as
      // a `LateError`), so it is matched on its identifying message.
      expect(
        asso.toString,
        throwsA(
          predicate(
            (e) => e.toString().startsWith('LateInitializationError'),
            'throws LateInitializationError',
          ),
        ),
      );
    });

    test('fromJson maps the payload into the model', () {
      final asso = Asso.fromJson({
        'name': 'BDF',
        'description': 'Bureau des sports',
        'icon': 'bdf.png',
        'links': [
          {'name': 'Site', 'url': 'https://bdf.example.com', 'icon': 'web'},
        ],
      });

      expect(asso.name, 'BDF');
      expect(asso.linkList.single.url, 'https://bdf.example.com');
      expect(asso.toString(), contains('BDF'));
    });
  });

  group('openLink', () {
    late UrlLauncherPlatform original;
    late _FakeUrlLauncher fake;

    setUp(() {
      original = UrlLauncherPlatform.instance;
      fake = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = fake;
    });

    tearDown(() {
      UrlLauncherPlatform.instance = original;
    });

    test('launches externally when the platform can handle the url', () async {
      openLink('https://bde.example.com');
      await pumpEventQueue();

      expect(fake.launched, ['https://bde.example.com']);
    });

    test(
      'throws the unable-to-open message when the url cannot launch',
      () async {
        fake.canLaunchResult = false;
        Object? captured;
        runZonedGuarded(
          () => openLink('sms:+33123456789'),
          (error, _) => captured = error,
        );
        await pumpEventQueue();

        expect(
          captured,
          '${CentralassociationTextConstants.unableToOpen} sms:+33123456789',
        );
      },
    );
  });

  group('assoProvider', () {
    late ProviderContainer container;

    final payload = [
      {
        'name': 'BDE',
        'description': 'Bureau des étudiants',
        'icon': 'bde.png',
        'links': [
          {'name': 'Site', 'url': 'https://bde.example.com', 'icon': 'web'},
          {'name': 'Insta', 'url': 'https://instagram.com/bde', 'icon': 'ig'},
        ],
      },
    ];

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    Future<AsyncValue<List<Asso>>> pumpUntilData(http.Client client) async {
      late AsyncValue<List<Asso>> seen;
      await http.runWithClient(() async {
        container.listen(
          assoProvider,
          (_, next) => seen = next,
          fireImmediately: true,
        );
        for (var i = 0; i < 50 && !seen.hasValue; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      }, () => client);
      return seen;
    }

    test('initState loads the asso list and expands every link', () async {
      final client = MockClient(
        (request) async => http.Response(jsonEncode(payload), 200),
      );

      final seen = await pumpUntilData(client);

      expect(seen.hasValue, isTrue);
      final assos = seen.requireValue;
      expect(assos, hasLength(1));
      expect(assos.single.name, 'BDE');
      expect(assos.single.linkList, hasLength(2));

      final notifier = container.read(assoProvider.notifier);
      expect(notifier.allAssos, hasLength(1));
      expect(notifier.allLinks.map((l) => l.name), ['Site', 'Insta']);
    });

    test('a failing fetch resolves the state to an empty list', () async {
      final client = MockClient((request) async => http.Response('boom', 500));

      final seen = await pumpUntilData(client);

      expect(seen.hasValue, isTrue);
      expect(seen.requireValue, isEmpty);

      final notifier = container.read(assoProvider.notifier);
      expect(notifier.allAssos, isEmpty);
      expect(notifier.allLinks, isEmpty);

      // The 500 lands in the repository's else arm and is logged through
      // the static Logger before the state resolves.
      await pumpEventQueue();
      expect(
        AssoRepository.logger.getLogs().map((l) => l.message),
        contains(contains('500 boom')),
      );
    });
  });
}
