import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/amap/ui/pages/admin_page/adding_user_card.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The card that turns a searched user into a cash line. It shows the full
/// name when there is no nickname to stand in for it, and a tap both creates
/// the zero-balance cash entry and reports back so the strip can flip.
/// The two lines of the card, top to bottom.
List<String?> cardTexts(WidgetTester tester) => tester
    .widgetList<AutoSizeText>(find.byType(AutoSizeText))
    .map((text) => text.data)
    .toList();

void main() {
  CoreUserSimple user({String? nickname}) => CoreUserSimple(
    name: 'Roucher',
    firstname: 'Maxime',
    nickname: nickname,
    id: 'user-1',
    accountType: AccountType.student,
    schoolId: 'school-1',
  );

  testWidgets('a user without a nickname shows their full name', (
    tester,
  ) async {
    var added = 0;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await pumpWidgetAt(
      tester,
      AddingUserCard(user: user(), onAdd: () => added++),
      container: container,
      frames: 6,
    );

    // The heading stands in the first name when there is no nickname, and the
    // subtitle falls back to the plain name. The card uses AutoSizeText, which
    // draws through its own render object, so the strings are read off the
    // widgets rather than through find.text.
    expect(cardTexts(tester), ['Maxime', 'Roucher']);

    await tester.tap(find.byType(AddingUserCard));
    await settle(tester, frames: 4);
    expect(added, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a nickname promotes the full name to the subtitle', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await pumpWidgetAt(
      tester,
      AddingUserCard(
        user: user(nickname: 'Max'),
        onAdd: () {},
      ),
      container: container,
      frames: 6,
    );

    expect(cardTexts(tester), ['Max', 'Maxime Roucher']);
  });
}
