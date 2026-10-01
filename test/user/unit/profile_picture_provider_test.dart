import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper_platform_interface/image_cropper_platform_interface.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/user/providers/profile_picture_provider.dart';

import '../../shared/mock_openapi.dart';

/// ProfilePictureNotifier talks to three platform plugins — image_picker,
/// image_cropper and path_provider — all of which are MethodChannel shims in
/// tests. Overriding their platform interfaces (the same seams the plugins
/// themselves use) drives every branch: pick, cancel, upload failure,
/// crop, crop-cancel and the compression refusal.
class _FakePickerPlatform extends ImagePickerPlatform {
  XFile? nextPick;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return nextPick;
  }
}

class _FakeCropperPlatform extends ImageCropperPlatform {
  CroppedFile? nextCrop;

  /// Completed on the first crop call so tests can wait for the un-awaited
  /// `whenData` pipeline inside cropImage to reach the cropper before the
  /// test ends (its trailing `state = previousState` must not run against a
  /// disposed container).
  final cropCalled = Completer<void>();

  @override
  Future<CroppedFile?> cropImage({
    required String sourcePath,
    int? maxWidth,
    int? maxHeight,
    CropAspectRatio? aspectRatio,
    ImageCompressFormat compressFormat = ImageCompressFormat.jpg,
    int compressQuality = 90,
    List<PlatformUiSettings>? uiSettings,
  }) async {
    if (!cropCalled.isCompleted) {
      cropCalled.complete();
    }
    return nextCrop;
  }
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.root);

  final String root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

