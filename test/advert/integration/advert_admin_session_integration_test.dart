import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
// image_picker's own export uses a `show` list without the platform types.
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/advert/providers/advert_posters_provider.dart';
import 'package:titan/advert/providers/selected_association_provider.dart';
import 'package:titan/advert/router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
// HeroIcon predicate finders below.

import '../../shared/app_scaffold.dart';
import '../advert_fixtures.dart';

final myAssociation = Association.empty().copyWith(
  id: 'asso-1',
  name: 'BDE de Lille',
);
final advert = AdvertComplete.empty().copyWith(
  id: 'a-1',
  title: 'Members only sale',
  content: 'From the association itself',
  advertiserId: 'asso-1',
  date: DateTime(2026, 5, 1),
);

Finder pencil() =>
    find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.pencil);
Finder trash() =>
    find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash);

/// Hands `ImagePicker().pickImage` an in-memory file — the real platform
/// channel has no host in tests. Only the method the widget actually calls
/// (`getImageFromSource`) is overridden; the rest throw UnimplementedError
/// like the base class.
class _FakeImagePickerPlatform extends ImagePickerPlatform {
  _FakeImagePickerPlatform(this.bytes);

  final Uint8List bytes;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile.fromData(bytes);
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubAdmin(IntegrationScaffold scaffold) {
    when(() => scaffold.repository.advertAdvertsGet())
        .thenAnswer((_) async => chopperListResponse([advert]));
    when(
      () => scaffold.repository.associationsAssociationIdLogoGet(
        associationId: any(named: 'associationId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "File does not exist"}', 404),
        [],
        error: 'File does not exist',
      ),
    );
    when(
      () => scaffold.repository.advertAdvertsAdvertIdPictureGet(
        advertId: any(named: 'advertId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "File does not exist"}', 404),
        [],
        error: 'File does not exist',
      ),
    );
  }

