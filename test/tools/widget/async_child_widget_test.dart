import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/builders/async_child.dart';
import 'package:tuple/tuple.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for the shared AsyncValue builders every page uses.
/// The data/loading/error arms and the multi-child variants only run when a
/// page renders them, so they are mounted directly here.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpChild(WidgetTester tester, Widget child) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(tester, child, container);
  }

  Widget dummyBuilder(BuildContext context, String value) =>
      Text(value, textDirection: TextDirection.ltr);

  group('AsyncChild', () {
    testWidgets('renders the builder on data', (tester) async {
      await pumpChild(
        tester,
        AsyncChild<String>(
          value: AsyncValue.data('loaded'),
          builder: dummyBuilder,
        ),
      );
      expect(find.text('loaded'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the default loader while loading', (tester) async {
      await pumpChild(
        tester,
        AsyncChild<String>(value: AsyncValue.loading(), builder: dummyBuilder),
      );
      // The default loading branch is the shared circular Loader.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the default error text on failure', (tester) async {
      await pumpChild(
        tester,
        AsyncChild<String>(
          value: AsyncValue.error('boom', StackTrace.empty),
          builder: dummyBuilder,
        ),
      );
      expect(find.textContaining('boom'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('honours custom loading, error and orElse builders', (
      tester,
    ) async {
      await pumpChild(
        tester,
        AsyncChild<String>(
          value: AsyncValue.loading(),
          loadingBuilder: (context) =>
              Text('custom-loading', textDirection: TextDirection.ltr),
          orElseBuilder: (context, child) =>
              Padding(padding: EdgeInsets.all(4), child: child),
          builder: dummyBuilder,
        ),
      );
      expect(find.text('custom-loading'), findsOneWidget);

      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        AsyncChild<String>(
          value: AsyncValue.error('bad', StackTrace.empty),
          errorBuilder: (error, stack) =>
              Text('custom-error:$error', textDirection: TextDirection.ltr),
          orElseBuilder: (context, child) =>
              Padding(padding: const EdgeInsets.all(4), child: child),
          builder: dummyBuilder,
        ),
        container,
      );
      expect(find.text('custom-error:bad'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('handleLoadingAndError', () {
    testWidgets('picks the first error, then loading, then shrinks', (
      tester,
    ) async {
      // Error wins over loading.
      await pumpChild(
        tester,
        handleLoadingAndErrorBuilder([
          const AsyncValue<int>.loading(),
          AsyncValue.error('first', StackTrace.empty),
        ]),
      );
      expect(find.textContaining('first'), findsOneWidget);

      // Loading when nothing failed.
      await pumpChild(
        tester,
        handleLoadingAndErrorBuilder([const AsyncValue<int>.loading()]),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // All data renders the orElse child (a shrink here).
      await pumpChild(
        tester,
        handleLoadingAndErrorBuilder([
          const AsyncValue<int>.data(1),
          const AsyncValue<int>.data(2),
        ]),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('first'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('AsyncNChildren', () {
    Widget two() => Async2Children<int, String>(
      values: const Tuple2(AsyncValue.data(1), AsyncValue.data('two')),
      builder: (context, a, b) =>
          Text('1-two', textDirection: TextDirection.ltr),
    );

    testWidgets('Async2Children renders when both sides carry data', (
      tester,
    ) async {
      await pumpChild(tester, two());
      expect(find.text('1-two'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Async2Children defers to the shared loader on loading', (
      tester,
    ) async {
      await pumpChild(
        tester,
        Async2Children<int, String>(
          values: const Tuple2(AsyncValue.loading(), AsyncValue.data('two')),
          builder: (context, a, b) =>
              Text('$a-$b', textDirection: TextDirection.ltr),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Async3Children renders and defers to the shared error', (
      tester,
    ) async {
      await pumpChild(
        tester,
        Async3Children<int, String, bool>(
          values: const Tuple3(
            AsyncValue.data(1),
            AsyncValue.data('two'),
            AsyncValue.data(true),
          ),
          builder: (context, a, b, c) =>
              Text('$a-$b-$c', textDirection: TextDirection.ltr),
        ),
      );
      expect(find.text('1-two-true'), findsOneWidget);

      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        Async3Children<int, String, bool>(
          values: const Tuple3(
            AsyncValue.data(1),
            AsyncValue.data('two'),
            AsyncValue.loading(),
          ),
          builder: (context, a, b, c) =>
              Text('$a-$b-$c', textDirection: TextDirection.ltr),
        ),
        container,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Async4Children and Async5Children render their data', (
      tester,
    ) async {
      await pumpChild(
        tester,
        Async4Children<int, String, bool, double>(
          values: const Tuple4(
            AsyncValue.data(1),
            AsyncValue.data('two'),
            AsyncValue.data(true),
            AsyncValue.data(2.5),
          ),
          builder: (context, a, b, c, d) =>
              Text('$a-$b-$c-$d', textDirection: TextDirection.ltr),
        ),
      );
      expect(find.text('1-two-true-2.5'), findsOneWidget);

      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        Async5Children<int, String, bool, double, int>(
          values: const Tuple5(
            AsyncValue.data(1),
            AsyncValue.data('two'),
            AsyncValue.data(true),
            AsyncValue.data(2.5),
            AsyncValue.data(7),
          ),
          builder: (context, a, b, c, d, e) =>
              Text('$a-$b-$c-$d-$e', textDirection: TextDirection.ltr),
        ),
        container,
      );
      expect(find.text('1-two-true-2.5-7'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Async5Children shows the shared loader while one loads', (
      tester,
    ) async {
      await pumpChild(
        tester,
        Async5Children<int, String, bool, double, int>(
          values: const Tuple5(
            AsyncValue.data(1),
            AsyncValue.data('two'),
            AsyncValue.data(true),
            AsyncValue.data(2.5),
            AsyncValue.loading(),
          ),
          builder: (context, a, b, c, d, e) =>
              Text('$a-$b-$c-$d-$e', textDirection: TextDirection.ltr),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Wraps [handleLoadingAndError] in the widget shape the pumps expect.
Widget handleLoadingAndErrorBuilder(List<AsyncValue> values) => Builder(
  builder: (context) => handleLoadingAndError(
    values,
    context,
    loadingBuilder: (context) =>
        const CircularProgressIndicator(color: Colors.black),
    errorBuilder: (error, stack) =>
        Text('handled:$error', textDirection: TextDirection.ltr),
  ),
);
