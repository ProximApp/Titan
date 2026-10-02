import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
// The MODELS barrel on purpose: the umbrella `openapi.swagger.dart` also
// exports a `Size` ENUM, which shadows dart:ui's Size for every measurement.
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/ui/components/association_research_bar.dart';
import 'package:titan/phonebook/ui/components/groupement_bar.dart';
import 'package:titan/phonebook/ui/components/member_card.dart';
import 'package:titan/phonebook/ui/pages/admin_page/editable_association_card.dart';
import 'package:titan/phonebook/ui/pages/main_page/association_card.dart';
import 'package:titan/phonebook/ui/pages/member_detail_page/membership_card.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/phonebook_fixtures.dart';

/// Widget-level tests for the phonebook rows — the module's first widget
/// level, and the one fixed-width sweep found nothing in.
///
/// That is the point of this file: `tool/detect_fixed_width_cards.py` looks
/// for a hardcoded `width` next to flex children, and none of the phonebook
/// rows has one. They all render through `ListItemTemplate`, which wraps the
/// title in an `Expanded` Column and lets the text wrap, so the horizontal
/// axis cannot overflow the way `AdminAdvertCard` did (ledger #47). Mounting
/// them at 360px is what proves that for the family instead of assuming it.
///
/// The rows are also the module's only place where a long association name
/// meets a long role name in a single line — `MemberCard` builds
/// "nickname - roleName" and `MembershipCard` builds "association - role",
/// both by string concatenation, so the title is the concatenation of the two
/// longest labels the app can produce.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    phonebookSetUp(scaffold);
  });

  /// Long on purpose: the harness measures this in real Lato, and the length
  /// is what decides whether the concatenated title wraps or not.
  const longName =
      'Association des etudiants en medecine de l universite de bordeaux';

  /// The members list behind `MemberCard`'s avatar, and the groupement
  /// catalog behind both bars. Unstubbed, these return null where a Future is
  /// expected and the card dies before it lays out — which would make "no
  /// overflow" true for the wrong reason.
  void stubCardLoads(List<MemberComplete> members) {
    when(
      () => scaffold.repository
          .phonebookAssociationsAssociationIdMembersMandateYearGet(
            associationId: any(named: 'associationId'),
            mandateYear: any(named: 'mandateYear'),
          ),
    ).thenAnswer((_) async => chopperListResponse(members));
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([
        groupement('grp-1', 'Culture'),
        groupement('grp-2', longName),
      ]),
    );
    stubPhonebookPictures(scaffold);
  }

  AssociationComplete asso() => association('a-1', longName, mandateYear: 2026);

  MembershipComplete membership(String roleName) =>
      MembershipComplete.empty().copyWith(
        id: 'm-1',
        userId: 'user-1',
        associationId: 'a-1',
        mandateYear: 2026,
        roleName: roleName,
        memberOrder: 0,
      );

  /// The same member with NO nickname, built through the real constructor
  /// because the generated `copyWith` is `nickname ?? this.nickname` — passing
  /// null there keeps the old value instead of clearing it, so a copyWith
  /// fixture can never reach the `nickname == null` branch of `getName()`.
  MemberComplete memberWithoutNickname() => MemberComplete(
    id: 'm-1',
    name: 'DelaunayDeserializer',
    firstname: 'Jean-Baptiste',
    accountType: enums.AccountType.student,
    schoolId: 'school-1',
    email: 'm-1@myem.fr',
    memberships: [
      MembershipComplete.empty().copyWith(
        id: 'm-1',
        userId: 'm-1',
        associationId: 'a-1',
        mandateYear: 2026,
        roleName: 'President',
        memberOrder: 0,
      ),
    ],
  );

  testWidgets('the association row fits a long name and groupement', (
    tester,
  ) async {
    stubCardLoads(const []);
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: AssociationCard(
            association: asso(),
            groupement: groupement('grp-1', 'Culture'),
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    // Non-vacuity: the row itself mounted, not just an ancestor.
    expect(find.byType(AssociationCard), findsOneWidget);
    expect(find.text(longName), findsOneWidget);
    expect(find.text('Culture'), findsOneWidget);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the editable association row fits the same data', (
    tester,
  ) async {
    stubCardLoads(const []);
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: EditableAssociationCard(
            association: asso(),
            groupement: groupement('grp-1', longName),
            isPhonebookAdmin: true,
            isAdmin: false,
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(EditableAssociationCard), findsOneWidget);
    // The admin row puts the groupement in the subtitle and the association
    // in the title, so the long label is the subtitle here.
    expect(find.text(longName), findsNWidgets(2));

    await scaffold.unmountApp(tester);
  });

  testWidgets('the membership row fits "association - role" in one line', (
    tester,
  ) async {
    stubCardLoads(const []);
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: MembershipCard(
            association: asso(),
            membership: membership('Tresorier adjoint'),
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(MembershipCard), findsOneWidget);
    // The title is the concatenation, not two separate lines.
    expect(find.text('$longName - Tresorier adjoint'), findsOneWidget);
    // The mandate year is the subtitle.
    expect(find.text('2026'), findsOneWidget);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the member row fits "nickname - role" plus a subtitle', (
    tester,
  ) async {
    final theMember = member(
      'm-1',
      'Turbo',
      'Jean-Baptiste',
      'DelaunayDeserializer',
      roleName: 'President',
    );
    stubCardLoads([theMember]);
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: MemberCard(
            member: theMember,
            association: asso(),
            deactivated: false,
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(MemberCard), findsOneWidget);
    expect(find.text('Turbo - President'), findsOneWidget);
    // A nickname means the subtitle is the real name, not the nickname.
    expect(find.text('Jean-Baptiste DelaunayDeserializer'), findsOneWidget);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the member row falls back to the full name without a nickname', (
    tester,
  ) async {
    // `getName()` returns "firstname name" when nickname is null, and the
    // row concatenates that with the role — the longest title in the module.
    final theMember = memberWithoutNickname();
    stubCardLoads([theMember]);
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: MemberCard(
            member: theMember,
            association: asso(),
            deactivated: false,
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(MemberCard), findsOneWidget);
    expect(
      find.text('Jean-Baptiste DelaunayDeserializer - President'),
      findsOneWidget,
    );
    // No nickname, so the subtitle is null and the row is one line shorter.
    expect(find.text('Turbo'), findsNothing);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the groupement bar fits a long chip name in its 40px box', (
    tester,
  ) async {
    // The bar pins height: 40 for the horizontal strip while `ItemChip` pads
    // 10px vertically on each side, so a two-line chip label is the shape
    // that would break out of the box. The label is allowed to run long
    // because the ListView scrolls it, but not to grow taller than 40.
    stubCardLoads(const []);
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(body: SingleChildScrollView(child: AssociationGroupementBar())),
      container,
      appFonts: true,
    );
    await settle(tester, frames: 4);

    expect(find.byType(AssociationGroupementBar), findsOneWidget);
    expect(find.text('Culture'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the groupement bar fits vertically too', (tester) async {
    // The filter modal renders the same bar vertically, where the height is
    // min(count * 52, 220) and a wrapped chip label is no longer free.
    stubCardLoads(const []);
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: AssociationGroupementBar(scrollDirection: Axis.vertical),
        ),
      ),
      container,
      appFonts: true,
    );
    await settle(tester, frames: 4);

    expect(find.byType(AssociationGroupementBar), findsOneWidget);
    expect(find.text('Culture'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the research bar fits with the filter affordance offered', (
    tester,
  ) async {
    // The filter button only appears when there is more than one groupement,
    // so this is the state where the search bar carries a second control.
    stubCardLoads(const []);
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(body: AssociationResearchBar()),
      container,
      appFonts: true,
    );
    await settle(tester, frames: 4);

    expect(find.byType(AssociationResearchBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
