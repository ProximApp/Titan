import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/mypayment/ui/pages/fund_page/web_view_modal.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../shared/app_scaffold.dart';

/// The funding page's in-app browser (`/mypayment/fund?path=…`).
///
/// `WebViewController` talks to `WebViewPlatform.instance`, and a widget test
/// has no implementation of it, so nothing in the suite had ever mounted this
/// page or its route: the builder threw before the first line. This file owns
/// the platform for its isolate (flutter test gives every file one) and
/// records what the page asks of it — the URL it loads, the JavaScript mode it
/// sets, and the widget it paints. That is the whole page; the browser itself
/// stays the plugin's business.

/// The controller the page drives, recording the two calls it makes.
class _RecordingController extends PlatformWebViewController {
  // The app's creation params carry nothing this fake records, so it builds
  // its own: what the page decides is the calls it makes, not the params.
  _RecordingController(this.owner)
    : super.implementation(const PlatformWebViewControllerCreationParams());

  final _FakeWebViewPlatform owner;

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    owner.loadedUrls.add(params.uri);
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {
    owner.javaScriptModes.add(javaScriptMode);
  }

  @override
  Future<String?> currentUrl() async =>
      owner.loadedUrls.isEmpty ? null : owner.loadedUrls.last.toString();
}

/// What the page's `WebViewWidget` paints in place of the native view.
class _RecordingWebViewWidget extends PlatformWebViewWidget {
  _RecordingWebViewWidget(PlatformWebViewController controller, this.owner)
    : super.implementation(
        PlatformWebViewWidgetCreationParams(controller: controller),
      );

  final _FakeWebViewPlatform owner;

  @override
  Widget build(BuildContext context) {
    owner.paintedWidgets++;
    return const SizedBox.expand();
  }
}

class _FakeWebViewPlatform extends WebViewPlatform {
  final loadedUrls = <Uri>[];
  final javaScriptModes = <JavaScriptMode>[];
  var paintedWidgets = 0;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => _RecordingController(this);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => _RecordingWebViewWidget(params.controller, this);
}

void main() {
  late IntegrationScaffold scaffold;
  late _FakeWebViewPlatform platform;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    platform = _FakeWebViewPlatform();
    // Not restored on teardown: the setter rejects null, and this file is its
    // own isolate, so the fake goes away with the process.
    WebViewPlatform.instance = platform;
  });

  testWidgets('the fund route opens the funding URL in an in-app browser', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
    );
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/mypayment/fund?path=https%3A%2F%2Fhelloasso.example%2Fpay',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    // The route built the browser page...
    expect(find.byType(WebViewExample), findsOneWidget);
    // ...which asked the platform for a controller, unrestricted JavaScript and
    // the funding URL the payment provider redirected to. The URL is the
    // `path` query parameter, decoded: a raw `https%3A%2F%2F…` would send the
    // user to a page that does not exist.
    expect(platform.javaScriptModes, [JavaScriptMode.unrestricted]);
    expect(platform.loadedUrls, [Uri.parse('https://helloasso.example/pay')]);
    // ...and painted it.
    expect(platform.paintedWidgets, 1);
  });

  testWidgets('the browser page carries no top-up UI of its own', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
    );
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/mypayment/fund?path=https%3A%2F%2Fhelloasso.example%2Fpay',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    // The provider page owns the whole screen: an app bar over the web view,
    // and none of the fund sheet's keypad or amount widgets behind it.
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(WebViewWidget), findsOneWidget);
    expect(find.text('Top-up'), findsNothing);
  });
}
