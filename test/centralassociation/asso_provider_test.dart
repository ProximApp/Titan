import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:titan/centralassociation/class/asso.dart';
import 'package:titan/centralassociation/providers/centralassociation_asso_provider.dart';
import 'package:titan/centralassociation/repositories/asso_repository.dart';

class _ThrowingAssoRepository extends AssoRepository {
  @override
  Future<List<Asso>> getAssoList() async => throw Exception('boom');
}

void main() {
  group('AssoNotifier', () {
    test('build resolves to data instead of staying in loading', () async {
      final repository = AssoRepository(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode([
              {
                'name': 'A',
                'description': 'desc',
                'icon': 'a.svg',
                'links': [],
              },
            ]),
            200,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [assoRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(assoProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(sub.read(), isA<AsyncData<List<Asso>>>());
    });

    test('build surfaces an error instead of staying in loading', () async {
      final container = ProviderContainer(
        overrides: [
          assoRepositoryProvider.overrideWithValue(_ThrowingAssoRepository()),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(assoProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(sub.read(), isA<AsyncError>());
    });
  });
}
