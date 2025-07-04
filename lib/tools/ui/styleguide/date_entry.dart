import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:titan/tools/constants.dart';
import 'package:titan/tools/ui/styleguide/list_item_template.dart';

class DateEntry extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Function()? onTap;
  const DateEntry({super.key, required this.title, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListItemTemplate(
      onTap: onTap,
      title: title,
      subtitle: subtitle,
      trailing: const HeroIcon(
        HeroIcons.calendar,
        color: ColorConstants.tertiary,
      ),
    );
  }
}