  testWidgets(
    'admin session: chip filter, edit arms, refresh, delete, Post, back',
    (tester) async {
      final container = scaffold.makeContainer(
        // The AdminMiddleware gate checks association membership
        // (myAssociations — exactly one, which also arms the Post
        // auto-select branch). The admin GROUP flips isAdminProvider,
        // arming the isAdmin arms of the refresh/delete closures and
        // switching the bar to the repository-backed association list.
        user: CoreUser.empty().copyWith(
          id: 'user-1',
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
              name: 'admin',
            ),
          ],
        ),
        myAssociations: [myAssociation],
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubAdmin(scaffold);
      // The pull-to-refresh closure reloads the my-associations list too
      // (MyAssociationListNotifier.loadAssociations → associationsMeGet).
      when(() => scaffold.repository.associationsMeGet())
          .thenAnswer((_) async => chopperListResponse([myAssociation]));
      // isAdmin switches the bar to the repository-backed association list.
      when(() => scaffold.repository.associationsGet())
          .thenAnswer((_) async => chopperListResponse([myAssociation]));
      // Engine work (Picture → PNG) needs real async inside fake-async tests.
      final png = (await tester.runAsync(solidPng))!;
      // The edit form renders the advert's poster from the posters map.
      container
          .read(advertPostersProvider.notifier)
          .setTData('a-1', AsyncData([Image.memory(png)]));
      when(
        () => scaffold.repository.advertAdvertsAdvertIdPatch(
          advertId: any(named: 'advertId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<void>(http.Response('err', 400), null),
      );
      when(
        () => scaffold.repository.advertAdvertsAdvertIdDelete(
          advertId: any(named: 'advertId'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());
      when(
        () => scaffold.repository.advertAdvertsPost(body: any(named: 'body')),
      ).thenAnswer((_) async => chopperResponse(advert.copyWith(id: 'a-9')));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${AdvertRouter.root}${AdvertRouter.admin}',
        pumpAndSettle: false,
      );
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 10);

      expect(find.text('Members only sale'), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // --- multi-select chip filter (both select and remove arms) --------
      await tester.tap(find.text('BDE de Lille'));
      await settle(tester);
      expect(container.read(selectedAssociationProvider), hasLength(1));
      expect(find.text('Members only sale'), findsOneWidget); // still matches
      await tester.tap(find.text('BDE de Lille'));
      await settle(tester);
      expect(container.read(selectedAssociationProvider), isEmpty);
      expect(find.text('Members only sale'), findsOneWidget); // unfiltered

      // --- edit: PATCH 400 stays, PATCH 200 goes back ---------------------
      await tester.ensureVisible(pencil());
      await settle(tester, frames: 2);
      await tester.tap(pencil());
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 10);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Members only sale'), findsOneWidget);
      // The preseeded poster renders through the poster stack branches.
      expect(tester.takeException(), isNull);

      // Checkbox toggles (create/edit branch state init + onChanged).
      await tester.ensureVisible(find.text('Publish to feed?'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Publish to feed?'));
      await settle(tester);
      await tester.ensureVisible(find.text('Send a notification'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Send a notification'));
      await settle(tester);

      await tester.ensureVisible(find.text('Edit'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Edit'));
      await settle(tester, frames: 12);
      expect(find.text('Error while editing'), findsOneWidget);
      await scaffold.drainToast(tester);
      // Failure keeps the form up.
      expect(find.text('Edit'), findsOneWidget);

      // Install a fake picker so the UPDATE success arm's
      // `poster.value != null` poster PATCH (lines 301-303) runs.
      final originalPicker = ImagePickerPlatform.instance;
      addTearDown(() => ImagePickerPlatform.instance = originalPicker);
      ImagePickerPlatform.instance = _FakeImagePickerPlatform(png);
      when(
        () => scaffold.repository.advertAdvertsAdvertIdPicturePost(
          advertId: any(named: 'advertId'),
          image: any(named: 'image'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());
      expect(find.byType(AspectRatio), findsOneWidget);
      await tester.ensureVisible(find.byType(AspectRatio));
      await settle(tester, frames: 2);
      await tester.tap(find.byType(AspectRatio));
      await settle(tester, frames: 6);

      when(
        () => scaffold.repository.advertAdvertsAdvertIdPatch(
          advertId: any(named: 'advertId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => chopperResponse(advert));
      await tester.ensureVisible(find.text('Edit'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Edit'));
      await settle(tester, frames: 12);
      expect(find.text('Advert edited'), findsOneWidget);
      await scaffold.drainToast(tester);
      // QR.back() → the admin page again.
      expect(find.text('Post'), findsOneWidget);

      // --- pull to refresh ------------------------------------------------
      await tester.fling(
        find.text('Members only sale'),
        const Offset(0, 300),
        1000,
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 10);
      expect(find.text('Members only sale'), findsOneWidget);

      // resetTData nulled the posters map during the refresh and the admin
      // card does not reload it, so re-seed the entry the delete dialog's
      // deleteE(id, 0) relies on (state[t]! would otherwise crash).
      container
          .read(advertPostersProvider.notifier)
          .setTData('a-1', AsyncData([Image.memory(png)]));

      // --- delete: dialog → Confirm → list surgery ------------------------
      await tester.ensureVisible(trash());
      await settle(tester, frames: 2);
      await tester.tap(trash());
      await settle(tester, frames: 6);
      expect(find.text('Deleting'), findsOneWidget);
      expect(find.text('Delete ad?'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await settle(tester, frames: 12);
      verify(
        () => scaffold.repository.advertAdvertsAdvertIdDelete(advertId: 'a-1'),
      ).called(1);
      expect(find.text('Members only sale'), findsNothing);
      expect(tester.takeException(), isNull);

      // --- Post button: auto-selects the single association ----------------
      // The edit trip left the association selected; deselect it so the
      // handler's `length == 1 && selected.isEmpty` auto-select arm runs.
      await tester.tap(find.text('BDE de Lille'));
      await settle(tester);
      expect(container.read(selectedAssociationProvider), isEmpty);

      await tester.tap(find.text('Post'));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 10);
      expect(find.text('Add'), findsOneWidget);
      // …and the chip was preselected by the handler.
      expect(container.read(selectedAssociationProvider), hasLength(1));
      expect(tester.takeException(), isNull);

      // --- the template TopBar's onBack closure ----------------------------
      // AdvertTemplate passes a non-null onBack, so the chevron only clears
      // the selected associations — it deliberately does NOT pop the route.
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.chevronLeft,
        ),
      );
      await settle(tester, frames: 10);
      expect(find.text('Add'), findsOneWidget); // still on the form
      expect(tester.takeException(), isNull);
    },
  );
}