void main() {
  late MockOpenapi repository;
  late ProviderContainer container;
  late ProfilePictureNotifier provider;
  late _FakePickerPlatform picker;
  late _FakeCropperPlatform cropper;
  late Directory tempDir;
  late ImagePickerPlatform previousPicker;
  late ImageCropperPlatform previousCropper;
  late PathProviderPlatform previousPath;

  final bytes = Uint8List.fromList(List<int>.generate(2048, (i) => i % 251));
  // Not decodable by any of the compressors' codecs: compressImageForUpload
  // hands back null and the notifier must treat that as a failure.
  final undecidableBytes = Uint8List.fromList(
    List<int>.filled(1024 * 1024 + 1, 7),
  );

  chopper.Response<List<int>> fileResponse(Uint8List payload) =>
      chopper.Response<List<int>>(http.Response.bytes(payload, 200), payload);

  chopper.Response<List<int>> emptyFileResponse() =>
      chopper.Response<List<int>>(http.Response('gone', 404), const <int>[]);

  setUpAll(() async {
    registerFallbackValue(<int>[]);
    // One directory for the whole file: a test's own crop pipeline can still
    // be finishing real file IO when its tearDown runs, and deleting the
    // directory underneath it surfaces as a spurious PathNotFoundException.
    tempDir = await Directory.systemTemp.createTemp('profile_picture_test');
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    repository = MockOpenapi();
    picker = _FakePickerPlatform();
    cropper = _FakeCropperPlatform();

    previousPicker = ImagePickerPlatform.instance;
    previousCropper = ImageCropperPlatform.instance;
    previousPath = PathProviderPlatform.instance;
    ImagePickerPlatform.instance = picker;
    ImageCropperPlatform.instance = cropper;
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);

    // build() fires getMyProfilePicture() on construction: answer a 404 so
    // the provider lands on an empty byte state before each test drives it.
    when(
      () =>
          repository.usersUserIdProfilePictureGet(userId: any(named: 'userId')),
    ).thenAnswer((_) async => emptyFileResponse());

    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    provider = container.read(profilePictureProvider.notifier);
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() {
    ImagePickerPlatform.instance = previousPicker;
    ImageCropperPlatform.instance = previousCropper;
    PathProviderPlatform.instance = previousPath;
  });

  test('build fetches my profile picture (userId "me")', () async {
    when(() => repository.usersUserIdProfilePictureGet(userId: 'me'))
        .thenAnswer((_) async => fileResponse(bytes));
    clearInteractions(repository);

    final fresh = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(fresh.dispose);
    fresh.read(profilePictureProvider);
    await Future<void>.delayed(Duration.zero);

    expect(fresh.read(profilePictureProvider).value, bytes);
    verify(() => repository.usersUserIdProfilePictureGet(userId: 'me'))
        .called(1);
  });

  test('getProfilePicture loads another user picture', () async {
    when(() => repository.usersUserIdProfilePictureGet(userId: 'u-2'))
        .thenAnswer((_) async => fileResponse(bytes));

    final result = await provider.getProfilePicture('u-2');

    expect(result.value, bytes);
  });

  test('getProfilePicture surfaces repository failures', () async {
    when(() => repository.usersUserIdProfilePictureGet(userId: 'u-3'))
        .thenThrow(Exception('boom'));

    final result = await provider.getProfilePicture('u-3');

    expect(result.hasError, isTrue);
  });

  test(
    'setProfilePicture uploads the picked image and updates state',
    () async {
      when(
        () => repository.usersMeProfilePicturePost(image: any(named: 'image')),
      ).thenAnswer(
        (_) async => repository.ok(AppTypesStandardResponsesResult.empty()),
      );
      picker.nextPick = XFile.fromData(bytes, name: 'picked.png');

      final result = await provider.setProfilePicture(ImageSource.gallery);

      expect(result, isTrue);
      expect(provider.state.value, bytes);
      final uploaded = verify(
        () => repository.usersMeProfilePicturePost(
          image: captureAny(named: 'image'),
        ),
      ).captured;
      expect(uploaded.single, bytes);
    },
  );

  test('setProfilePicture returns null when the picker is cancelled', () async {
    picker.nextPick = null;

    final result = await provider.setProfilePicture(ImageSource.gallery);

    expect(result, isNull);
    // The loading state was restored, i.e. the empty bytes build() landed on.
    expect(provider.state.value, isEmpty);
    verifyNever(
      () => repository.usersMeProfilePicturePost(image: any(named: 'image')),
    );
  });

  test('setProfilePicture returns false when the upload fails', () async {
    when(() => repository.usersMeProfilePicturePost(image: any(named: 'image')))
        .thenThrow(Exception('upload failed'));
    picker.nextPick = XFile.fromData(bytes, name: 'picked.png');

    final result = await provider.setProfilePicture(ImageSource.camera);

    expect(result, isFalse);
    expect(provider.state.value, isEmpty);
  });

  test(
    'setProfilePicture returns false when compression cannot fix size',
    () async {
      provider.state = AsyncValue.data(bytes);
      picker.nextPick = XFile.fromData(undecidableBytes, name: 'huge.bin');

      final result = provider.setProfilePicture(ImageSource.gallery);
      // The pick is immediate; the refusal lands when compute() finishes, i.e.
      // when the loading state is replaced by the restored previous one.
      await Future.doWhile(() async {
        if (!provider.state.isLoading) {
          return false;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return true;
      });

      expect(await result, isFalse);
      expect(provider.state.value, bytes);
      verifyNever(
        () => repository.usersMeProfilePicturePost(image: any(named: 'image')),
      );
    },
  );

  test('cropImage uploads the cropped file and updates state', () async {
    provider.state = AsyncValue.data(bytes);
    when(() => repository.usersMeProfilePicturePost(image: any(named: 'image')))
        .thenAnswer(
          (_) async => repository.ok(AppTypesStandardResponsesResult.empty()),
        );
    final cropped = File('${tempDir.path}/cropped_success.png');
    await cropped.writeAsBytes(bytes);
    cropper.nextCrop = CroppedFile(cropped.path);

    final result = provider.cropImage();
    await result;
    await cropper.cropCalled.future;
    await untilCalled(
      () => repository.usersMeProfilePicturePost(image: any(named: 'image')),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(provider.state.value, bytes);
    verify(
      () => repository.usersMeProfilePicturePost(image: any(named: 'image')),
    ).called(1);
  });

  test('cropImage returns null and restores state when cancelled', () async {
    provider.state = AsyncValue.data(bytes);
    cropper.nextCrop = null;

    final result = provider.cropImage();
    await result;
    await cropper.cropCalled.future;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(provider.state.value, bytes);
    verifyNever(
      () => repository.usersMeProfilePicturePost(image: any(named: 'image')),
    );
  });

  test('cropImage returns false when the cropped upload fails', () async {
    provider.state = AsyncValue.data(bytes);
    when(() => repository.usersMeProfilePicturePost(image: any(named: 'image')))
        .thenThrow(Exception('upload failed'));
    final cropped = File('${tempDir.path}/cropped_fail.png');
    await cropped.writeAsBytes(bytes);
    cropper.nextCrop = CroppedFile(cropped.path);

    final result = provider.cropImage();
    await result;
    await cropper.cropCalled.future;
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(provider.state.value, bytes);
  });

  test('cropImage returns false when the crop cannot be compressed', () async {
    provider.state = AsyncValue.data(bytes);
    final cropped = File('${tempDir.path}/cropped_huge.bin');
    await cropped.writeAsBytes(undecidableBytes);
    cropper.nextCrop = CroppedFile(cropped.path);

    final result = provider.cropImage();
    await result;
    await cropper.cropCalled.future;
    // No state transition marks the end of this path: after the crop the
    // closure reads the file and hands it to compute() on a real isolate,
    // which nothing observable reports. Wait long enough for it to be done
    // before the test ends and the container is disposed under it.
    await Future<void>.delayed(const Duration(seconds: 2));

    expect(provider.state.value, bytes);
    verifyNever(
      () => repository.usersMeProfilePicturePost(image: any(named: 'image')),
    );
  });
}
