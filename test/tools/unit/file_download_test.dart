import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/file_download.dart';

/// `downloadFile` was at 4/17 lines: its three-way branch is decided by
/// `kIsWeb` and `defaultTargetPlatform`, so on a VM only the `saveAs` arm could
/// ever run and the iOS share sheet — the arm whose whole purpose is a
/// deliberate product decision — was never executed by anything.
///
/// These tests pin the routing itself, over every value of the enum rather than
/// the handful a device matrix would reach, plus the sanitiser that the iOS arm
/// puts into `fileNameOverrides`.
void main() {
  group('downloadChannelFor', () {
    test('the browser saves through the web API on every platform', () {
      for (final platform in TargetPlatform.values) {
        expect(
          downloadChannelFor(isWeb: true, platform: platform),
          DownloadChannel.saveFile,
          reason:
              'a mobile browser is still a browser, so $platform must not '
              'reach saveAs or the share sheet',
        );
      }
    });

    test('iOS off the web shares, so the user chooses where it goes', () {
      expect(
        downloadChannelFor(isWeb: false, platform: TargetPlatform.iOS),
        DownloadChannel.shareSheet,
        reason:
            'saveAs on iOS can only offer the Files picker, which drops the '
            'file where the user then has to hunt for it',
      );
    });

    test('every other native platform keeps its own save dialog', () {
      for (final platform in TargetPlatform.values) {
        if (platform == TargetPlatform.iOS) continue;
        expect(
          downloadChannelFor(isWeb: false, platform: platform),
          DownloadChannel.saveAs,
          reason: '$platform has a real save dialog and must keep it',
        );
      }
    });
  });

  group('sanitizeFileName', () {
    test('a slash becomes an underscore instead of a directory', () {
      expect(sanitizeFileName('invoice 2026/03'), 'invoice 2026_03');
      expect(sanitizeFileName('event\\night'), 'event_night');
    });

    test('every character a path cannot carry is replaced', () {
      expect(sanitizeFileName(r'a\b:c*d?e"f<g>h|i'), 'a_b_c_d_e_f_g_h_i');
    });

    test('surrounding whitespace is trimmed', () {
      expect(sanitizeFileName('  ticket  '), 'ticket');
    });

    test('a name that sanitises away falls back instead of sharing ""', () {
      expect(sanitizeFileName(''), 'file');
      expect(sanitizeFileName('   '), 'file');
      expect(sanitizeFileName('/'), '_');
    });
  });
}
