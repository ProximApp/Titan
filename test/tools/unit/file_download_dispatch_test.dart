import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:titan/tools/file_download.dart';

/// `downloadFile` itself, not just its channel choice: each arm has its own
/// way of answering "did the user actually get the file".
///
/// The web arm (`saveFile`, non-nullable result) cannot be reached on the VM —
/// `kIsWeb` is a compile-time constant — so it stays untested here.
/// `SharePlus.instance` is a static final that captures `SharePlatform.instance`
/// on first use, so the suite installs one fake up front and varies its answer
/// per test instead of swapping the instance.
class FakeSharePlatform extends SharePlatform {
  ShareResultStatus status = ShareResultStatus.success;
  ShareParams? captured;

  @override
  Future<ShareResult> share(ShareParams params) async {
    captured = params;
    return ShareResult('', status);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const codec = StandardMessageCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const saveAsChannel = 'dev.flutter.pigeon.file_saver.FileSaverHostApi.saveAs';

  final bytes = Uint8List.fromList([1, 2, 3]);
  final share = FakeSharePlatform();

  setUpAll(() {
    SharePlatform.instance = share;
  });

  setUp(() {
    share.status = ShareResultStatus.success;
    share.captured = null;
  });

  void stubSaveAs(Object? path) {
    messenger.setMockMessageHandler(
      saveAsChannel,
      (message) async => codec.encodeMessage(<Object?>[path]),
    );
  }

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMessageHandler(saveAsChannel, null);
  });

  test('a completed save dialog reports the file was handed over', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    stubSaveAs('/Users/someone/report.pdf');

    final saved = await downloadFile(
      name: 'report',
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    expect(saved, isTrue);
  });

  test('backing out of the save dialog reports nothing was saved', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    stubSaveAs(null);

    final saved = await downloadFile(
      name: 'report',
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    expect(saved, isFalse);
  });

  test('iOS shares the file and a completed share counts as saved', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final saved = await downloadFile(
      name: 'my/report',
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    expect(saved, isTrue);
    // `XFile.name` is ignored off the web, so the sanitised name travels in
    // `fileNameOverrides` — that override is what share_plus names the
    // temporary file after. Letting the slash through would drop the file in
    // a directory that does not exist.
    final params = share.captured!;
    expect(params.files!.single.mimeType, MimeType.pdf.type);
    expect(params.fileNameOverrides, ['my_report.pdf']);
    expect(params.text, isNull);
  });

  test('dismissing the share sheet reports nothing was saved', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    share.status = ShareResultStatus.dismissed;

    final saved = await downloadFile(
      name: 'report',
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    expect(saved, isFalse);
  });
}
