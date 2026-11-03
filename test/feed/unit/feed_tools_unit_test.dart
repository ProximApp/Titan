import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/feed/tools/image_color_utils.dart';
import 'package:titan/feed/tools/news_filter_type.dart';
import 'package:titan/tools/constants.dart';

/// The two pure helpers in `lib/feed/tools/` that no test reached: the
/// luminance helpers behind the adaptive card text, and the filter-key
/// switch — the generated extension test only ever calls `getKey()` on
/// `NewsFilterType.values.first`, so three of its four cases were dead.
///
/// `getDominantColor`'s sampling lives in the widget test instead: it needs
/// a real image codec, which only the widget binding provides.
void main() {
  group('image_color_utils', () {
    test('isColorDark reads luminance off the colour channels', () {
      expect(isColorDark(const Color(0xFF000000)), isTrue);
      expect(isColorDark(const Color(0xFFFFFFFF)), isFalse);
      // 0.299*0.2 + 0.587*0.2 + 0.114*0.2 = 0.2 < 0.5
      expect(isColorDark(const Color(0xFF333333)), isTrue);
    });

    test('getTextColor picks the contrasting preset', () {
      expect(getTextColor(const Color(0xFF000000)), ColorConstants.background);
      expect(getTextColor(const Color(0xFFFFFFFF)), ColorConstants.onTertiary);
    });
  });

  group('NewsFilterTypeExtension', () {
    test('getKey covers every filter case', () {
      expect(NewsFilterType.all.getKey(), 'feedFilterAll');
      expect(NewsFilterType.pending.getKey(), 'feedFilterPending');
      expect(NewsFilterType.approved.getKey(), 'feedFilterApproved');
      expect(NewsFilterType.rejected.getKey(), 'feedFilterRejected');
    });
  });
}
