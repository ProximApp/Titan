import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/ph/providers/ph_list_provider.dart';
import 'package:titan/ph/providers/ph_pdf_provider.dart';
import 'package:titan/ph/tools/functions.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';
import '../ph_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('fr');
    // Repositories log through a static Logger whose FileLoggerOutput writes
    // to <documents>/myecl.log. Point path_provider at a real temp directory.
    await Directory.systemTemp.createTemp('titan_test_documents').then((dir) {
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            switch (call.method) {
              case 'getApplicationDocumentsDirectory':
              case 'getTemporaryDirectory':
                return dir.path;
            }
            return null;
          });
    });
  });

  late MockOpenapi repository;

  setUp(() {
    repository = MockOpenapi();
    registerFallbackValue(<int>[]);
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [repositoryProvider.overrideWithValue(repository)],
  );

  chopper.Response<List<PaperComplete>> listResponse(
    List<PaperComplete> body,
  ) => chopper.Response<List<PaperComplete>>(http.Response('body', 200), body);

  group('PhListNotifier', () {
    test('loadPhList resolves the journals into data', () async {
      when(() => repository.phGet()).thenAnswer(
        (_) async => listResponse([
          paperFixture('p1', 'Journal 2026', 2026),
          paperFixture('p2', 'Journal 2025', 2025),
        ]),
      );
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(phListProvider.notifier);
      final result = await notifier.loadPhList();

      expect(result.value, hasLength(2));
      expect(container.read(phListProvider).value, hasLength(2));
    });

    test('a failed list response lands in error', () async {
      when(() => repository.phGet()).thenAnswer(
        (_) async => chopper.Response<List<PaperComplete>>(
          http.Response('boom', 500),
          null,
          error: 'server down',
        ),
      );
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(phListProvider.notifier).loadPhList();

      expect(result.hasError, isTrue);
      expect(container.read(phListProvider).hasError, isTrue);
    });

    test('addPh posts the paper and appends it to the list', () async {
      when(
        () => repository.phGet(),
      ).thenAnswer((_) async => listResponse([paperFixture('p1', 'A', 2026)]));
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(phListProvider.notifier);
      await notifier.loadPhList();

      when(() => repository.phPost(body: any(named: 'body'))).thenAnswer(
        (_) async => chopper.Response<PaperComplete>(
          http.Response('body', 200),
          paperFixture('p3', 'New', 2026),
        ),
      );

      final ok = await notifier.addPh(
        PaperBase(name: 'New', releaseDate: DateTime(2026, 4, 1)),
      );

      expect(ok, isTrue);
      expect(
        container.read(phListProvider).value!.map((e) => e.id),
        containsAll(['p1', 'p3']),
      );
    });

    test('addPh refuses to run while the list is still loading', () async {
      // A phGet that never answers keeps the notifier in its build loading
      // state — handleState's loading arm must decline the mutation.
      when(() => repository.phGet()).thenAnswer((_) {
        final completer = Completer<chopper.Response<List<PaperComplete>>>();
        return completer.future;
      });
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(phListProvider.notifier);

      final ok = await notifier.addPh(
        PaperBase(name: 'Nope', releaseDate: DateTime(2026, 4, 1)),
      );

      expect(ok, isFalse);
      expect(container.read(phListProvider).hasError, isTrue);
    });

    test('editPh patches the paper and replaces it in place', () async {
      when(() => repository.phGet()).thenAnswer(
        (_) async => listResponse([
          paperFixture('p1', 'Old name', 2026),
          paperFixture('p2', 'Other', 2025),
        ]),
      );
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(phListProvider.notifier);
      await notifier.loadPhList();

      when(
        () => repository.phPaperIdPatch(
          paperId: any(named: 'paperId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<void>(http.Response('body', 200), null),
      );

      final ok = await notifier.editPh(
        paperFixture(
          'p1',
          'Renamed',
          2026,
        ).copyWith(releaseDate: DateTime(2026, 5, 1)),
      );

      expect(ok, isTrue);
      final list = container.read(phListProvider).value!;
      expect(list.first.name, 'Renamed');
      expect(list.first.releaseDate, DateTime(2026, 5, 1));
      expect(list, hasLength(2));
      verify(
        () => repository.phPaperIdPatch(
          paperId: 'p1',
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('deletePh removes the paper by id', () async {
      when(() => repository.phGet()).thenAnswer(
        (_) async => listResponse([
          paperFixture('p1', 'Gone', 2026),
          paperFixture('p2', 'Kept', 2025),
        ]),
      );
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(phListProvider.notifier);
      await notifier.loadPhList();

      when(() => repository.phPaperIdDelete(paperId: any(named: 'paperId')))
          .thenAnswer(
            (_) async =>
                chopper.Response<void>(http.Response('body', 200), null),
          );

      final ok = await notifier.deletePh(paperFixture('p1', 'Gone', 2026));

      expect(ok, isTrue);
      expect(container.read(phListProvider).value!.map((e) => e.id), ['p2']);
      verify(() => repository.phPaperIdDelete(paperId: 'p1')).called(1);
    });
  });

  group('PhPdf', () {
    test('build returns the pdf bytes', () async {
      when(() => repository.phPaperIdPdfGet(paperId: any(named: 'paperId')))
          .thenAnswer(
            (_) async => chopper.Response<List<int>>(
              http.Response.bytes([1, 2, 3], 200),
              [1, 2, 3],
            ),
          );
      final container = makeContainer();
      addTearDown(container.dispose);

      final bytes = await container.read(phPdfProvider('p1').future);

      expect(bytes, [1, 2, 3]);
    });

    test('updatePhPdf posts the new bytes and echoes them back', () async {
      when(
        () => repository.phPaperIdPdfPost(
          paperId: any(named: 'paperId'),
          pdf: any(named: 'pdf'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<void>(http.Response('body', 200), null),
      );
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(phPdfProvider('p1').notifier);
      final out = await notifier.updatePhPdf(Uint8List.fromList([9, 9, 9]));

      expect(out, [9, 9, 9]);
      verify(() => repository.phPaperIdPdfPost(paperId: 'p1', pdf: [9, 9, 9]))
          .called(1);
    });
  });

  group('phParseDateEntry', () {
    test('accepts both the pretty yMMMd prefill and the yMd picker format', () {
      expect(phParseDateEntry('Jan 1, 2000', 'en'), DateTime(2000, 1, 1));
      expect(phParseDateEntry('1/1/2000', 'en'), DateTime(2000, 1, 1));
      // The fr prefill round-trips through its own formatter.
      final pretty = phFormatDateEntry(DateTime(2000, 1, 1), 'fr');
      expect(phParseDateEntry(pretty, 'fr'), DateTime(2000, 1, 1));
    });

    test('throws on text that is no date at all', () {
      expect(
        () => phParseDateEntry('not a date', 'en'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
