import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// A [FilePickerPlatform] whose native dialog is a queue the test fills:
/// every `FilePicker.pickFile` call shifts one entry, and an empty queue (or
/// an explicit `null`) means the user cancelled. Install with
/// `FilePickerPlatform.instance = picker` and restore the previous instance
/// in an `addTearDown`.
class StubFilePicker extends FilePickerPlatform {
  final List<FilePickerResult?> queue = [];

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
    AndroidSAFOptions? androidSafOptions,
  }) async {
    if (queue.isEmpty) return null;
    return queue.removeAt(0);
  }
}

/// A pick result backed by in-memory [bytes]: `PlatformFile.readAsBytes()`
/// returns the `bytes` field first, so nothing touches the disk. Real file
/// IO inside `testWidgets` never resumes in this environment (an `await` on
/// a real `File` write hangs the test), so every pick must stay byte-backed.
///
/// `size` is what the app's size checks see; the payload is [size] zero
/// bytes so a size-limit toast compares the real byte length.
FilePickerResult stubPick(String name, {required int size}) {
  return FilePickerResult([
    PlatformFile(
      path: null,
      name: name,
      size: size,
      bytes: Uint8List(
        size,
      ), // ignore: deprecated_member_use — only zero-IO source
    ),
  ]);
}
