import 'dart:io';
import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart' show verify, verifyNever;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:titan/admin/providers/association_logo_provider.dart';
import 'package:titan/admin/providers/associations_logo_map_provider.dart';
import 'package:titan/tools/image_compression.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

/// `AssociationLogoNotifier` is the only admin path that touches the phone's
/// picker and the byte-level logo upload, so it is driven here through a fake
/// [ImagePickerPlatform] (both dependencies are declared in pubspec) instead
/// of a channel mock: the notifier builds its own `ImagePicker`, so the
/// platform singleton is the only seam.
///
/// Every branch of `setLogo` is a distinct toast in the edit form: uploaded,
/// too heavy to compress, failed upload, and "the user backed out".
class _FakePicker extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  _FakePicker(this.bytes);

  /// What the next pick returns, or null for a cancelled picker.
  Uint8List? bytes;

  final List<ImageSource> sources = [];

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    sources.add(source);
    final picked = bytes;
    if (picked == null) return null;
    final file = File(
      '${Directory.systemTemp.path}/admin_logo_pick_${sources.length}.png',
    )..writeAsBytesSync(picked);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    return XFile(file.path);
  }
}

chopper.Response<List<int>> _file(Uint8List bytes) =>
    chopper.Response<List<int>>(
      http.Response.bytes(bytes, 200),
      bytes.toList(),
    );

void main() {
  late MockOpenapi repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockOpenapi();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  AssociationLogoNotifier notifier() =>
      container.read(associationLogoProvider.notifier);

  group('getAssociationLogo', () {
    test('falls back to the placeholder when the server has no file', () async {
      when(
        () => repo.associationsAssociationIdLogoGet(
          associationId: any(named: 'associationId'),
        ),
      ).thenAnswer((_) async => _file(Uint8List(0)));

      final image = await notifier().getAssociationLogo('a-1');

      // An empty body is not an image: the placeholder asset is served instead
      // of handing zero bytes to Image.memory.
      expect(image, isA<Image>());
      expect(container.read(associationLogoProvider), isA<AsyncData<Image>>());
      final cached = container.read(associationLogoMapProvider)['a-1'];
      expect(cached!.value, hasLength(1));
    });

    test('decodes the bytes the server returns', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      when(
        () => repo.associationsAssociationIdLogoGet(
          associationId: any(named: 'associationId'),
        ),
      ).thenAnswer((_) async => _file(bytes));

      await notifier().getAssociationLogo('a-2');

      expect(container.read(associationLogoProvider), isA<AsyncData<Image>>());
      expect(container.read(associationLogoMapProvider)['a-2'], isNotNull);
      verify(() => repo.associationsAssociationIdLogoGet(associationId: 'a-2'))
          .called(1);
    });
  });

  group('setLogo', () {
    late _FakePicker picker;
    late Uint8List imageBytes;

    setUp(() {
      imageBytes = Uint8List.fromList(List<int>.generate(64, (i) => i));
      picker = _FakePicker(imageBytes);
      ImagePickerPlatform.instance = picker;
    });

    test(
      'a cancelled pick restores the previous state and answers null',
      () async {
        picker.bytes = null;
        final before = container.read(associationLogoProvider);

        final result = await notifier().setLogo(ImageSource.gallery, 'a-1');

        expect(result, isNull);
        expect(container.read(associationLogoProvider), before);
        expect(picker.sources, [ImageSource.gallery]);
        verifyNever(
          () => repo.associationsAssociationIdLogoPost(
            associationId: any(named: 'associationId'),
            image: any(named: 'image'),
          ),
        );
      },
    );

    test(
      'an uploaded logo is posted, cached and reported as success',
      () async {
        when(
          () => repo.associationsAssociationIdLogoPost(
            associationId: any(named: 'associationId'),
            image: any(named: 'image'),
          ),
        ).thenAnswer((_) async => repo.okVoid());

        final result = await notifier().setLogo(ImageSource.camera, 'a-3');

        expect(result, isTrue);
        expect(picker.sources, [ImageSource.camera]);
        verify(
          () => repo.associationsAssociationIdLogoPost(
            associationId: 'a-3',
            image: any(named: 'image'),
          ),
        ).called(1);
        expect(
          container.read(associationLogoProvider),
          isA<AsyncData<Image>>(),
        );
        expect(container.read(associationLogoMapProvider)['a-3'], isNotNull);
      },
    );

    test('bytes that cannot be compressed are refused before upload', () async {
      // Over the 1 MiB multipart limit and not a decodable image, which is the
      // one input the compressor answers null for.
      final oversized = Uint8List(maxUploadedImageSize + 16);
      for (var i = 0; i < oversized.length; i++) {
        oversized[i] = (i * 37 + 11) % 251;
      }
      picker.bytes = oversized;

      final result = await notifier().setLogo(ImageSource.gallery, 'a-4');

      expect(result, isFalse);
      verifyNever(
        () => repo.associationsAssociationIdLogoPost(
          associationId: any(named: 'associationId'),
          image: any(named: 'image'),
        ),
      );
      expect(
        container.read(associationLogoProvider),
        isNot(isA<AsyncData<Image>>()),
      );
    });

    test('a failed upload answers false and restores the state', () async {
      when(
        () => repo.associationsAssociationIdLogoPost(
          associationId: any(named: 'associationId'),
          image: any(named: 'image'),
        ),
      ).thenThrow(Exception('upload refused'));

      final result = await notifier().setLogo(ImageSource.gallery, 'a-5');

      expect(result, isFalse);
      expect(container.read(associationLogoProvider), isNot(isA<AsyncError>()));
    });
  });
}
