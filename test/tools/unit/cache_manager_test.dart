import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/tools/cache/cache_manager.dart';

void main() {
  late CacheManager cache;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cache = CacheManager();
  });

  test('string cache round-trips, defaults to "" and deletes', () async {
    expect(await cache.readCache('missing'), '');

    await cache.writeCache('token', 'abc');
    expect(await cache.readCache('token'), 'abc');

    await cache.deleteCache('token');
    expect(await cache.readCache('token'), '');
  });

  test('image cache round-trips bytes and deletes', () async {
    // Nothing stored reads as the empty byte list, not a crash.
    expect(await cache.readImage('picture'), isEmpty);

    final bytes = Uint8List.fromList([1, 2, 3, 255]);
    await cache.writeImage('picture', bytes);
    expect(await cache.readImage('picture'), bytes);

    await cache.deleteImage('picture');
    expect(await cache.readImage('picture'), isEmpty);
  });
}
