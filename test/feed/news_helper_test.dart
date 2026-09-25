import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/feed/tools/image_color_utils.dart';
import 'package:titan/feed/tools/news_filter_type.dart';
import 'package:titan/feed/tools/news_helper.dart';
import 'package:titan/generated/openapi.swagger.dart';

News news({DateTime? start, DateTime? end}) =>
    News.empty().copyWith(start: start ?? DateTime(2000), end: end);

void main() {
  group('isNewsTerminated', () {
    test('is true when the end date has passed', () {
      final terminated = news(
        start: DateTime(2020),
        end: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(isNewsTerminated(terminated), isTrue);
    });

    test('is false while the end date is in the future', () {
      final ongoing = news(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 1)),
      );

      expect(isNewsTerminated(ongoing), isFalse);
    });

    test('is false when the news has no end date', () {
      expect(isNewsTerminated(news(start: DateTime(2000))), isFalse);
    });
  });

  group('isNewsOngoing', () {
    test('is true between start and end', () {
      final ongoing = news(
        start: DateTime.now().subtract(const Duration(hours: 1)),
        end: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(isNewsOngoing(ongoing), isTrue);
    });

    test('is true after the start when there is no end date', () {
      final started = news(
        start: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(isNewsOngoing(started), isTrue);
    });

    test('is false before the start', () {
      final upcoming = news(
        start: DateTime.now().add(const Duration(days: 1)),
        end: DateTime.now().add(const Duration(days: 2)),
      );

      expect(isNewsOngoing(upcoming), isFalse);
    });

    test('is false once the end date has passed', () {
      final finished = news(
        start: DateTime.now().subtract(const Duration(days: 2)),
        end: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(isNewsOngoing(finished), isFalse);
    });
  });

  group('NewsFilterType.getKey', () {
    test('maps every filter to its translation key', () {
      expect(NewsFilterType.all.getKey(), 'feedFilterAll');
      expect(NewsFilterType.pending.getKey(), 'feedFilterPending');
      expect(NewsFilterType.approved.getKey(), 'feedFilterApproved');
      expect(NewsFilterType.rejected.getKey(), 'feedFilterRejected');
    });
  });

  group('image color utils', () {
    test('isColorDark classifies colors by their luminance', () {
      expect(isColorDark(const Color(0xFF101010)), isTrue);
      expect(isColorDark(const Color(0xFFEEEEEE)), isFalse);
    });

    test('getTextColor picks a readable color for both backgrounds', () {
      // The two returned colors must differ, otherwise text would be
      // unreadable on one of the backgrounds.
      final onDark = getTextColor(const Color(0xFF101010));
      final onLight = getTextColor(const Color(0xFFEEEEEE));

      expect(onDark, isNot(onLight));
    });
  });
}
