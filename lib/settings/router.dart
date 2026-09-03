import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/navigation/class/module.dart';

import 'package:titan/settings/ui/pages/log_page/log_page.dart'
    deferred as log_page;
import 'package:titan/settings/ui/pages/main_page/main_page.dart'
    deferred as main_page;

import 'package:titan/tools/middlewares/authenticated_middleware.dart';
import 'package:titan/tools/middlewares/deferred_middleware.dart';
import 'package:qlevar_router/qlevar_router.dart';

class SettingsRouter {
  final Ref ref;
  static const String root = '/settings';
  static const String logs = '/logs';
  static final Module module = Module(
    getName: (context) => AppLocalizations.of(context)!.moduleSettings,
    getDescription: (context) =>
        AppLocalizations.of(context)!.moduleSettingsDescription,
    root: SettingsRouter.root,
  );

  SettingsRouter(this.ref);

  QRoute route() => QRoute(
    name: "settings",
    path: SettingsRouter.root,
    builder: () => main_page.SettingsMainPage(),
    middleware: [
      AuthenticatedMiddleware(ref),
      DeferredLoadingMiddleware(main_page.loadLibrary),
    ],
    pageType: QCustomPage(
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
    children: !kIsWeb
        ? [
            QRoute(
              path: logs,
              builder: () => log_page.LogPage(),
              middleware: [DeferredLoadingMiddleware(log_page.loadLibrary)],
            ),
          ]
        : null,
  );
}
