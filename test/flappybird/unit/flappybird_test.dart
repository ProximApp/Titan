import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/flappybird/class/pipe.dart';
import 'package:titan/flappybird/tools/functions.dart';

void main() {
  group('Pipe', () {
    test('defaults to not passed and copies with new values', () {
      final pipe = Pipe(position: 1.5, height: 100);

      expect(pipe.isPassed, false);

      final passed = pipe.copyWith(isPassed: true);

      expect(passed.position, 1.5);
      expect(passed.height, 100);
      expect(passed.isPassed, true);
    });

    test('empty pipe is at the origin', () {
      final pipe = Pipe.empty();

      expect(pipe.position, 0);
      expect(pipe.height, 0);
      expect(pipe.isPassed, false);
    });

    test('random keeps the position and varies the height', () {
      final pipe = Pipe.random(position: 3.0);

      expect(pipe.position, 3.0);
      expect(pipe.height, greaterThanOrEqualTo(50.0));
      expect(pipe.height, lessThan(350.0));
    });

    test('random produces different heights across calls (statistically)', () {
      final heights = {
        for (var i = 0; i < 30; i++) Pipe.random(position: i.toDouble()).height,
      };

      expect(heights.length, greaterThan(1));
    });

    test('toString describes the pipe', () {
      final pipe = Pipe(position: 1, height: 2, isPassed: true);

      expect(pipe.toString(), contains('position: 1.0'));
      expect(pipe.toString(), contains('height: 2.0'));
      expect(pipe.toString(), contains('isPassed: true'));
    });
  });

  group('getSwatch', () {
    test('returns the ten material shades around the base color', () {
      final swatch = getSwatch(Colors.blue);

      expect(
        swatch.keys,
        containsAll([50, 100, 200, 300, 400, 500, 600, 700, 800, 900]),
      );
      expect(swatch[500]!.value, Colors.blue.value);
    });

    test('lighter shades are brighter than the base', () {
      final swatch = getSwatch(Colors.blue);

      expect(
        swatch[50]!.computeLuminance(),
        greaterThan(swatch[500]!.computeLuminance()),
      );
      expect(
        swatch[900]!.computeLuminance(),
        lessThan(swatch[500]!.computeLuminance()),
      );
    });
  });
}
