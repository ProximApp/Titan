import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/constants.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';

CustomIconButton _button({
  CustomIconButtonType type = CustomIconButtonType.main,
  bool? disabled,
}) => CustomIconButton(
  type: type,
  disabled: disabled,
  icon: const Icon(Icons.add),
  onPressed: () {},
);

/// `textColor` is only read by pages that style their own chrome, so the
/// getter is exercised directly: one arm per type, plus the disabled dim.
void main() {
  test('textColor resolves per button type', () {
    expect(_button().textColor, ColorConstants.background);
    expect(
      _button(type: CustomIconButtonType.danger).textColor,
      ColorConstants.background,
    );
    expect(
      _button(type: CustomIconButtonType.secondary).textColor,
      ColorConstants.tertiary,
    );
  });

  test('a disabled button dims the colour by alpha 150', () {
    expect(
      _button(disabled: true).textColor,
      ColorConstants.background.withAlpha(150),
    );
    expect(_button(disabled: false).textColor, ColorConstants.background);
    expect(
      _button(type: CustomIconButtonType.secondary, disabled: true).textColor,
      ColorConstants.tertiary.withAlpha(150),
    );
  });
}
