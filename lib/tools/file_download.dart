import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Hands [bytes] to the user as `<name>.<fileExtension>`.
///
/// iOS gets the share sheet — open the file in another app, AirDrop it, or
/// *Save to Files* when that is really what was wanted. `saveAs` there can only
/// offer the Files picker, which drops the file somewhere the user then has to
/// go and find before they can read it.
///
/// Every other platform keeps its native save dialog.
///
/// [shareOrigin] anchors the popover the share sheet opens as on iPad; take it
/// from the widget that triggered the download with [shareOriginOf].
///
/// Returns false when the user backed out, so the caller can stay quiet rather
/// than announce a download that did not happen.
/// Which hand-off [downloadFile] uses.
///
/// Split out from the call itself so the ROUTING — the part a user notices when
/// it is wrong, and the part that cannot be reached on a VM when it is decided
/// by `kIsWeb` and `defaultTargetPlatform` — is testable without a platform or
/// a plugin channel.
enum DownloadChannel { shareSheet, saveFile, saveAs }

/// The channel for [platform] and [isWeb].
///
/// The browser wins over the platform: a mobile browser is still a browser, and
/// `saveAs` has no meaning there.
DownloadChannel downloadChannelFor({
  required bool isWeb,
  required TargetPlatform platform,
}) {
  if (isWeb) return DownloadChannel.saveFile;
  if (platform == TargetPlatform.iOS) return DownloadChannel.shareSheet;
  return DownloadChannel.saveAs;
}

Future<bool> downloadFile({
  required String name,
  required Uint8List bytes,
  required String fileExtension,
  required MimeType mimeType,
  Rect? shareOrigin,
}) async {
  switch (downloadChannelFor(isWeb: kIsWeb, platform: defaultTargetPlatform)) {
    case DownloadChannel.shareSheet:
      final fileName = '${sanitizeFileName(name)}.$fileExtension';
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes, mimeType: mimeType.type, name: fileName),
          ],
          // `XFile.name` is ignored off the web, and share_plus names the
          // temporary file it shares after the override instead.
          fileNameOverrides: [fileName],
          sharePositionOrigin: shareOrigin,
        ),
      );
      return result.status != ShareResultStatus.dismissed;

    case DownloadChannel.saveFile:
      await FileSaver.instance.saveFile(
        name: name,
        bytes: bytes,
        fileExtension: fileExtension,
        mimeType: mimeType,
      );
      // `saveFile` answers a NON-nullable `String` — a web download has no
      // "the user backed out" to report — so a completed call is a save. The
      // old single ternary hid that: its `String?` came from the `saveAs`
      // arm, and this null check could never be false.
      return true;

    case DownloadChannel.saveAs:
      final path = await FileSaver.instance.saveAs(
        name: name,
        bytes: bytes,
        fileExtension: fileExtension,
        mimeType: mimeType,
      );
      // The one arm that can answer null, and null is the user backing out of
      // the save dialog — the caller stays quiet instead of announcing a
      // download that did not happen.
      return path != null;
  }
}

/// The rect an iPad share sheet should point at, read from the widget the user
/// tapped. Null when that widget is not laid out, which lets the sheet fall back
/// to the middle of the screen.
///
/// Call it before awaiting anything: it needs the render object still attached.
Rect? shareOriginOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Strips what a file name cannot carry into a path — event and invoice names
/// are free text, and a slash in one would send the shared file to a directory
/// that does not exist.
@visibleForTesting
String sanitizeFileName(String name) {
  final sanitized = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  return sanitized.isEmpty ? 'file' : sanitized;
}
