import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
// image_picker's own export uses a `show` list without the platform types.
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/advert/providers/selected_association_provider.dart';
import 'package:titan/advert/router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The CREATE branch of the add-edit form as its own router session
/// (convention 19 — one router-pushing test per file): three association
/// names exercising every AssociationBar avatar fallback, the single-select
/// select/deselect closures, BOTH FormField validators' red states with the
/// "Incorrect or missing fields" gate, the two checkbox toggles, and the
/// template TopBar's onBack closure.
/// A genuinely decodable PNG — `fileBytes` feeds `Image.memory`, and raw
/// text throws `Invalid image data` on paint.
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

final associations = [
  // length ≤ 3 → uppercased whole name.
  Association.empty().copyWith(id: 'a1', name: 'BDE'),
  // ≥ 2 word parts → first letters of the first two.
  Association.empty().copyWith(id: 'a2', name: 'Chauffage Collective'),
  // single long word → first three letters uppercased.
  Association.empty().copyWith(id: 'a3', name: 'UucopLille'),
];

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

  testWidgets(
    'create form: association selection, validator reds, checkboxes, back',
    (tester) async {
      final container = scaffold.makeContainer(myAssociations: associations);
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);

      // Logos: the first association resolves to real bytes (dataBuilder),
      // the rest fall through to the initials avatar (orElseBuilder).
      // Engine work (Picture → PNG) needs real async inside fake-async tests.
      final png = (await tester.runAsync(solidPng))!;
      when(
        () => scaffold.repository.associationsAssociationIdLogoGet(
          associationId: any(named: 'associationId'),
        ),
      ).thenAnswer((invocation) async {
        final id = invocation.namedArguments[#associationId] as String? ?? '';
        if (id == 'a1') {
          return chopper.Response<List<int>>(
            http.Response.bytes(png, 200),
            png,
          );
        }
        return chopper.Response<List<int>>(
          http.Response('{"detail": "File does not exist"}', 404),
          [],
          error: 'File does not exist',
        );
      });
      // build() fires loadAdverts immediately; without a data state the
      // list notifier's add() short-circuits (handleState) and no POST
      // would ever be issued.
      when(() => scaffold.repository.advertAdvertsGet()).thenAnswer(
        // A non-empty data state: the page's `list.last` after a successful
        // save reads the SNAPSHOT taken when the button was tapped, and
        // `.last` on an empty list throws.
        (_) async => chopperListResponse([posterlessAdvert()]),
      );
      when(
        () => scaffold.repository.advertAdvertsPost(body: any(named: 'body')),
      ).thenAnswer((_) async => chopperResponse(posterlessAdvert()));

      // Deep-link straight into CREATE mode: advertProvider is untouched,
      // so advert.id == AdvertComplete.empty().id → isEdit is false.
      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${AdvertRouter.root}${AdvertRouter.admin}${AdvertRouter.addEditAdvert}',
        pumpAndSettle: false,
      );
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 10);

      expect(find.text('Add'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // --- single-select association bar ---------------------------------
      // Tap #2: clears any selection then selects (the `!selected` arm).
      await tester.tap(find.text('Chauffage Collective'));
      await settle(tester);
      // Tap #1: switching replaces the previous selection.
      await tester.tap(find.text('BDE'));
      await settle(tester);
      // Tap #1 again: already selected → the clear-only arm deselects.
      await tester.ensureVisible(find.text('BDE'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('BDE'));
      await settle(tester);

      // --- checkbox toggles ----------------------------------------------
      await tester.ensureVisible(find.text('Publish to feed?'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Publish to feed?'));
      await settle(tester);
      await tester.ensureVisible(find.text('Send a notification'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Send a notification'));
      await settle(tester);
      // Toggle back to the initial states.
      await tester.ensureVisible(find.text('Publish to feed?'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Publish to feed?'));
      await settle(tester);
      await tester.ensureVisible(find.text('Send a notification'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Send a notification'));
      await settle(tester);

      // --- poster validator red state ------------------------------------
      // Association selected but no poster → FormField<File> errors and the
      // generic gate toast fires (key.validate() is false).
      await tester.ensureVisible(find.text('Chauffage Collective'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Chauffage Collective'));
      await settle(tester);
      await tester.ensureVisible(find.text('Add'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 10);
      // The FormField validators only paint a red glow (their messages are
      // never rendered as text), so the observable proof of the failed
      // validate() run is the generic gate toast.
      expect(find.text('Incorrect or missing fields'), findsOneWidget);
      await scaffold.drainToast(tester);

      // --- announcer validator red state ---------------------------------
      // Deselect → FormField<List<Association>> errors (red glow container).
      await tester.ensureVisible(find.text('Chauffage Collective'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Chauffage Collective'));
      await settle(tester);
      await tester.ensureVisible(find.text('Add'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 10);
      expect(find.text('Incorrect or missing fields'), findsOneWidget);
      await scaffold.drainToast(tester);
      expect(tester.takeException(), isNull);

      // --- the template TopBar's onBack closure ---------------------------
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

      // --- the success path: fake picker + valid fields --------------------
      final originalPicker = ImagePickerPlatform.instance;
      addTearDown(() => ImagePickerPlatform.instance = originalPicker);
      ImagePickerPlatform.instance = _FakeImagePickerPlatform(png);

      when(
        () => scaffold.repository.advertAdvertsAdvertIdPicturePost(
          advertId: any(named: 'advertId'),
          image: any(named: 'image'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());

      // Re-select the announcer (the chevron cleared it) — and prove the
      // chip taps actually mutate the selection provider.
      await tester.ensureVisible(find.text('Chauffage Collective'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Chauffage Collective'));
      await settle(tester);
      expect(container.read(selectedAssociationProvider), hasLength(1));

      // The placeholder poster box is the ImagePickerOnTap child.
      await tester.ensureVisible(find.text('(851/315)'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('(851/315)'));
      await settle(tester, frames: 6);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Fête de fin d’année');
      await tester.enterText(fields.at(1), 'Venez nombreux');
      await scaffold.unfocus(tester);

      await tester.ensureVisible(find.text('Add'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 12);

      verify(
        () => scaffold.repository.advertAdvertsPost(body: any(named: 'body')),
      ).called(1);
      expect(find.text('Advert published'), findsOneWidget);
      await scaffold.drainToast(tester);
      // QR.back() → the admin page beneath the form.
      expect(find.text('Post'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

AdvertComplete posterlessAdvert() => AdvertComplete.empty().copyWith(
  id: '',
  title: 'Whatever',
  content: 'Content',
  advertiserId: 'a1',
);
