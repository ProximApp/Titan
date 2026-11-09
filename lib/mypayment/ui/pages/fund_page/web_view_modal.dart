import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The funding page handed to the payment provider: an in-app browser on
/// the URL the fund flow navigates to.
///
/// The URL is the `path` query parameter of the provider's redirect, already
/// decoded — the page loads exactly what it is given.
///
/// `WebViewController` needs a `WebViewPlatform` implementation, which a widget
/// test does not have by default; `web_view_modal_widget_test.dart` installs a
/// recording one for its isolate and walks this page and its route.
class WebViewExample extends ConsumerWidget {
  const WebViewExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = QR.params['path'].toString();

    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      appBar: AppBar(),
      body: WebViewWidget(controller: controller),
    );
  }
}
