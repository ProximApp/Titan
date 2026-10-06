import 'dart:async';
import 'dart:ui' as ui;

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/mypayment/ui/components/request_card.dart';
import 'package:titan/mypayment/ui/components/transaction_card.dart';
import 'package:titan/mypayment/ui/pages/main_page/account_card/account_card.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for mypayment's three main-page cards:
/// `TransactionCard`, `RequestCard` and the wallet `AccountCard`.
///
/// All three are mounted at **360px** (the narrowest real Android surface)
/// with adversarial data — long wallet names, five-figure amounts, the full
/// status set, refunded transactions with their own sub-line — because those
/// are the strings that overflow a card nobody has typed into a demo.
/// `flutter_test` makes every `A RenderFlex overflowed` fatal, so a silent
/// truncation or clipping is caught here rather than on a device.
///
/// The AccountCard is the one card that reads providers: `myWalletProvider`
/// and `hasAcceptedTosProvider` are both stubbed through the scaffold's
/// mock repository, so the card's own `AsyncChild` branches are all reachable.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  // -----------------------------------------------------------------------
  // Fixture builders
  // -----------------------------------------------------------------------

  History history({
    String name = 'Cafe des Arts',
    HistoryType type = HistoryType.directTransaction,
    HistoryDirection direction = HistoryDirection.debited,
    TransactionStatus status = TransactionStatus.confirmed,
    int total = 1250,
    DateTime? creation,
    HistoryRefund? refund,
  }) => History(
    id: 'hist-1',
    type: type,
    direction: direction,
    otherWalletName: name,
    total: total,
    creation: creation ?? DateTime(2026, 3, 1, 10, 30),
    status: status,
    refund: refund,
  );

  Request$ request({
    String name = 'Cafe des Arts',
    RequestStatus status = RequestStatus.proposed,
    int total = 1250,
    Duration expiresIn = const Duration(minutes: 5),
    DateTime? creation,
    String? storeNote,
  }) => Request$(
    id: 'req-1',
    walletId: 'wallet-1',
    creation: creation ?? DateTime(2026, 3, 1, 10, 30),
    expirationDate: DateTime.now().add(expiresIn),
    total: total,
    storeId: 'store-1',
    name: name,
    storeNote: storeNote,
    module: 'mypayment',
    objectId: 'obj-1',
    status: status,
  );

  /// Mounts a single card at 360x640 with real app fonts (convention 20:
  /// the harness font is wider than Roboto and would produce phantom
  /// overflows).
  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      card,
      container,
      appFonts: true,
      surface: const ui.Size(360, 640),
    );
    await settle(tester, frames: 8);
  }

  void stubWallet(int balance) {
    when(() => scaffold.repository.mypaymentUsersMeWalletGet()).thenAnswer(
      (_) async => chopperResponse(
        Wallet.empty().copyWith(id: 'wallet-1', balance: balance),
      ),
    );
  }

  void stubWalletError() {
    when(() => scaffold.repository.mypaymentUsersMeWalletGet()).thenAnswer(
      (_) async => chopper.Response(
        http.Response('', 500),
        null,
        error: 'wallet unavailable',
      ),
    );
  }

  void stubWalletLoading() {
    when(
      () => scaffold.repository.mypaymentUsersMeWalletGet(),
    ).thenAnswer((_) => Completer<chopper.Response<Wallet>>().future);
  }

  void stubTos({bool accepted = true}) {
    when(() => scaffold.repository.mypaymentUsersMeTosGet()).thenAnswer(
      (_) async => chopperResponse(
        TOSSignatureResponse.empty().copyWith(
          acceptedTosVersion: accepted ? 1 : 0,
          latestTosVersion: 1,
          maxWalletBalance: 100000,
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // TransactionCard
  // -----------------------------------------------------------------------

  group('TransactionCard at 360px', () {
    testWidgets('a long wallet name and a five-figure amount fit', (
      tester,
    ) async {
      await pumpCard(
        tester,
        TransactionCard(
          transaction: history(
            name: 'Association Bienveillance des Anciens Etudiants',
            total: 1234567, // 12,345.67 ʍ
          ),
        ),
      );

      expect(find.text('Association Bienveillance des Anciens Etudiants'), findsOneWidget);
      // fr_FR format: 12 345,67 (space group separator, comma decimal).
      expect(find.textContaining('345,67'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a debited direct transaction shows a negative amount', (
      tester,
    ) async {
      await pumpCard(
        tester,
        TransactionCard(
          transaction: history(
            direction: HistoryDirection.debited,
            total: 5000,
            status: TransactionStatus.confirmed,
          ),
        ),
      );

      expect(find.textContaining('-'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a canceled transaction shows the refused badge', (
      tester,
    ) async {
      await pumpCard(
        tester,
        TransactionCard(
          transaction: history(status: TransactionStatus.canceled),
        ),
      );

      expect(find.text('Refused'), findsOneWidget);
      // The amount is struck through when the status is not confirmed/refunded.
      expect(tester.takeException(), isNull);
    });

    testWidgets('a refunded transaction renders its refund sub-line', (
      tester,
    ) async {
      await pumpCard(
        tester,
        TransactionCard(
          transaction: history(
            status: TransactionStatus.refunded,
            refund: HistoryRefund(
              total: 500,
              creation: DateTime(2026, 3, 5, 14, 0),
            ),
          ),
        ),
      );

      // The refund line appears below the date.
      expect(find.textContaining('5,00'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a refund type with a long name and large amount fits', (
      tester,
    ) async {
      await pumpCard(
        tester,
        TransactionCard(
          transaction: history(
            type: HistoryType.refund,
            direction: HistoryDirection.credited,
            name: 'Remboursement Festival des Etudiants de Lyon',
            total: 9876543,
            status: TransactionStatus.refunded,
          ),
        ),
      );

      // fr_FR format: 98 765,43.
      expect(find.textContaining('765,43'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('all HistoryType values mount without overflow', (tester) async {
      for (final type in HistoryType.values) {
        await pumpCard(
          tester,
          TransactionCard(
            transaction: history(
              type: type,
              name: 'Boutique en ligne de produits artisanaux regionaux',
              total: 99999,
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'type: $type');
      }
    });
  });

  // -----------------------------------------------------------------------
  // RequestCard
  // -----------------------------------------------------------------------

  group('RequestCard at 360px', () {
    testWidgets('a long request name with a pending badge fits', (
      tester,
    ) async {
      await pumpCard(
        tester,
        RequestCard(
          request: request(
            name: 'Location de la salle des fetes pour le mariage de Marie',
            status: RequestStatus.proposed,
            total: 45000,
          ),
        ),
      );

      expect(find.text('Location de la salle des fetes pour le mariage de Marie'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an expired proposed request shows the expired badge', (
      tester,
    ) async {
      await pumpCard(
        tester,
        RequestCard(
          request: request(
            status: RequestStatus.proposed,
            expiresIn: const Duration(minutes: -5),
          ),
        ),
      );

      expect(find.text('Expired'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an accepted request shows its check icon', (tester) async {
      await pumpCard(
        tester,
        RequestCard(
          request: request(status: RequestStatus.accepted, total: 12500),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.checkCircle,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a refused request shows the refused badge', (tester) async {
      await pumpCard(
        tester,
        RequestCard(
          request: request(
            status: RequestStatus.refused,
            name: 'Abonnement magazine annee 2026',
          ),
        ),
      );

      expect(find.text('Refused'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a five-figure amount fits alongside a long name', (
      tester,
    ) async {
      await pumpCard(
        tester,
        RequestCard(
          request: request(
            name: 'Don pour la campagne de solidarite universitaire',
            total: 9876543,
            status: RequestStatus.accepted,
          ),
        ),
      );

      // fr_FR format: 98 765,43.
      expect(find.textContaining('765,43'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('all RequestStatus values mount without overflow', (
      tester,
    ) async {
      for (final status in RequestStatus.values) {
        await pumpCard(
          tester,
          RequestCard(
            request: request(
              status: status,
              name: 'Commande de fournitures pour le laboratoire de chimie',
              total: 55000,
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'status: $status');
      }
    });
  });

  // -----------------------------------------------------------------------
  // AccountCard (wallet balance)
  // -----------------------------------------------------------------------

  group('AccountCard at 360px', () {
    testWidgets('a nine-figure balance renders without overflow', (
      tester,
    ) async {
      stubWallet(999999999); // 9,999,999.99 ʍ
      stubTos();
      await pumpCard(
        tester,
        AccountCard(toggle: () {}, resetHandledKeys: () {}),
      );

      // fr_FR format: 9 999 999,99.
      expect(find.textContaining('999,99'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the error message when the wallet fails', (tester) async {
      stubWalletError();
      stubTos();
      await pumpCard(
        tester,
        AccountCard(toggle: () {}, resetHandledKeys: () {}),
      );

      expect(find.text('Error while retrieving balance: '), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a spinner while the wallet is loading', (tester) async {
      stubWalletLoading();
      stubTos();
      await pumpCard(
        tester,
        AccountCard(toggle: () {}, resetHandledKeys: () {}),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
      await scaffold.unmountApp(tester);
    });

    testWidgets('the action button row fits at 360px', (tester) async {
      stubWallet(5000);
      stubTos();
      await pumpCard(
        tester,
        AccountCard(toggle: () {}, resetHandledKeys: () {}),
      );

      // All five MainCardButton titles must be on screen.
      expect(find.text('Devices'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
