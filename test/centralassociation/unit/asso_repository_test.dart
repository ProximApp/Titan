import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:titan/centralassociation/repositories/asso_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // The static Logger creates a FileLoggerOutput, which writes to
    // <documents>/myecl.log. Point path_provider at a real temp directory.
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

  group('AssoRepository.getAssoList', () {
    test('parses the assos_links.json payload', () async {
      final payload = [
        {
          'name': 'BDE',
          'description': 'Bureau des étudiants',
          'icon': 'bde.png',
          'links': [
            {'name': 'Site', 'url': 'https://bde.example.com', 'icon': 'web'},
          ],
        },
        {
          'name': 'BDF',
          'description': 'Bureau des sports',
          'icon': 'bdf.png',
          'links': [],
        },
      ];
      final client = MockClient(
        (request) async => http.Response(jsonEncode(payload), 200),
      );

      final assos = await http.runWithClient(
        () => AssoRepository().getAssoList(),
        () => client,
      );

      expect(assos, hasLength(2));
      expect(assos.first.name, 'BDE');
      expect(assos.first.linkList.single.url, 'https://bde.example.com');
      expect(assos.last.name, 'BDF');
    });

    test('returns an empty list when decoding fails', () async {
      final client = MockClient(
        (request) async => http.Response('not json', 200),
      );

      final assos = await http.runWithClient(
        () => AssoRepository().getAssoList(),
        () => client,
      );

      expect(assos, isEmpty);
    });

    test('returns an empty list on http error status', () async {
      final client = MockClient((request) async => http.Response('boom', 404));

      final assos = await http.runWithClient(
        () => AssoRepository().getAssoList(),
        () => client,
      );

      expect(assos, isEmpty);
    });
  });
}
