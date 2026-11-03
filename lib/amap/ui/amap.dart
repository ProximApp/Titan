import 'package:flutter/material.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/amap/router.dart';
import 'package:titan/tools/providers/rendered_path_provider.dart';
import 'package:titan/tools/constants.dart';
import 'package:titan/tools/ui/widgets/top_bar.dart';

class AmapTemplate extends ConsumerWidget {
  final Widget child;
  const AmapTemplate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: ColorConstants.background,
      child: SafeArea(
        child: Column(
          children: [
            TopBar(
              root: AmapRouter.root,
              rightIcon: ref.watch(renderedPathProvider) == AmapRouter.root
                  ? IconButton(
                      onPressed: () {
                        QR.to(AmapRouter.root + AmapRouter.presentation);
                      },
                      icon: const HeroIcon(
                        HeroIcons.informationCircle,
                        color: Colors.black,
                        size: 40,
                      ),
                    )
                  : null,
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
