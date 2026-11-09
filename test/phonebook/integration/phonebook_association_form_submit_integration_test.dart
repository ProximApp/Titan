import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_groupement_provider.dart';
import 'package:titan/phonebook/providers/association_list_provider.dart';
import 'package:titan/phonebook/providers/association_picture_provider.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/router.dart';
import 'package:titan/phonebook/ui/pages/association_add_edit_page/association_add_edit_page.dart';
import 'package:titan/settings/ui/pages/main_page/picture_button.dart';
import 'package:titan/tools/image_compression.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/styleguide/button.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/image_stub.dart';
import '../../shared/fixtures.dart';
import '../phonebook_fixtures.dart';

/// `AssociationAddEditPage`'s save handler and its two picture buttons were
/// both at ZERO lines: the existing add_edit tests only render the form.
///
/// The submit branches are driven against the real router (deep link, as the
/// page's qlevar navigation needs a live route tree):
///  - empty required name → "A field is not filled",
///  - filled name but no association kind → "Please choose an association type",
///  - create → POST + "Association added" + the success route, POST failure →
///    "Error adding",
///  - update → PATCH + "Association updated" + QR.back(), PATCH failure →
///    "Error during update",
/// and the gallery/camera buttons toast all three pick outcomes each
/// (updated / cancelled / upload failure) — image_picker is faked through
/// its platform interface; compression is pure Dart, and the success path
/// feeds a real PNG into the avatar's `Image.memory`.
void main() {
  late IntegrationScaffold scaffold;
  late StubImagePicker picker;
  late ImagePickerPlatform previousPicker;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
    picker = StubImagePicker();
    previousPicker = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = picker;
    addTearDown(() => ImagePickerPlatform.instance = previousPicker);
  });

  final addEditPath =
      '${PhonebookRouter.root}${PhonebookRouter.admin}'
      '${PhonebookRouter.addEditAssociation}';

  /// The admin gate user plus every load the page makes on mount.
  ///
  /// [initialAssociations] seeds the GET: the update path's success branch
  /// rewrites the list IN PLACE (`newList[indexWhere(...)] = t`), so an empty
  /// list would RangeError instead of saving.
  Future<ProviderContainer> pumpAddEdit(
    WidgetTester tester, {
    List<AssociationComplete>? initialAssociations,
    List<dynamic> providerOverrides = const [],
  }) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: phonebookAdminGroupId,
            name: 'admin_phonebook',
          ),
        ],
      ),
      providerOverrides: providerOverrides,
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(
      () => scaffold.repository.phonebookAssociationsGet(),
    ).thenAnswer((_) async => chopperListResponse(initialAssociations ?? []));
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: addEditPath,
      pumpAndSettle: false,
    );
    await settle(tester);
    return container;
  }

  Finder submitButton(String label) =>
      find.descendant(of: find.byType(Button), matching: find.text(label));

  /// The toast pipeline: assert (offstage-insensitive, the way the overlay
  /// stages its items), then pump the auto-close timer out.
  Future<void> expectToast(WidgetTester tester, String text) async {
    expect(find.text(text, skipOffstage: false), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  }

  testWidgets('the save handler guards the empty field and the kind', (
    tester,
  ) async {
    await pumpAddEdit(tester);

    // Empty required name → validate() fails → field error toast.
    await tester.ensureVisible(submitButton('Add'));
    await tester.tap(submitButton('Add'));
    await settle(tester, frames: 4);
    await expectToast(tester, 'A field is not filled');

    // Filled name, but no association kind was ever chosen.
    await tester.enterText(find.byType(TextFormField).at(0), 'Robotics Club');
    await tester.ensureVisible(submitButton('Add'));
    await tester.tap(submitButton('Add'));
    await settle(tester, frames: 4);
    await expectToast(tester, 'Please choose an association type');

    verifyNever(
      () => scaffold.repository.phonebookAssociationsPost(
        body: any(named: 'body'),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating an association POSTs, toasts and routes on', (
    tester,
  ) async {
    when(
      () => scaffold.repository.phonebookAssociationsPost(
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => scaffold.repository.ok(association('a-9', 'Robotics')),
    );
    // The success arm does `d.last` on the captured list value — an empty
    // GET would RangeError instead of routing on.
    final container = await pumpAddEdit(
      tester,
      initialAssociations: [association('a-0', 'Seed Club')],
    );
    container
        .read(associationGroupementProvider.notifier)
        .setAssociationGroupement(groupement('grp-1', 'Clubs'));
    // A settled rebuild before typing: enterText flushes a frame, and a dirty
    // widget would rebuild mid-IME and recreate the field controllers.
    await settle(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Robotics Club');
    await tester.ensureVisible(submitButton('Add'));
    await tester.tap(submitButton('Add'));
    await settle(tester, frames: 8);

    verify(
      () => scaffold.repository.phonebookAssociationsPost(
        body: any(named: 'body'),
      ),
    ).called(1);
    await expectToast(tester, 'Association added');
    // The success arm routes on to the same admin form — no exception.
    expect(find.byType(AssociationAddEditPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a create that lands while the list is broken still toasts the '
      'loading error', (tester) async {
    when(
      () => scaffold.repository.phonebookAssociationsPost(
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => scaffold.repository.ok(association('a-9', 'Robotics')),
    );
    // The POST succeeds, but the cached list never loaded: the handler's
    // `data:` arm cannot run, so it says so instead of routing into a page
    // built from nothing.
    final container = await pumpAddEdit(
      tester,
      providerOverrides: [
        associationListProvider.overrideWith(_BrokenList.new),
      ],
    );
    container
        .read(associationGroupementProvider.notifier)
        .setAssociationGroupement(groupement('grp-1', 'Clubs'));
    await settle(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Robotics Club');
    await tester.ensureVisible(submitButton('Add'));
    await tester.tap(submitButton('Add'));
    await settle(tester, frames: 8);

    // Both toasts are staged in the same frame: the success one, then the
    // list-state one that replaces the route the `data:` arm would take.
    expect(find.text('Association added', skipOffstage: false), findsOneWidget);
    expect(
      find.text('Error loading association', skipOffstage: false),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a create that lands while the list is still loading is a '
      'no-op past the toast', (tester) async {
    when(
      () => scaffold.repository.phonebookAssociationsPost(
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => scaffold.repository.ok(association('a-9', 'Robotics')),
    );
    final container = await pumpAddEdit(
      tester,
      providerOverrides: [
        associationListProvider.overrideWith(_HoldingList.new),
      ],
    );
    container
        .read(associationGroupementProvider.notifier)
        .setAssociationGroupement(groupement('grp-1', 'Clubs'));
    await settle(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Robotics Club');
    await tester.ensureVisible(submitButton('Add'));
    await tester.tap(submitButton('Add'));
    await settle(tester, frames: 8);

    // The loading arm does nothing: only the success toast shows and the
    // form stays put.
    await expectToast(tester, 'Association added');
    expect(find.byType(AssociationAddEditPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed create toasts the adding error', (tester) async {
    when(
      () => scaffold.repository.phonebookAssociationsPost(
        body: any(named: 'body'),
      ),
    ).thenThrow(Exception('create failed'));
    final container = await pumpAddEdit(tester);
    container
        .read(associationGroupementProvider.notifier)
        .setAssociationGroupement(groupement('grp-1', 'Clubs'));
    // See the create test: settle so the rebuild predates enterText.
    await settle(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Robotics Club');
    await tester.ensureVisible(submitButton('Add'));
    await tester.tap(submitButton('Add'));
    await settle(tester, frames: 8);

    await expectToast(tester, 'Error adding');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing an association PATCHes, toasts and goes back', (
    tester,
  ) async {
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdPatch(
        associationId: any(named: 'associationId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    // The success branch rewrites the list in place — the saved association
    // must be IN it (see pumpAddEdit).
    final container = await pumpAddEdit(
      tester,
      initialAssociations: [association('a-1', 'Robot Club')],
    );
    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));
    container
        .read(associationGroupementProvider.notifier)
        .setAssociationGroupement(groupement('grp-1', 'Clubs'));
    await settle(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Robot Club 2');
    await tester.ensureVisible(submitButton('Edit'));
    await tester.tap(submitButton('Edit'));
    await settle(tester, frames: 8);

    verify(
      () => scaffold.repository.phonebookAssociationsAssociationIdPatch(
        associationId: 'a-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    await expectToast(tester, 'Association updated');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed update toasts the updating error', (tester) async {
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdPatch(
        associationId: any(named: 'associationId'),
        body: any(named: 'body'),
      ),
    ).thenThrow(Exception('update failed'));
    final container = await pumpAddEdit(
      tester,
      initialAssociations: [association('a-1', 'Robot Club')],
    );
    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));
    container
        .read(associationGroupementProvider.notifier)
        .setAssociationGroupement(groupement('grp-1', 'Clubs'));
    await settle(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Robot Club 2');
    await tester.ensureVisible(submitButton('Edit'));
    await tester.tap(submitButton('Edit'));
    await settle(tester, frames: 8);

    await expectToast(tester, 'Error during update');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the gallery and camera buttons toast every pick outcome', (
    tester,
  ) async {
    final png = (await tester.runAsync(solidPng))!;
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdPicturePost(
        associationId: any(named: 'associationId'),
        image: any(named: 'image'),
      ),
    ).thenAnswer(
      (_) async =>
          scaffold.repository.ok(AppTypesStandardResponsesResult.empty()),
    );
    // pumpAddEdit's stubAssociationAndProfilePictures answers the picture
    // GET with a 404; re-stub it with real bytes AFTER that so the avatar's
    // Image.memory paints instead of the asset fallback.
    final container = await pumpAddEdit(tester);
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdPictureGet(
        associationId: any(named: 'associationId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopper.Response<List<int>>(http.Response.bytes(png, 200), png),
    );
    // The picture section is an AsyncChild over associationPictureProvider,
    // which nothing on THIS page loads (the app arrives from a card that
    // did) — seed it the way phonebook_detail_edition_modal's test does.
    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));
    container
        .read(associationGroupementProvider.notifier)
        .setAssociationGroupement(groupement('grp-1', 'Clubs'));
    await container
        .read(associationPictureProvider.notifier)
        .getAssociationPicture('a-1');
    await settle(tester);

    final gallery = find.descendant(
      of: find.byType(PictureButton).hitTestable(),
      matching: find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.photo,
      ),
    );
    final camera = find.descendant(
      of: find.byType(PictureButton).hitTestable(),
      matching: find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.camera,
      ),
    );

    // 1. Gallery: pick + upload land → "updated".
    picker.next = XFile.fromData(png);
    await tester.tap(gallery);
    await settle(tester, frames: 8);
    verify(
      () => scaffold.repository.phonebookAssociationsAssociationIdPicturePost(
        associationId: 'a-1',
        image: any(named: 'image'),
      ),
    ).called(1);
    await expectToast(tester, 'Profile picture updated');

    // 2. Camera: the same pick + upload, taken from the camera button.
    picker.next = XFile.fromData(png);
    await tester.tap(camera);
    await settle(tester, frames: 8);
    await expectToast(tester, 'Profile picture updated');

    // 3. Gallery: a cancelled pick → the null arm → "error".
    picker.next = null;
    await tester.tap(gallery);
    await settle(tester, frames: 8);
    await expectToast(tester, 'Error editing profile picture');

    // 4. Camera: a cancelled pick → the same null arm.
    await tester.tap(camera);
    await settle(tester, frames: 8);
    await expectToast(tester, 'Error editing profile picture');

    // 5. Camera: upload throws → the false arm → "too large".
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdPicturePost(
        associationId: any(named: 'associationId'),
        image: any(named: 'image'),
      ),
    ).thenThrow(Exception('upload failed'));
    picker.next = XFile.fromData(png);
    await tester.tap(camera);
    await settle(tester, frames: 8);
    await expectToast(tester, 'Image is too large (max 4MB)');

    // 6. Gallery: the same failing upload through the other button.
    await tester.tap(gallery);
    await settle(tester, frames: 8);
    await expectToast(tester, 'Image is too large (max 4MB)');

    // 7. A pick the compressor cannot decode (over the upload limit and not
    // an image) is refused before any POST: `compressImageForUpload` answers
    // null, so the notifier puts the previous state back and says false.
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdPicturePost(
        associationId: any(named: 'associationId'),
        image: any(named: 'image'),
      ),
    ).thenAnswer(
      (_) async =>
          scaffold.repository.ok(AppTypesStandardResponsesResult.empty()),
    );
    await tester.runAsync(() async {
      picker.next = XFile.fromData(
        Uint8List(maxUploadedImageSize + 1),
        mimeType: 'application/octet-stream',
      );
      await tester.tap(gallery);
      await tester.pump();
      // The compression runs on an isolate: give it real time to answer.
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await settle(tester, frames: 8);
    await expectToast(tester, 'Image is too large (max 4MB)');

    expect(tester.takeException(), isNull);
  });
}

/// The association catalog in its `error:` state, with a create that still
/// answers true — the shape the handler's `error:` arm exists for.
class _BrokenList extends AssociationListNotifier {
  @override
  AsyncValue<List<AssociationComplete>> build() =>
      AsyncError(Exception('offline'), StackTrace.empty);

  @override
  Future<bool> createAssociation(
    AppModulesPhonebookSchemasPhonebookAssociationBase association,
  ) async => true;
}

/// The same, but the catalog never resolves.
class _HoldingList extends AssociationListNotifier {
  @override
  AsyncValue<List<AssociationComplete>> build() => const AsyncValue.loading();

  @override
  Future<bool> createAssociation(
    AppModulesPhonebookSchemasPhonebookAssociationBase association,
  ) async => true;
}
