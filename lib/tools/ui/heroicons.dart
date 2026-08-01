import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'heroicons.g.dart';

export 'heroicons.g.dart';

/// Style options for [HeroIcon].
///
/// Only the styles this app actually draws exist here. Upstream also ships
/// `mini` and `micro`; adding one means teaching `tool/gen_heroicons.dart` to
/// emit it, so it is deliberately not declarable until then.
enum HeroIconStyle { outline, solid }

/// Drop-in replacement for the `heroicons` package's widget of the same name.
///
/// The package is not used because it bundles all 1288 upstream icons: on the
/// web that inflates `AssetManifest.bin.json`, which every visitor downloads
/// and parses before the first frame, and turns each drawn icon into its own
/// HTTP request. The eighty-odd icons this app references are compiled into the
/// bundle instead — see `tool/gen_heroicons.dart`.
///
/// ```dart
/// HeroIcon(HeroIcons.arrowLeft)
/// ```
class HeroIcon extends StatelessWidget {
  const HeroIcon(
    this.icon, {
    super.key,
    this.color,
    this.size,
    this.style,
    this.semanticLabel,
  });

  /// The icon to be displayed. One of [HeroIcons].
  final HeroIcons icon;

  /// Defaults to the surrounding [IconTheme]'s colour, then to black.
  final Color? color;

  /// Defaults to the surrounding [IconTheme]'s size, then to 24.
  final double? size;

  /// Defaults to [HeroIconStyle.outline].
  final HeroIconStyle? style;

  /// Announced by VoiceOver and TalkBack. Null means the icon is decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? HeroIconStyle.outline;
    final source = switch (style) {
      HeroIconStyle.outline => icon.outline,
      HeroIconStyle.solid => icon.solid,
    };
    assert(
      source != null,
      'HeroIcons.${icon.name} has no ${style.name} variant. Add it under '
      '`${style.name}:` in tool/heroicons.yaml and re-run '
      '`dart run tool/gen_heroicons.dart`.',
    );

    final size = this.size ?? IconTheme.of(context).size ?? 24.0;

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SvgPicture.string(
            // Falling back to the outline drawing keeps a missing variant from
            // becoming a blank hole in a release build; the assertion above is
            // what surfaces it during development.
            source ?? icon.outline,
            colorFilter: ColorFilter.mode(
              color ?? IconTheme.of(context).color ?? Colors.black,
              BlendMode.srcIn,
            ),
            width: size,
            height: size,
            alignment: Alignment.center,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('icon', icon.name, showName: false));
    properties.add(
      EnumProperty<HeroIconStyle>('style', style, defaultValue: null),
    );
    properties.add(DoubleProperty('size', size, defaultValue: null));
    properties.add(ColorProperty('color', color, defaultValue: null));
  }
}
