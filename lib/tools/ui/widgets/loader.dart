import 'package:flutter/material.dart';

class Loader extends StatelessWidget {
  final Color? color;
  final double? maxSize;
  static const double defaultMaxSize = 64.0;
  static const double fallbackSize = 24.0;

  const Loader({super.key, this.color = Colors.black, this.maxSize});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final derived =
            constraints.hasBoundedWidth && constraints.hasBoundedHeight
            ? constraints.biggest.shortestSide
            : fallbackSize;
        final ceiling = maxSize ?? defaultMaxSize;
        final size = derived > ceiling ? ceiling : derived;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(color: color),
          ),
        );
      },
    );
  }
}
