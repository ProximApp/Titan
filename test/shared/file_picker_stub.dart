import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';

/// A byte-backed [PlatformFile]: `readAsBytes()` answers from memory, so
/// nothing touches the disk. Real file IO inside `testWidgets` never resumes
/// in this environment (an `await` on a real `File` write hangs the test), so
/// every pick must stay byte-backed.
///
/// The `uri` uses a non-file scheme, which is what makes `path` (derived from
/// it) null — the "not on local disk" answer the pre-v13 constructor's
/// `path: null` gave.
base class StubPlatformFile extends PlatformFile {
  StubPlatformFile({required this.name, required this._bytes})
    : uri = Uri(scheme: 'stub', path: name);

  @override
  final String name;

  @override
  final Uri uri;

  final Uint8List _bytes;

  @override
  XFile get xFile => XFile.fromData(_bytes, name: name);

  @override
  int? lengthSync() => _bytes.length;

  @override
  Future<int?> length() async => _bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(_bytes);
}

/// A [FilePickerPlatform] whose native dialog is a queue the test fills:
/// every `FilePicker.pickFile` call shifts one entry, and an empty queue (or
/// an explicit `null`) means the user cancelled. Install with
/// `FilePickerPlatform.instance = picker` and restore the previous instance
/// in an `addTearDown`.
class StubFilePicker extends FilePickerPlatform {
  final List<PlatformFile?> queue = [];

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    if (queue.isEmpty) return null;
    return queue.removeAt(0);
  }
}

/// A pick backed by in-memory [bytes]: `PlatformFile.readAsBytes()` returns
/// them first, so nothing touches the disk.
///
/// `size` is what the app's size checks see; the default payload is [size]
/// zero bytes so a size-limit toast compares the real byte length. Pass
/// [bytes] when the test asserts what the app decodes.
PlatformFile stubPick(String name, {required int size, Uint8List? bytes}) {
  return StubPlatformFile(name: name, bytes: bytes ?? Uint8List(size));
}
