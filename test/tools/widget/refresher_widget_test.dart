import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/layouts/column_refresher.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';

/// `Refresher.build` picks its list with `Platform.isAndroid`, which is false
/// on the host, so the Material branch is exercised by calling
/// [Refresher.buildAndroidList] directly from a Consumer host — the same way
/// `build` would on a device.
class _AndroidRefresherHost extends ConsumerWidget {
  final Future Function() onRefresh;
  final ScrollController controller;

  const _AndroidRefresherHost({
    required this.onRefresh,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Refresher(
      onRefresh: onRefresh,
      controller: controller,
      child: const SizedBox(height: 40),
    ).buildAndroidList(ref);
  }
}

class _AndroidColumnRefresherHost extends ConsumerWidget {
  final Future Function() onRefresh;
  final ScrollController controller;

  const _AndroidColumnRefresherHost({
    required this.onRefresh,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColumnRefresher(
      onRefresh: onRefresh,
      controller: controller,
      children: const [Text('first row'), Text('second row')],
    ).buildAndroidList(ref);
  }
}

void main() {
  late ProviderContainer container;
  late ScrollController controller;

  setUp(() {
    container = ProviderContainer();
    controller = ScrollController();
  });

  tearDown(() {
    container.dispose();
    controller.dispose();
  });

  testWidgets('Refresher builds the Cupertino refresh list on the host', (
    tester,
  ) async {
    await pumpWidgetAt(
      tester,
      Refresher(
        onRefresh: () async {},
        controller: controller,
        child: const SizedBox(height: 40),
      ),
      container: container,
    );

    expect(find.byType(Refresher), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
    // The control sits at the viewport's leading edge, outside the onstage
    // area of a non-shrinkwrapped scroll view.
    expect(
      find.byType(CupertinoSliverRefreshControl, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byType(SliverToBoxAdapter), findsOneWidget);
  });

  testWidgets('Refresher builds the Material refresh indicator on Android', (
    tester,
  ) async {
    await pumpWidgetAt(
      tester,
      _AndroidRefresherHost(onRefresh: () async {}, controller: controller),
      container: container,
    );

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('ColumnRefresher lists its children in a Cupertino scroll view', (
    tester,
  ) async {
    await pumpWidgetAt(
      tester,
      ColumnRefresher(
        onRefresh: () async {},
        controller: controller,
        children: const [Text('first row'), Text('second row')],
      ),
      container: container,
    );

    expect(find.byType(ColumnRefresher), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(CupertinoSliverRefreshControl), findsOneWidget);
    expect(find.text('first row'), findsOneWidget);
    expect(find.text('second row'), findsOneWidget);
  });

  testWidgets('ColumnRefresher builds the Material list on Android', (
    tester,
  ) async {
    await pumpWidgetAt(
      tester,
      _AndroidColumnRefresherHost(
        onRefresh: () async {},
        controller: controller,
      ),
      container: container,
    );

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('first row'), findsOneWidget);
    expect(find.text('second row'), findsOneWidget);
  });
}
