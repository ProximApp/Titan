import 'dart:convert';
import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/raffle/providers/tombola_logo_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

/// `TombolaLogoNotifier`'s two public mutations — neither is called by any
/// raffle page test, so all 14 lines of the provider were dark: `getLogo`
/// (fetch → asset-vs-memory → cache + state) and `updateLogo` (POST the new
/// bytes → cache + state).
void main() {
  late MockOpenapi repo;
  late ProviderContainer container;
  late TombolaLogoProvider notifier;

  final Uint8List png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  setUp(() {
    repo = MockOpenapi();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    notifier = container.read(tombolaLogoProvider.notifier);
  });

  test('getLogo falls back to the app asset on an empty response', () async {
    when(
      () =>
          repo.tombolaRafflesRaffleIdLogoGet(raffleId: any(named: 'raffleId')),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "no logo"}', 404),
        [],
        error: 'no logo',
      ),
    );

    final logo = await notifier.getLogo('r-1');

    expect(logo.image, isA<AssetImage>());
    expect(notifier.state.value, logo);
  });

  test('getLogo keeps real bytes in memory and caches them', () async {
    when(
      () =>
          repo.tombolaRafflesRaffleIdLogoGet(raffleId: any(named: 'raffleId')),
    ).thenAnswer(
      (_) async =>
          chopper.Response<List<int>>(http.Response.bytes(png, 200), png),
    );

    final logo = await notifier.getLogo('r-2');

    expect(logo.image, isA<MemoryImage>());
    expect(notifier.state.value, logo);
  });

  test('updateLogo posts the bytes and stores the new image', () async {
    when(
      () => repo.tombolaRafflesRaffleIdLogoPost(
        raffleId: any(named: 'raffleId'),
        image: any(named: 'image'),
      ),
    ).thenAnswer((_) async => repo.ok(AppTypesStandardResponsesResult.empty()));

    final logo = await notifier.updateLogo('r-3', png);

    expect(logo.image, isA<MemoryImage>());
    expect(notifier.state.value, logo);
    verify(
      () => repo.tombolaRafflesRaffleIdLogoPost(
        raffleId: 'r-3',
        image: any(named: 'image'),
      ),
    ).called(1);
  });
}
