import 'package:flutter/material.dart';
import 'package:titan/tools/constants.dart';
import 'package:titan/tools/ui/styleguide/list_item_template.dart';

/// A boolean row laid out like every other list row in the module.
///
/// Material's [SwitchListTile] brings its own typography and padding, which is
/// what made the edit page stand out from the rest of the tickets screens.
class SwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;

  /// A null callback renders the row read-only.
  final ValueChanged<bool>? onChanged;

  const SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return ListItemTemplate(
      title: title,
      subtitle: subtitle,
      onTap: onChanged == null ? null : () => onChanged(!value),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: ColorConstants.background,
        activeTrackColor: ColorConstants.main,
      ),
    );
  }
}
