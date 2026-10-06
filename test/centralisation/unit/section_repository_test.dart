import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:titan/centralisation/repositories/section_repository.dart';

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

  group('SectionRepository.getSectionList', () {
    test('parses the links.json payload into sections', () async {
      final payload = {
        'Clubs': [
          {
            'name': 'Flappy',
            'description': 'Jeu',
            'icon': 'bird.png',
            'url': 'https://flappy.example.com',
          },
        ],
        'Services': [
          {
            'name': 'Print',
            'description': 'Impression',
            'icon': 'print.png',
            'url': 'https://print.example.com',
          },
        ],
      };
      final client = MockClient(
        (request) async => http.Response(jsonEncode(payload), 200),
      );

      final sections = await http.runWithClient(
        () => SectionRepository().getSectionList(),
        () => client,
      );

      expect(sections, hasLength(2));
      final names = sections.map((s) => s.name).toList();
      expect(names, containsAll(['Clubs', 'Services']));
      final clubs = sections.firstWhere((s) => s.name == 'Clubs');
      expect(clubs.moduleList.single.name, 'Flappy');
      expect(clubs.expanded, true);
    });

    test('returns an empty list when decoding fails', () async {
      final client = MockClient(
        (request) async => http.Response('not json', 200),
      );

      final sections = await http.runWithClient(
        () => SectionRepository().getSectionList(),
        () => client,
      );

      expect(sections, isEmpty);
    });

    test('returns an empty list on http error status', () async {
      final client = MockClient((request) async => http.Response('boom', 500));

      final sections = await http.runWithClient(
        () => SectionRepository().getSectionList(),
        () => client,
      );

      expect(sections, isEmpty);
    });
  });
}
