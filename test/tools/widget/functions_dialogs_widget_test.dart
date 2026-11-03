import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/functions.dart';

import '../../shared/app_scaffold.dart';

/// Widget coverage for the platform-dialog wrappers in
/// `lib/tools/functions.dart` (`displayToast`, `getOnlyDayDate`,
/// `getOnlyDayDateFunction`, `getOnlyHourDate`, `pickFullDate`,
/// `getFullDate`) and their private `_getDate` / `_getTime` pickers. Each
/// flow drives the real Material dialogs: OK confirms the preselected value,
/// CANCEL exercises the null paths.
class _Harness extends StatefulWidget {
  const _Harness();

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final TextEditingController day = TextEditingController();
  final TextEditingController dayFn = TextEditingController();
  final TextEditingController hour = TextEditingController();
  final TextEditingController full = TextEditingController();
  String? pickedByCallback;
  bool? pickFullDateWasNull;
  bool? cancelledFullDateKeptController;

  @override
  void dispose() {
    day.dispose();
    dayFn.dispose();
    hour.dispose();
    full.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () async {
              await getOnlyDayDate(context, day);
              if (mounted) setState(() {});
            },
            child: const Text('day'),
          ),
          TextButton(
            onPressed: () async {
              await getOnlyDayDateFunction(
                context,
                (s) => setState(() => pickedByCallback = s),
              );
              if (mounted) setState(() {});
            },
            child: const Text('dayFn'),
          ),
          TextButton(
            onPressed: () async {
              await getOnlyHourDate(context, hour);
              if (mounted) setState(() {});
            },
            child: const Text('hour'),
          ),
          TextButton(
            onPressed: () async {
              await getFullDate(context, full);
              if (mounted) setState(() {});
            },
            child: const Text('full'),
          ),
          TextButton(
            onPressed: () async {
              final picked = await pickFullDate(context);
              if (mounted) setState(() => pickFullDateWasNull = picked == null);
            },
            child: const Text('pickOk'),
          ),
          TextButton(
            onPressed: () async {
              final picked = await pickFullDate(context);
              if (mounted) setState(() => pickFullDateWasNull = picked == null);
            },
            child: const Text('pickTimeCancel'),
          ),
          TextButton(
            onPressed: () async {
              final before = full.text;
              await getFullDate(context, full);
              if (mounted) {
                setState(
                  () => cancelledFullDateKeptController = full.text == before,
                );
              }
            },
            child: const Text('fullCancel'),
          ),
        ],
      ),
    );
  }
}

_HarnessState _harnessState(WidgetTester tester) =>
    tester.state<_HarnessState>(find.byType(_Harness));

Future<void> acceptDialog(WidgetTester tester) async {
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> cancelDialog(WidgetTester tester) async {
  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('displayToast renders both the success and the error toast', (
    tester,
  ) async {
    await pumpWidgetAt(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () {
              displayToast(context, TypeMsg.msg, 'all good here');
              displayToast(context, TypeMsg.error, 'it broke here');
            },
            child: const Text('toast'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('toast'));
    await tester.pump();
    // Toastification's entries only materialise on stepped frames: a single
    // 2s jump leaves them invisible (verified), while 500ms steps show both
    // toasts at t+1s — well before the 2.5s autoClose.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('all good here'), findsOneWidget);
    expect(find.text('it broke here'), findsOneWidget);

    // Let the 2500ms autoClose timers fire and the exit animations finish so
    // the test ends without a pending Timer.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('getOnlyDayDate fills the controller after the picker is OKd', (
    tester,
  ) async {
    await pumpWidgetAt(tester, const _Harness());

    await tester.tap(find.text('day'));
    await tester.pumpAndSettle();
    expect(find.text('OK'), findsOneWidget);
    await acceptDialog(tester);

    expect(
      _harnessState(tester).day.text,
      matches(RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$')),
    );
  });

  testWidgets('getOnlyDayDateFunction hands the date to its callback', (
    tester,
  ) async {
    await pumpWidgetAt(tester, const _Harness());

    await tester.tap(find.text('dayFn'));
    await tester.pumpAndSettle();
    await acceptDialog(tester);

    final picked = _harnessState(tester).pickedByCallback;
    expect(picked, isNotNull);
    // yMMMd renders like "Oct 26, 2026".
    expect(picked, matches(RegExp(r'^\w{3} \d{1,2}, \d{4}$')));
  });

  testWidgets('getOnlyHourDate fills the controller after the time picker', (
    tester,
  ) async {
    await pumpWidgetAt(tester, const _Harness());

    await tester.tap(find.text('hour'));
    await tester.pumpAndSettle();
    expect(find.text('OK'), findsOneWidget);
    await acceptDialog(tester);

    expect(
      _harnessState(tester).hour.text,
      matches(RegExp(r'^\d{1,2}:\d{2}$')),
    );
  });

  testWidgets(
    'pickFullDate answers a date, and null when the time is cancelled',
    (tester) async {
      await pumpWidgetAt(tester, const _Harness());

      // Date OK, time OK.
      await tester.tap(find.text('pickOk'));
      await tester.pumpAndSettle();
      await acceptDialog(tester);
      expect(find.text('OK'), findsOneWidget);
      await acceptDialog(tester);
      expect(_harnessState(tester).pickFullDateWasNull, isFalse);

      // Date OK, time CANCEL — the date branch runs past `date == null`.
      await tester.tap(find.text('pickTimeCancel'));
      await tester.pumpAndSettle();
      await acceptDialog(tester);
      expect(find.text('Cancel'), findsOneWidget);
      await cancelDialog(tester);
      expect(_harnessState(tester).pickFullDateWasNull, isTrue);
    },
  );

  testWidgets(
    'getFullDate fills the controller, and returns early when cancelled',
    (tester) async {
      await pumpWidgetAt(tester, const _Harness());

      // Cancel the date stage: `picked` is null, the controller stays empty.
      await tester.tap(find.text('fullCancel'));
      await tester.pumpAndSettle();
      await cancelDialog(tester);
      expect(_harnessState(tester).cancelledFullDateKeptController, isTrue);
      expect(_harnessState(tester).full.text, isEmpty);

      // Date OK, time OK: "M/d/yyyy H:mm".
      await tester.tap(find.text('full'));
      await tester.pumpAndSettle();
      await acceptDialog(tester);
      expect(find.text('OK'), findsOneWidget);
      await acceptDialog(tester);
      expect(
        _harnessState(tester).full.text,
        matches(RegExp(r'^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}$')),
      );
    },
  );
}
