import 'package:flutter/material.dart';
import 'package:titan/login/ui/web/left_panel.dart';
import 'package:titan/login/ui/web/right_panel.dart';
import 'package:titan/tools/functions.dart';

class WebSignIn extends StatelessWidget {
  const WebSignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/${getBaseSchoolName()}/back.webp'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const Row(
              children: [
                Expanded(child: LeftPanel()),
                Expanded(child: RightPanel()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
