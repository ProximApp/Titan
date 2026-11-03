import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/advert/notification_service.dart';
import 'package:titan/advert/providers/advert_list_provider.dart';
import 'package:titan/advert/providers/advert_poster_provider.dart';
import 'package:titan/advert/providers/advert_posters_provider.dart';
import 'package:titan/advert/router.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/mock_openapi.dart';

/// AdvertPosterNotifier's two uncovered paths: getAdvertPoster's empty-bytes
/// fallback (placeholder asset) vs MemoryImage, and updateAdvertPoster's
/// loading → POST → data sequence through the posters map.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOpenapi repository;

  setUp(() {
    repository = MockOpenapi();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    // Initialises the notifier (it wires the posters map on first read).
    container.read(advertPosterProvider);
    container.read(advertPostersProvider);
    return container;
  }

  test(
    'getAdvertPoster falls back to the placeholder asset when empty',
    () async {
      // fileBytes = raw bodyBytes when successful → an empty body is the
      // "no bytes" case that must fall back to the placeholder asset.
      when(() => repository.advertAdvertsAdvertIdPictureGet(advertId: 'a1'))
          .thenAnswer(
            (_) async =>
                chopper.Response<List<int>>(http.Response('', 200), []),
          );

      final container = makeContainer();
      final image = await container
          .read(advertPosterProvider.notifier)
          .getAdvertPoster('a1');

      expect(image.image, isA<AssetImage>());
      expect(container.read(advertPostersProvider)['a1'], isNotNull);
    },
  );

  test('getAdvertPoster wraps real bytes in a memory image', () async {
    when(
      () => repository.advertAdvertsAdvertIdPictureGet(advertId: 'a2'),
    ).thenAnswer(
      (_) async =>
          chopper.Response<List<int>>(http.Response('x', 200), [1, 2, 3, 4]),
    );

    final container = makeContainer();
    final image = await container
        .read(advertPosterProvider.notifier)
        .getAdvertPoster('a2');

    expect(image.image, isA<MemoryImage>());
  });

  test(
    'updateAdvertPoster POSTs the bytes and flips the map to data',
    () async {
      when(
        () => repository.advertAdvertsAdvertIdPicturePost(
          advertId: any(named: 'advertId'),
          image: any(named: 'image'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());

      final container = makeContainer();
      final future = container
          .read(advertPosterProvider.notifier)
          .updateAdvertPoster('a3', Uint8List.fromList([7, 7, 7]));
      // Mid-flight the map entry is a (loading) state.
      expect(container.read(advertPostersProvider)['a3'], isNotNull);

      final image = await future;
      expect(image.image, isA<MemoryImage>());
      verify(
        () => repository.advertAdvertsAdvertIdPicturePost(
          advertId: 'a3',
          image: any(named: 'image'),
        ),
      ).called(1);
      final entry = container.read(advertPostersProvider)['a3'];
      expect(entry, isA<AsyncValue<List<Image>>>());
    },
  );

  group('advert notification wiring', () {
    test('the advertProviders map roots the module at its list provider', () {
      expect(advertProviders.keys, ['advert']);
      final entry = advertProviders['advert']!;
      expect(entry.item1, AdvertRouter.root);
      expect(entry.item2, [advertListProvider]);
    });
  });
}
