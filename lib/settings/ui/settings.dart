import 'package:flutter/material.dart';
import 'package:titan/tools/constants.dart';

class SettingsTemplate extends StatelessWidget {
  final Widget child;
  const SettingsTemplate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(color: ColorConstants.background, child: child);
  }
}
