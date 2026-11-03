import 'dart:math';
import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/amap/tools/amap_background_painter.dart';

/// The floating-bubble background behind the amap catalogue
/// (`amap_background_painter.dart`, 29 uncovered lines): `Sphere`'s
/// constructor, factory and `move()`, every cull branch of `paint()` and
/// `shouldRepaint`.
///
/// The spheres are seeded directly (the painter's list is public), so each
/// removal branch runs deterministically on the first paint — the only
/// random step is the 5%-per-frame spawn, which a long paint loop makes
/// certain, and the factory is also called directly.
void main() {
  test('the bubble background culls, moves and draws its spheres', () {
    final painter = AmapBackgroundPainter(
      animation: const AlwaysStoppedAnimation<double>(0),
    );
    // Three spheres parked past each cull edge and one in bounds: x only
    // grows for angles above -90°, so the right exit needs a seeded x
    // beyond the canvas.
    painter.spheres.addAll([
      Sphere(420, 100, 10, 2, 0), // x - radius > width
      Sphere(-30, 100, 10, 2, pi), // x + radius < 0
      Sphere(100, -30, 10, 2, -pi / 2), // y + radius < 0
      Sphere(100, 300, 10, 2, -pi / 2), // in bounds: moves and draws
    ]);

    painter.paint(Canvas(PictureRecorder()), const Size(400, 600));

    // The three edge cases were culled; the survivor stepped north by
    // speed * sin(angle) = -2.
    expect(
      painter.spheres.any((s) => s.x == 420 || s.x == -30 || s.y == -30),
      isFalse,
    );
    expect(painter.spheres.any((s) => (s.y - 298).abs() < 1e-6), isTrue);

    // The 5%-per-frame spawn branch (and its factory): 500 rolls leave a
    // probability of ~7e-12 of never rolling one.
    for (var i = 0; i < 500; i++) {
      painter.paint(Canvas(PictureRecorder()), const Size(400, 600));
    }
    // The factory itself, called directly so the assertion does not depend
    // on the roll.
    final born = Sphere.generateNextSphere(400, 600);
    expect(born.radius, greaterThanOrEqualTo(7));
    expect(born.radius, lessThan(17));

    // The painter listens through repaint:, so a delegate swap never asks
    // for a repaint.
    expect(painter.shouldRepaint(painter), isFalse);
  });
}
