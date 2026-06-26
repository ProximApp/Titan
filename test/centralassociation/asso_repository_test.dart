import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:titan/centralassociation/repositories/asso_repository.dart';

/// A client whose requests never complete, used to reproduce an unreachable
/// host hanging forever.
class _NeverCompletingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Completer<http.StreamedResponse>().future;
}

/// AssoRepository logs through a static Logger whose async init resolves the
/// log file via path_provider. In a plain test there is no plugin, so this
/// fake lets that init succeed instead of throwing an unhandled async error.
class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getApplicationSupportPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });

  group('AssoRepository.getAssoList', () {
    test('parses the asso list on a 200 response', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'name': 'A',
              'description': 'desc',
              'icon': 'a.svg',
              'links': [
                {'name': 'L', 'url': 'https://x.fr', 'icon': 'l.svg'},
              ],
            },
          ]),
          200,
        ),
      );
      final repository = AssoRepository(client: client);

      final result = await repository.getAssoList();

      expect(result, hasLength(1));
      expect(result.first.name, 'A');
      expect(result.first.linkList, hasLength(1));
    });

    test('returns an empty list on a non-200 response', () async {
      final client = MockClient((_) async => http.Response('nope', 500));
      final repository = AssoRepository(client: client);

      final result = await repository.getAssoList();

      expect(result, isEmpty);
    });

    test('returns an empty list on a malformed body', () async {
      final client = MockClient((_) async => http.Response('not json', 200));
      final repository = AssoRepository(client: client);

      final result = await repository.getAssoList();

      expect(result, isEmpty);
    });

    test(
      'returns an empty list when the request times out instead of hanging '
      'forever',
      () async {
        final repository = AssoRepository(
          client: _NeverCompletingClient(),
          timeout: const Duration(milliseconds: 100),
        );

        final result = await repository.getAssoList();

        expect(result, isEmpty);
      },
    );

    test('returns an empty list when the request throws', () async {
      final client = MockClient((_) async => throw Exception('boom'));
      final repository = AssoRepository(client: client);

      final result = await repository.getAssoList();

      expect(result, isEmpty);
    });
  });
}
