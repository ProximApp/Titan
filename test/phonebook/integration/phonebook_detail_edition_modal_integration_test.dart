import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_groupement_provider.dart';
import 'package:titan/phonebook/providers/association_picture_provider.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/router.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';

/// AssociationEditionModal — the bottom sheet the PRESIDENT sees behind the
/// pencil icon on /phonebook/association_detail (36 lines at 0%: the admin
/// page's modal is a different widget). This file owns the one deferred
/// route journey (pencil → Edit → the add-edit form → the groupement form,
/// convention 10); the modal's two buttons both navigate, so the members
/// side lives in phonebook_president_members_integration_test.dart.
/// The picture GET returns real PNG bytes here so the edit form's avatar
/// runs the provider's `Image.memory` branch (the 404 stubs elsewhere only
/// ever exercise the asset fallback).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  /// A president for a-1: the member list carries ME (id u-1) with a
  /// Presidency role tag, and the roletags endpoint lists it first — that
  /// is exactly what isAssociationPresidentProvider compares.
  void stubPresidentDetail(IntegrationScaffold scaffold, {Uint8List? png}) {
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
    );
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
    );
    when(() => scaffold.repository.phonebookRoletagsGet()).thenAnswer(
      (_) async => chopperResponse(RoleTagsReturn(tags: ['President'])),
    );
    when(
      () => scaffold.repository
          .phonebookAssociationsAssociationIdMembersMandateYearGet(
            associationId: 'a-1',
            mandateYear: 2026,
          ),
    ).thenAnswer(
      (_) async => chopperListResponse([
        member('u-1', 'Bolt', 'Ada', 'Lovelace', roleTags: 'President'),
      ]),
    );
    if (png == null) {
      stubAssociationAndProfilePictures(scaffold);
    } else {
      when(
        () => scaffold.repository.phonebookAssociationsAssociationIdPictureGet(
          associationId: any(named: 'associationId'),
        ),
      ).thenAnswer(
        (_) async =>
            chopper.Response<List<int>>(http.Response.bytes(png, 200), png),
      );
      scaffold.stubProfilePicture();
    }
  }

  ProviderContainer presidentContainer() => scaffold.makeContainer(
    // President AND phonebook admin: the pencil gate reads the member
    // list, but the groupement form nested under the president-side page
    // still carries AdminMiddleware(isPhonebookAdminProvider).
    user: CoreUser.empty().copyWith(
      id: 'u-1',
      groups: [
        CoreGroupSimple.empty().copyWith(
          id: phonebookAdminGroupId,
          name: 'admin_phonebook',
        ),
      ],
    ),
  );

  /// A genuinely decodable 8x8 PNG so `Image.memory` paints instead of
  /// throwing `Invalid image data`.
  Future<Uint8List> solidPng() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 8, 8),
      Paint()..color = const Color(0xFF00FF00),
    );
    final image = await recorder.endRecording().toImage(8, 8);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> pumpDeferred(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('the president edits the association through the detail modal', (
    tester,
  ) async {
    final png = (await tester.runAsync(solidPng))!;
    final container = presidentContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubPresidentDetail(scaffold, png: png);

    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));
    container
        .read(associationGroupementProvider.notifier)
        .setAssociationGroupement(groupement('grp-1', 'Clubs'));
    // Pre-load the picture so the avatar is data, not the perpetual loader
    // animation that would hang every pumpAndSettle in this test.
    await container
        .read(associationPictureProvider.notifier)
        .getAssociationPicture('a-1');

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.associationDetail}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('Robot Club'), findsOneWidget);
    expect(find.text('Clubs'), findsOneWidget);

    // The pencil only renders for the association's president.
    final pencil = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.pencilSquare,
    );
    expect(pencil, findsOneWidget);
    await scaffold.openModal(tester, pencil);
    expect(scaffold.isModalOpen(tester), isTrue);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Manage members'), findsOneWidget);

    // "Edit" pops the sheet, seeds the providers and routes to the
    // president-side add-edit form (deferred: pump until it mounts).
    await scaffold.tapInModal(tester, find.text('Edit'));
    await pumpDeferred(tester);

    expect(scaffold.isModalOpen(tester), isFalse);
    // Edit-mode title and submit button are both phonebookEdit ("Edit").
    expect(find.text('Edit'), findsNWidgets(2));
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields[0].controller!.text, 'Robot Club');
    expect(fields[1].controller!.text, 'We build robots');
    // The modal fetched the picture with REAL bytes: the avatar renders
    // through the provider's Image.memory branch.
    expect(
      find.byWidgetPredicate(
        (w) => w is CircleAvatar && w.backgroundImage is MemoryImage,
      ),
      findsAtLeastNWidgets(1),
    );
    // The selected groupement reached the editable bar (the modal set it).
    expect(find.text('Clubs'), findsOneWidget);

    // Same journey continues: the bar's "+" chip routes to the groupement
    // form nested under this president-side page (add mode).
    await tester.tap(find.byKey(const Key('add')));
    await pumpDeferred(tester);
    expect(find.text('Add an association groupement'), findsOneWidget);
    expect(find.text('Groupement name'), findsOneWidget);
  });

  testWidgets('pulling the detail page down reloads members and picture', (
    tester,
  ) async {
    final container = presidentContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubPresidentDetail(scaffold);

    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.associationDetail}',
      pumpAndSettle: false,
    );
    await settle(tester);

    // Refresher runs on the Cupertino path under the test binding: pull the
    // page down past the threshold and release.
    await tester.drag(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.text('Robot Club'),
      ),
      const Offset(0, 300),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    verify(
      () => scaffold.repository
          .phonebookAssociationsAssociationIdMembersMandateYearGet(
            associationId: 'a-1',
            mandateYear: 2026,
          ),
    ).called(2);
  });
}
